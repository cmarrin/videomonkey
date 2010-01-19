//
//  AppController.m
//  VideoMonkey
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright 2008 Chris Marrin. All rights reserved.
//

#import "AppController.h"
#import "DeviceController.h"
#import "FileListController.h"
#import "JavaScriptContext.h"
#import "MoviePanelController.h"
#import "Transcoder.h"

#import <sys/types.h>
#import <sys/sysctl.h>

#define MAX_CPUS 8

@implementation MyDockTileView

@synthesize progress = m_progress;
@synthesize currentFile = m_currentFile;
@synthesize totalFiles = m_totalFiles;

-(id) initWithIcon:(NSImage*) icon
{
    m_icon = [icon retain];
    [super init];
    return self;
}

-(void) drawRect:(NSRect)dirtyRect
{
    const NSRect k_progressBarRect = NSMakeRect(0.05, 0.05, 0.9, 0.2);
    const NSRect k_textRect = NSMakeRect(0.2, 0.65, 0.8, 0.3);
    
    
    // Draw the icon
    [m_icon drawAtPoint:NSMakePoint(0.0, 0.0) fromRect: dirtyRect operation: NSCompositeSourceOver fraction: 1.0];
    
    if (m_progress > 0 && m_progress < 1) {
        [[NSGraphicsContext currentContext] saveGraphicsState];
        // Create the rounded rect for the progress bar
        NSRect progressBarRect = NSMakeRect(dirtyRect.size.width * k_progressBarRect.origin.x, 
                                            dirtyRect.size.height * k_progressBarRect.origin.y,
                                            dirtyRect.size.width * k_progressBarRect.size.width, 
                                            dirtyRect.size.height * k_progressBarRect.size.height);
        float radius = progressBarRect.size.height / 2;
                                            
        NSBezierPath* path = [NSBezierPath bezierPathWithRoundedRect:progressBarRect xRadius:radius yRadius:radius];
        [path setClip];
        
        // Draw the progress bar background
        [[NSColor whiteColor] setFill];
        [[NSBezierPath bezierPathWithRect:progressBarRect] fill];
        
        // Fill in the progress
        progressBarRect.size.width *= m_progress;
        [[NSColor colorWithDeviceRed:0.4 green:0.6 blue:0.9 alpha:1] setFill];
        [[NSBezierPath bezierPathWithRect:progressBarRect] fill];
        
        [[NSGraphicsContext currentContext] restoreGraphicsState];
        
        // Outline the progress bar
        [[NSColor blackColor] setStroke];
        [path setLineWidth:2];
        [path stroke];
        
        // Only draw file count if number of files is less than 100. Otherwise
        // it doesn't fit
        if (m_totalFiles < 100) {
        // Draw text background
            NSRect textRect = NSMakeRect(dirtyRect.size.width * k_textRect.origin.x, 
                                                dirtyRect.size.height * k_textRect.origin.y,
                                                dirtyRect.size.width * k_textRect.size.width, 
                                                dirtyRect.size.height * k_textRect.size.height);
            radius = textRect.size.height / 2;
            [[NSColor colorWithDeviceRed:0 green:0.75 blue:0 alpha:1] setFill];
            [[NSColor whiteColor] setStroke];
            path = [NSBezierPath bezierPathWithRoundedRect:textRect xRadius:radius yRadius:radius];
            [path fill];
            
            // Draw the text
            NSString* text = [NSString stringWithFormat:@"%d/%d", m_currentFile + 1, m_totalFiles];
            NSFont* font = [NSFont fontWithName:@"Helvetica" size:textRect.size.height];
            NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys: 
                                            font, NSFontAttributeName,
                                            [NSColor whiteColor], NSForegroundColorAttributeName,
                                            nil];
            
            NSSize size = [text sizeWithAttributes:attributes];
            float offset = (textRect.size.width - size.width) / 2;
            NSPoint textPoint = NSMakePoint(textRect.origin.x + offset, textRect.origin.y * 0.96);
            [text drawAtPoint:textPoint withAttributes:attributes];
            
            [path stroke];
        }
    }
}

