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

@implementation AppController

@synthesize fileList = m_fileList;
@synthesize deviceController = m_deviceController;

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

-(double) currentTime
{
    return (double) [[NSDate date] timeIntervalSince1970];
}

- (id)init
{
    self = [super init];
    m_fileList = [[NSMutableArray alloc] init];
    return self;
}

- (void)dealloc
{
    [m_fileList release];
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
    
    [self setProgressFor:nil to:PROGRESS_NONE];
}

-(Transcoder*) transcoderForFileName:(NSString*) fileName
{
    Transcoder* transcoder = [[Transcoder alloc] initWithController:self];
    [transcoder addInputFile: fileName];
    [transcoder addOutputFile: getOutputFileName(fileName, m_savePath, [m_deviceController fileSuffix])];
    [transcoder setVideoFormat: [m_deviceController videoFormat]];
    return transcoder;
}

-(void) setOutputFileName
{
    NSEnumerator* e = [m_fileList objectEnumerator];
    Transcoder* transcoder;
    NSString* suffix = [m_deviceController fileSuffix];
    NSString* format = [m_deviceController videoFormat];
    
    while ((transcoder = (Transcoder*) [e nextObject])) {
        [transcoder changeOutputFileName: getOutputFileName([transcoder inputFileName], m_savePath, suffix)];
        [transcoder setVideoFormat: format];
    }
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
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

-(void) startNextEncode
{
    m_currentEncodingStartTime = [self currentTime];
    m_numLastProgressTimes = 0;
    for (int i =  0; i < NUM_PROGRESS_TIMES; ++i)
        m_lastProgressTimes[i] = -1;
    
    if (!m_isTerminated) {
        if (++m_currentEncoding < [m_fileList count]) {
            if (![[m_fileList objectAtIndex: m_currentEncoding] startEncode])
                [self startNextEncode];
            else {
                m_fileConvertingIndex++;
                m_finishedEncodedFileSize += m_currentEncodedFileSize;
                m_currentEncodedFileSize = [[m_fileList objectAtIndex: m_currentEncoding] outputFileSize];
                
            }
            return;
        }
    }
    
    m_runState =  RS_STOPPED;
    [self setProgressFor:nil to:0];
}

- (IBAction)startEncode:(id)sender
{
    [self setProgressFor:nil to:0];
    m_isTerminated = NO;
    
    // reset the status for anything we're about to encode
    m_numFilesToConvert = 0;
    m_totalEncodedFileSize = 0;
    m_finishedEncodedFileSize = 0;
    
    for (Transcoder* transcoder in m_fileList) {
        if ([transcoder enabled]) {
            m_numFilesToConvert++;
            m_totalEncodedFileSize += [transcoder outputFileSize];
            [transcoder resetStatus];
        }
    }
    
    if (!m_numFilesToConvert) {
        NSBeginAlertSheet(@"No Files To Encode", nil, nil, nil, [[NSApplication sharedApplication] mainWindow], 
                          nil, nil, nil, nil, 
                          @"None of the files in the list are selected for encoding. Either "
                          "select the check box on some files or drag more files into the list.");
        return;
    }
    
    m_fileConvertingIndex = -1;

    [m_progressText setStringValue:@""];
    [m_fileNumberText setStringValue:@""];

    if (m_runState == RS_PAUSED) {
        [[m_fileList objectAtIndex: m_currentEncoding] resumeEncode];
        m_runState = RS_RUNNING;
    }
    else {
        [self setOutputFileName];
        m_runState = RS_RUNNING;
    
        m_currentEncoding = -1;
        [self startNextEncode];
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

-(IBAction)toggleConsoleDrawer:(id)sender
{
    [m_consoleDrawer toggle:sender];
}

 -(IBAction)changeSaveToText:(id)sender
{
    [m_savePath release];
    m_savePath = [m_saveToPathTextField stringValue];
    [m_savePath retain];
    [m_saveToPathTextField abortEditing];
    [m_saveToPathTextField setStringValue:m_savePath];
    [self setOutputFileName];
}

-(IBAction)selectSaveToPath:(id)sender
{
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:NO];
    [panel setCanChooseDirectories:YES];
    [panel setCanCreateDirectories:YES];
    [panel setTitle:@"Choose a Folder"];
    [panel setPrompt:@"Choose"];
    if ([panel runModalForTypes: nil] == NSOKButton) {
        m_savePath = [[panel filenames] objectAtIndex:0];
        [m_savePath retain];
        [m_saveToPathTextField setStringValue:m_savePath];
        [self setOutputFileName];
    }
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

-(BOOL) addToMediaLibrary
{
    return m_addToMediaLibrary;
}

-(BOOL) deleteFromDestination
{
    return m_deleteFromDestination;
}

-(void) setProgressFor: (Transcoder*) transcoder to: (double) progress
{
    if (!transcoder) {
        [m_totalProgressBar setIndeterminate:NO];
        [m_totalProgressBar setDoubleValue: 0];
        [m_totalProgressBar startAnimation:self];
        [m_progressText setStringValue:@"Press start to encode"];
        [m_fileNumberText setStringValue:@""];
        return;
    }
    
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
    }
    else {
        [m_totalProgressBar stopAnimation:self];
        [m_totalProgressBar setIndeterminate:NO];

        // To determine progress of this file we multiply current progress
        // by what percentage of total file size this file is. Then we add
        // to that the percentage of the file size already completed
        progress *= m_currentEncodedFileSize / m_totalEncodedFileSize;
        progress += m_finishedEncodedFileSize / m_totalEncodedFileSize;
        [m_totalProgressBar setDoubleValue: progress];
        
        if (!timeRemainingString) {
            // compute time remaining
            double estimatedTotalTime = timeSoFar / progress;
            int minutesRemaining = (int) floor((estimatedTotalTime - timeSoFar) / 60 + 0.5);
            
            if (minutesRemaining > 0) {
                if (minutesRemaining == 1)
                    timeRemainingString = @"About a minute remaining for";
                else
                    timeRemainingString = [NSString stringWithFormat:@"About %d minutes remaining for", minutesRemaining];
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

-(void) encodeFinished: (Transcoder*) transcoder
{
    [m_progressText setStringValue:@""];
    [m_fileListController reloadData];
    [self startNextEncode];
}

-(DeviceController*) deviceController
{
    return m_deviceController;
}

-(void) log: (NSString*) format, ...
{
    va_list args;
    va_start(args, format);
    NSString* s = [[NSString alloc] initWithFormat:format arguments: args];
    
    // Output to stderr
    fprintf(stderr, [s UTF8String]);
    
    // Output to log file
    if ([m_fileList count] > m_currentEncoding)
        [(Transcoder*) [m_fileList objectAtIndex: m_currentEncoding] logToFile: s];
        
    // Output to consoleView
    [[[m_consoleView textStorage] mutableString] appendString: s];
    
    // scroll to the end
    NSRange range = NSMakeRange ([[m_consoleView string] length], 0);
    [m_consoleView scrollRangeToVisible: range];    
}

-(void) setSelectedFile: (int) index
{
    [m_moviePanel setMovie: (index < 0) ? nil : [((Transcoder*) [m_fileList objectAtIndex:index]) inputFileName]];
}

-(void) uiChanged
{
    for (Transcoder* transcoder in m_fileList) {
        [transcoder setParams];
    }
    
    [m_fileListController reloadData];
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


@end
