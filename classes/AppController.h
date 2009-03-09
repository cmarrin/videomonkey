//
//  AppController.h
//  VideoMonkey
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright 2008 Chris Marrin. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DeviceController;
@class FileListController;
@class JavaScriptContext;
@class MoviePanelController;
@class Transcoder;

typedef enum { RS_STOPPED, RS_RUNNING, RS_PAUSED } RunStateType;

@interface AppController : NSObject {
@private
    IBOutlet NSProgressIndicator* m_totalProgressBar;
    IBOutlet NSTextField* m_saveToPathTextField;
    IBOutlet NSToolbarItem* m_startEncodeItem;
    IBOutlet NSToolbarItem* m_pauseEncodeItem;
    IBOutlet NSToolbarItem* m_stopEncodeItem;
    IBOutlet DeviceController* m_deviceController;
    IBOutlet MoviePanelController* m_moviePanel;
    IBOutlet NSDrawer* m_consoleDrawer;
    IBOutlet NSTextView* m_consoleView;
    IBOutlet FileListController* m_fileListController;
    
    NSString* m_savePath;
    int m_currentEncoding;
    RunStateType m_runState;
    BOOL m_isTerminated;
    
    NSArray* m_fileList;
}

@property (retain) NSArray* fileList;
@property (readonly) DeviceController* deviceController;

-(IBAction)startEncode:(id)sender;
-(IBAction)pauseEncode:(id)sender;
-(IBAction)stopEncode:(id)sender;
-(IBAction)toggleConsoleDrawer:(id)sender;

- (BOOL)windowShouldClose:(id)window;

-(IBAction)changeSaveToText:(id)sender;
-(IBAction)selectSaveToPath:(id)sender;

-(Transcoder*) transcoderForFileName:(NSString*) fileName;

-(void) setProgressFor: (Transcoder*) transcoder to: (double) progress;
-(void) encodeFinished: (Transcoder*) transcoder;

-(void) log: (NSString*) format, ...;

-(void) setSelectedFile: (int) index;

// delegate method
-(void) uiChanged;

@end