@end

@implementation MyPathCell
-(void)setURL:(NSURL *)url
{
    [super setURL:url];

    // Workround for <rdar://5415437> on Mac OS X 10.5.x.
    NSPathControl* pathControl = (NSPathControl*)[self controlView];
    (void)[pathControl sendAction:[self action] to:[self target]];
}
@end

@implementation AppController

@synthesize fileList = m_fileList;
@synthesize deviceController = m_deviceController;
@synthesize fileInfoPanelController = m_fileInfoPanelController;
@synthesize limitParams = m_limitParams;

static AppController *g_appController;

+(AppController *) instance 
{
    assert(g_appController);
    return g_appController;
}

-(NSString*) maxCPU
{
    NSString* s = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"maxCPU"];
    return ([s length] == 0) ? @"Auto" : s;
    
}

-(int) numCPUs
{
    int n = 2;
    
    // get the number of CPUs
    NSString* s = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"maxCPU"];
    if ([s isEqualToString:@"Auto"]) {
        size_t size = sizeof(n);
        if (sysctlbyname("hw.ncpu", &n, &size, NULL, 0))
            n = 2;
    }
    else
        n = [s intValue];
        
    if (n < 1)
        n = 2;
    else if (n > MAX_CPUS)
        n = MAX_CPUS;
        
    return n;
}

-(double) currentTime
{
    return (double) [[NSDate date] timeIntervalSince1970];
}

static NSString* getOutputFileName(NSString* inputFileName, NSString* savePath, NSString* suffix)
{
    // extract filename
    NSString* lastComponent = [inputFileName lastPathComponent];
    NSString* inputPath = [inputFileName stringByDeletingLastPathComponent];
    NSString* baseName = [lastComponent stringByDeletingPathExtension];

    if (!savePath)
        savePath = inputPath;
        
    // now make sure the file doesn't exist
    NSString* filename;
    for (int i = 0; i < 10000; ++i) {
        if (i == 0)
            filename = [[savePath stringByAppendingPathComponent: baseName] stringByAppendingPathExtension: suffix];
        else
            filename = [[savePath stringByAppendingPathComponent: 
                        [NSString stringWithFormat: @"%@_%d", baseName, i]] stringByAppendingPathExtension: suffix];
            
        if (![[NSFileManager defaultManager] fileExistsAtPath: filename])
            break;
    }
    
    return filename;
}

-(void) setOutputFileName
{
    NSEnumerator* e = [m_fileList objectEnumerator];
    Transcoder* transcoder;
    NSString* suffix = [m_deviceController fileSuffix];
    
    while ((transcoder = (Transcoder*) [e nextObject])) {
        [transcoder changeOutputFileName: getOutputFileName(transcoder.inputFileInfo.filename, m_savePath, suffix)];
    }
}

- (void) updateDockIcon
{
    m_dockTileView.progress = 0;
    [[NSApp dockTile] display];
}

- (void) updateDockIcon:(float) progress currentFile:(int) currentFile totalFiles:(int) totalFiles
{
    m_dockTileView.progress = progress;
    m_dockTileView.currentFile = currentFile;
    m_dockTileView.totalFiles = totalFiles;
    [[NSApp dockTile] display];
}

- (id)init
{
    assert(!g_appController);
    
    self = [super init];
    g_appController = self;
    
    m_fileList = [[NSMutableArray alloc] init];
    
    // Save a copy of the app icon
    m_applicationIcon = [[[NSApplication sharedApplication] applicationIconImage] copy];
    
    // Make a view to use to draw the dock tile
    m_dockTileView = [[MyDockTileView alloc] initWithIcon:m_applicationIcon];
    [[NSApp dockTile] setContentView:m_dockTileView];
    [self updateDockIcon];
    
    // Make sure the maxCPU value is rational
    if ([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"maxCPU"] length] == 0)
        [[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:@"Auto" forKey:@"maxCPU"];    

    // Make sure the defaultMetadataSearch value is rational
    if ([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"defaultMetadataSearch"] length] == 0)
        [[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:@"thetvdb.com" forKey:@"defaultMetadataSearch"];

    return self;
}

