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
typedef enum { PL_NONE, PL_LIMIT, PL_MATCH } ParamLimitType;

// Progress Special Values
#define DELAY_FOR_PROGRESS_RESPONSE 5   // in seconds
#define NUM_PROGRESS_TIMES 10

// Workaround to get an event when a file is selected from NSPathCell
@interface MyPathCell : NSPathCell { } - (void)setURL:(NSURL *)url; @end

@interface AppController : NSObject {
@private
    IBOutlet NSProgressIndicator* m_totalProgressBar;
    IBOutlet NSTextField* m_progressText;
    IBOutlet NSTextField* m_fileNumberText;
    IBOutlet NSTextField* m_saveToPathTextField;
    IBOutlet NSToolbarItem* m_startEncodeItem;
    IBOutlet NSToolbarItem* m_pauseEncodeItem;
    IBOutlet NSToolbarItem* m_stopEncodeItem;
    IBOutlet DeviceController* m_deviceController;
    IBOutlet MoviePanelController* m_moviePanel;
    IBOutlet NSDrawer* m_consoleDrawer;
    IBOutlet NSTextView* m_consoleView;
    IBOutlet FileListController* m_fileListController;
    IBOutlet NSButton* m_addToMediaLibraryButton;
    IBOutlet NSButton* m_deleteFromDestinationButton;
    IBOutlet NSPathControl* m_savePathControl;
    
    NSString* m_savePath;
    int m_currentEncoding;
    RunStateType m_runState;
    ParamLimitType m_paramLimit;
    BOOL m_isTerminated;
    BOOL m_addToMediaLibrary;
    BOOL m_deleteFromDestination;
    
    int m_numFilesToConvert;
    int m_fileConvertingIndex;
    
    NSArray* m_fileList;

    // encoding progress displays
    double m_currentEncodingStartTime;
    int m_numLastProgressTimes;
    double m_lastProgressTimes[NUM_PROGRESS_TIMES];
    double m_totalEncodedFileSize;
    double m_currentEncodedFileSize;
    double m_finishedEncodedFileSize;
}

@property (retain) NSArray* fileList;
@property (readonly) DeviceController* deviceController;

-(IBAction)startEncode:(id)sender;
-(IBAction)pauseEncode:(id)sender;
-(IBAction)stopEncode:(id)sender;
-(IBAction)toggleConsoleDrawer:(id)sender;

- (BOOL)windowShouldClose:(id)window;

-(IBAction)changeSaveToPath:(id)sender;
-(IBAction)changeAddToMediaLibrary:(id)sender;
-(IBAction)changeDeleteFromDestination:(id)sender;
-(IBAction)paramLimitNone:(id)sender;
-(IBAction)paramLimitLimit:(id)sender;
-(IBAction)paramLimitMatch:(id)sender;

-(BOOL) addToMediaLibrary;
-(BOOL) deleteFromDestination;

-(Transcoder*) transcoderForFileName:(NSString*) fileName;

-(void) setProgressFor: (Transcoder*) transcoder to: (double) progress;
-(void) encodeFinished: (Transcoder*) transcoder;

-(void) log: (NSString*) format, ...;

-(void) setSelectedFile: (int) index;

// delegate method
-(void) uiChanged;

@end
