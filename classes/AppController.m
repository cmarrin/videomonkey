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
}

-(Transcoder*) transcoderForFileName:(NSString*) fileName
{
    Transcoder* transcoder = [[Transcoder alloc] initWithController:self];
    [transcoder addInputFile: fileName];
    [transcoder addOutputFile: getOutputFileName(fileName, m_savePath, [m_deviceController fileSuffix])];
    [transcoder setVideoFormat: [m_deviceController videoFormat]];
    [transcoder setBitrate: [m_deviceController bitrate]];
    
    [m_moviePanel setMovie: fileName];
    
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
    if (!m_isTerminated) {
        if (++m_currentEncoding < [m_fileList count]) {
            [[m_fileList objectAtIndex: m_currentEncoding] startEncode];
            return;
        }
    }
    else {
        [m_totalProgressBar setDoubleValue: 0];
        [m_fileListController reloadData];
    }
    
    m_runState =  RS_STOPPED;
}

- (IBAction)startEncode:(id)sender
{
    [m_totalProgressBar setDoubleValue: 0];
    m_isTerminated = NO;
    
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
    [m_fileListController reloadData];
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

-(void) setProgressFor: (Transcoder*) transcoder to: (double) progress
{
    [m_totalProgressBar setDoubleValue: progress];
    [m_fileListController reloadData];
}

-(void) encodeFinished: (Transcoder*) transcoder
{
    [m_totalProgressBar setDoubleValue: m_isTerminated ? 0 : 1];
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

-(void) uiChanged
{
    double bitrate = [m_deviceController bitrate];
    for (Transcoder* transcoder in m_fileList) {
        [transcoder setBitrate: bitrate];
        [transcoder setParams];
    }
    
    [m_fileListController reloadData];
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    [m_fileListController addFile:filename];
    return YES;
}

@end