- (void)dealloc
{
    [m_fileList release];
    [[NSApp dockTile] setContentView:nil];
    [m_dockTileView release];
    [super dealloc];
}

- (void) awakeFromNib
{
    [m_totalProgressBar setUsesThreadedAnimation:YES];

    [m_stopEncodeItem setEnabled: NO];
    [m_pauseEncodeItem setEnabled: NO];
    
    [m_deviceController setDelegate:self];
    
    m_runState = RS_STOPPED;
    
    // init the addToMediaLibrary buttons
    m_addToMediaLibrary = [m_addToMediaLibraryButton state] != 0;
    m_deleteFromDestination = [m_deleteFromDestinationButton state] != 0;
    [m_deleteFromDestinationButton setEnabled:m_addToMediaLibrary];
    
    [self setProgressFor:nil to:0];
    
    m_savePath = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"saveToLocation"];
    [m_savePathControl setURL: [NSURL fileURLWithPath:m_savePath ? m_savePath : @""]];

    m_limitParams = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"limitOutputParams"] boolValue];
}

// This is called to update the info used while encoding is running. It allows
// files to be added or removed from the list while encoding
-(void) updateEncodingInfo
{
    m_numFilesToConvert = 0;
    m_totalEncodedFileSize = 0;
    int numNotYetConverted = 0;

    for (Transcoder* transcoder in m_fileList) {
        FileStatus status = [transcoder fileStatus];
        if ([transcoder enabled] || status == FS_FAILED || status == FS_SUCCEEDED) {
            m_numFilesToConvert++;
            m_totalEncodedFileSize += transcoder.outputFileInfo.fileSize;
            
            BOOL needsConvert = [transcoder enabled] && !(status == FS_ENCODING || status == FS_PAUSED);
            if (needsConvert)
                numNotYetConverted++;
            
            if (m_runState == RS_STOPPED || needsConvert)
                [transcoder resetStatus];
        }
    }

    m_fileConvertingIndex = m_numFilesToConvert - numNotYetConverted - 1;
}

// Main Encoding Functions
-(void) startNextEncode
{
    m_currentEncodingStartTime = [self currentTime];
    m_numTotalTimeEstimates = 0;
    m_totalTimeEstimaes = 0;
    m_lastMinutesRemaining = -1;
    m_firstTimeEstimate = YES;
    
    if (!m_isTerminated) {
        if (++m_currentEncoding < [m_fileList count]) {
            if (![[m_fileList objectAtIndex: m_currentEncoding] startEncode])
                [self startNextEncode];
            else {
                m_fileConvertingIndex++;
                m_finishedEncodedFileSize += m_currentEncodedFileSize;
                m_currentEncodedFileSize = [[m_fileList objectAtIndex: m_currentEncoding] outputFileInfo].fileSize;
                
            }
            return;
        }
        if (!m_someFilesFailed)
            NSBeginAlertSheet(@"Encoding Successful", nil, nil, nil, [[NSApplication sharedApplication] mainWindow], 
                            nil, nil, nil, nil, 
                            @"All files finished encoding without errors");
        else 
            NSBeginAlertSheet(@"Encoding FAILED", nil, nil, nil, [[NSApplication sharedApplication] mainWindow], 
                            nil, nil, nil, nil, 
                            @"Some files had errors during encoding. See Console for details");
        }
    
    m_runState =  RS_STOPPED;
    [self setProgressFor:nil to:0];
}

- (IBAction)startEncode:(id)sender
{
    if (m_runState != RS_PAUSED) {
        [self setProgressFor:nil to:0];
        m_isTerminated = NO;
    
        // reset the status for anything we're about to encode
        m_finishedEncodedFileSize = 0;
        m_currentEncodedFileSize = 0;
    
        for (Transcoder* transcoder in m_fileList) {
            if ([transcoder enabled]) {
                m_numFilesToConvert++;
                m_totalEncodedFileSize += transcoder.outputFileInfo.fileSize;
                [transcoder resetStatus];
            }
        }
        
        [self updateEncodingInfo];
    
        if (!m_numFilesToConvert) {
            NSBeginAlertSheet(@"No Files To Encode", nil, nil, nil, [[NSApplication sharedApplication] mainWindow], 
                            nil, nil, nil, nil, 
                            @"None of the files in the list are selected for encoding. Either "
                            "select the check box on some files or drag more files into the list.");
            return;
        }
    
        m_someFilesFailed = NO;

        [m_progressText setStringValue:@""];
        [m_fileNumberText setStringValue:@""];

        [self setOutputFileName];
        m_runState = RS_RUNNING;
        m_currentEncoding = -1;
        [self startNextEncode];
    }
    else {
        m_runState = RS_RUNNING;
        [[m_fileList objectAtIndex: m_currentEncoding] resumeEncode];
    }
}

- (IBAction)pauseEncode:(id)sender
{
    [[m_fileList objectAtIndex: m_currentEncoding] pauseEncode];
    m_runState = RS_PAUSED;
    [m_fileListController reloadData];
}

- (IBAction)stopEncode:(id)sender
{
    m_isTerminated = YES;
    [[m_fileList objectAtIndex: m_currentEncoding] stopEncode];
    m_runState = RS_STOPPED;
    [self setProgressFor:nil to:0];
}

-(void) setProgressFor: (Transcoder*) transcoder to: (double) progress
{
    if (!transcoder) {
        [m_totalProgressBar setIndeterminate:NO];
        [m_totalProgressBar setDoubleValue: 0];
        [m_totalProgressBar startAnimation:self];
        [m_progressText setStringValue:@"Press start to encode"];
        [m_fileNumberText setStringValue:@""];
		[self updateDockIcon];
        return;
    }
    
    if (m_runState != RS_RUNNING)
        return;
    
    // compute the time remaining for this file
    double timeSoFar = [self currentTime] - m_currentEncodingStartTime;
    
    NSString* timeRemainingString = nil;
    
    // progress of 0 means we're starting and don't know our progress yet
    // progress of 1 means we're just finishing
    if (progress == 0 || timeSoFar < DELAY_FOR_PROGRESS_RESPONSE)
        timeRemainingString = @"Starting";
    else if (progress == 1)
        timeRemainingString = @"Finishing";
        
    if (progress == 0 || progress == 1) {
        [m_totalProgressBar setIndeterminate:YES];
        [m_totalProgressBar startAnimation:self];
		[self updateDockIcon];
    }
    else {
        [m_totalProgressBar stopAnimation:self];
        [m_totalProgressBar setIndeterminate:NO];

        // To determine progress of this file we multiply current progress
        // by what percentage of total file size this file is. Then we add
        // to that the percentage of the file size already completed
        double overallProgress = progress;
        overallProgress *= m_currentEncodedFileSize / m_totalEncodedFileSize;
        overallProgress += m_finishedEncodedFileSize / m_totalEncodedFileSize;
        [m_totalProgressBar setDoubleValue: overallProgress];
		[self updateDockIcon:(float)progress currentFile:m_fileConvertingIndex totalFiles:m_numFilesToConvert];
        
        if (!timeRemainingString) {
            // compute time remaining
            double estimatedTotalTime = timeSoFar / progress;
            m_totalTimeEstimaes += estimatedTotalTime;
            
            if (m_numTotalTimeEstimates++ >= NUM_TOTAL_TIME_ESTIMATES) {
                m_numTotalTimeEstimates = 0;
                estimatedTotalTime = m_totalTimeEstimaes / NUM_TOTAL_TIME_ESTIMATES;
                m_totalTimeEstimaes = 0;
                
                // If this is the first time estimate, ignore it
                if (m_firstTimeEstimate)
                    m_firstTimeEstimate = NO;
                else
                    m_lastMinutesRemaining = (int) floor((estimatedTotalTime - timeSoFar) / 60 + 0.5);
            }
            
            if (m_lastMinutesRemaining < 0)
                timeRemainingString = @"Estimating time remaining for";
            else if (m_lastMinutesRemaining > 0) {
                if (m_lastMinutesRemaining == 1)
                    timeRemainingString = @"About a minute remaining for";
                else
                    timeRemainingString = [NSString stringWithFormat:@"About %d minutes remaining for", m_lastMinutesRemaining];
            }
            else
                timeRemainingString = @"Less than a minute remaining for";
        }
    }
    
    timeRemainingString = [NSString stringWithFormat:@"%@ file %d...", timeRemainingString, m_fileConvertingIndex+1];
    [m_progressText setStringValue:timeRemainingString];
    [m_fileNumberText setStringValue:[NSString stringWithFormat:@"File %d of %d", m_fileConvertingIndex+1, m_numFilesToConvert]];
    [m_fileListController reloadData];
}

-(void) encodeFinished: (Transcoder*) transcoder withStatus:(int) status
{
    if (status != 0 && status != 255)
        m_someFilesFailed = YES;
    [m_progressText setStringValue:@""];
    [m_fileListController reloadData];
    [self startNextEncode];
}

// Toolbar delegate method
- (BOOL) validateToolbarItem:(NSToolbarItem *)theItem
{
    if (theItem == m_startEncodeItem) {
        [m_startEncodeItem setLabel:(m_runState == RS_PAUSED) ? @"Resume" : @"Start"];
        return [m_fileList count] > 0 && m_runState != RS_RUNNING;
    }
        
    if (theItem == m_stopEncodeItem)
        return [m_fileList count] > 0 && m_runState != RS_STOPPED;
        
    if (theItem == m_pauseEncodeItem)
        return [m_fileList count] > 0 && m_runState == RS_RUNNING;
        
    return [theItem isEnabled];
}

-(Transcoder*) transcoderForFileName:(NSString*) fileName
{
    Transcoder* transcoder = [Transcoder transcoder];
    [transcoder addInputFile: fileName];
    [transcoder addOutputFile: getOutputFileName(fileName, m_savePath, [m_deviceController fileSuffix])];
    transcoder.outputFileInfo.duration = transcoder.inputFileInfo.duration;
    return transcoder;
}

-(IBAction)toggleConsoleDrawer:(id)sender
{
    [m_consoleDrawer toggle:sender];
}

-(IBAction)changeSaveToPath:(id)sender
{
    [m_savePath release];
    
    // see if we clicked a cell
    NSPathComponentCell* cell = [sender clickedPathComponentCell];
    NSURL* url = cell ? [cell URL] : [(NSPathControl*) sender URL];
    m_savePath = [[url path] retain];
    if (cell)
        [m_savePathControl setURL: [NSURL fileURLWithPath:m_savePath ? m_savePath : @""]];
    [[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:m_savePath forKey:@"saveToLocation"];
}

-(IBAction) setDefaultSavePath:(id) sender
{
    [m_savePath release];
    m_savePath = nil;
    [m_savePathControl setURL: [NSURL fileURLWithPath:m_savePath ? m_savePath : @""]];
    [[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:m_savePath forKey:@"saveToLocation"];
}

- (void)pathControl:(NSPathControl *)pathControl willDisplayOpenPanel: (NSOpenPanel *)openPanel
{
	[openPanel setCanCreateDirectories:YES];
	[openPanel setCanChooseDirectories:YES];
}

// This is a delegate for NSPathControl to add the 'Same folder as input file' menu item
- (void)pathControl:(NSPathControl *)pathControl willPopUpMenu:(NSMenu *)menu
{
    NSMenuItem* sameFolderItem = [[NSMenuItem alloc] init];
    [sameFolderItem setTitle: @"Same folder as input file"];
    [sameFolderItem setTarget: self];
    [sameFolderItem setAction: @selector(setDefaultSavePath:)];
    [menu insertItem:sameFolderItem atIndex:1];
}

-(IBAction)changeAddToMediaLibrary:(id)sender
{
    m_addToMediaLibrary = [sender state] != 0;
    [m_deleteFromDestinationButton setEnabled:m_addToMediaLibrary];
}

-(IBAction)changeDeleteFromDestination:(id)sender
{
    m_deleteFromDestination = [sender state] != 0;
}

-(IBAction)limitParams:(id)sender
{
    m_limitParams = [sender state];
    [self uiChanged];
}

-(BOOL) addToMediaLibrary
{
    return m_addToMediaLibrary;
}

-(BOOL) deleteFromDestination
{
    return m_deleteFromDestination;
}

-(DeviceController*) deviceController
{
    return m_deviceController;
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    [m_fileListController addFile:filename];
    return YES;
}

-(void) terminateApp:(id) sender
{
    [[NSApplication sharedApplication] terminate:sender];
}

-(void) sheetDidDismiss:(NSWindow *) sheet returnCode:(int) returnCode contextInfo:(void  *) contextInfo
{
    if (returnCode == NSAlertAlternateReturn)
        [self terminateApp:self];
}

- (BOOL)windowShouldClose:(id)window
{
    if (m_runState != RS_STOPPED) {
        NSBeginAlertSheet(@"Are you sure you want to quit?", @"Continue", @"Quit", nil, 
                            [[NSApplication sharedApplication] mainWindow], 
                            self, nil, @selector(sheetDidDismiss:returnCode:contextInfo:), nil, 
                            @"Encoding is in progress. Any unfinished encoding will be cancelled.");
        return NO;
    }
    
    [self terminateApp:self];
    return YES;
}

-(void) log: (NSString*) format, ...
{
    va_list args;
    va_start(args, format);
    NSString* s = [[NSString alloc] initWithFormat:format arguments: args];
    
    // Output to stderr
    fprintf(stderr, "%s", [s UTF8String]);
    
    // Output to log file
    if ([m_fileList count] > m_currentEncoding)
        [(Transcoder*) [m_fileList objectAtIndex: m_currentEncoding] logToFile: s];
        
    // Output to consoleView
    [[[m_consoleView textStorage] mutableString] appendString: s];
    
    // scroll to the end
    NSRange range = NSMakeRange ([[m_consoleView string] length], 0);
    [m_consoleView scrollRangeToVisible: range];    
}

-(void) updateFileInfo
{
    [m_fileListController rearrangeObjects];
}

-(void) setSelectedFile: (int) index
{
    [m_moviePanel setMovie: (index < 0) ? nil : [[m_fileList objectAtIndex:index] inputFileInfo].filename];
}

-(void) uiChanged
{
    for (Transcoder* transcoder in m_fileList) {
        [transcoder setParams];
    }
    
    [m_fileListController reloadData];
}

-(id) metadata
{
    // if we ask for the metadata here, it means we have no selection.
    return nil;
}

-(id) outputFileInfo
{
    // if we ask for outputFileInfo here, it means we have no selection.
    return nil;
}

-(id) inputFileInfo
{
    // if we ask for inputFileInfo here, it means we have no selection.
    return nil;
}

- (id)valueForUndefinedKey:(NSString *)key
{
    NSLog(@"*** AppController::valueForUndefinedKey:%@\n", key);
    return nil;
}

@end
