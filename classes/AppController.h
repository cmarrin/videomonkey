//
//  AppController.h
//  VideoMonkey
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright 2008 Chris Marrin. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DeviceController;
@class FileInfoPanelController;
@class FileListController;
@class JavaScriptContext;
@class MoviePanelController;
@class Transcoder;

typedef enum { RS_STOPPED, RS_RUNNING, RS_PAUSED } RunStateType;

// Progress Special Values
#define DELAY_FOR_PROGRESS_RESPONSE 5   // in seconds
#define NUM_TOTAL_TIME_ESTIMATES 20

@interface MyDockTileView : NSView {
    float m_progress;
    int m_totalFiles, m_currentFile;
    NSImage* m_icon;
}

@property(assign) float progress;
@property(assign) int totalFiles;
@property(assign) int currentFile;

-(id) initWithIcon:(NSImage*) icon;

@end

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
    IBOutlet FileInfoPanelController* m_fileInfoPanelController;
    IBOutlet MoviePanelController* m_moviePanel;
    IBOutlet NSDrawer* m_consoleDrawer;
    IBOutlet NSTextView* m_consoleView;
    IBOutlet FileListController* m_fileListController;
    IBOutlet NSButton* m_addToMediaLibraryButton;
    IBOutlet NSButton* m_deleteFromDestinationButton;
    IBOutlet NSPathControl* m_savePathControl;
	
	NSImage* m_applicationIcon;
    MyDockTileView* m_dockTileView;
    
    NSString* m_savePath;
    int m_currentEncoding;
    RunStateType m_runState;
    BOOL m_limitParams;
    BOOL m_isTerminated;
    BOOL m_addToMediaLibrary;
    BOOL m_deleteFromDestination;
    
    int m_numFilesToConvert;
    int m_fileConvertingIndex;
    BOOL m_someFilesFailed;
    
    NSArray* m_fileList;

    // encoding progress displays
    BOOL m_firstTimeEstimate;
    double m_currentEncodingStartTime;
    int m_numTotalTimeEstimates;
    double m_totalTimeEstimaes;
    int m_lastMinutesRemaining;
    double m_totalEncodedFileSize;
    double m_currentEncodedFileSize;
    double m_finishedEncodedFileSize;
}

@property (retain) NSArray* fileList;
@property (readonly) DeviceController* deviceController;
@property (readonly) FileInfoPanelController* fileInfoPanelController;
@property (readonly) BOOL limitParams;
@property (readonly) int numCPUs;

+(AppController *) instance;

-(IBAction)startEncode:(id)sender;
-(IBAction)pauseEncode:(id)sender;
-(IBAction)stopEncode:(id)sender;
-(IBAction)toggleConsoleDrawer:(id)sender;

- (BOOL)windowShouldClose:(id)window;

-(IBAction)changeSaveToPath:(id)sender;
-(IBAction)changeAddToMediaLibrary:(id)sender;
-(IBAction)changeDeleteFromDestination:(id)sender;
-(IBAction)limitParams:(id)sender;

-(BOOL) addToMediaLibrary;
-(BOOL) deleteFromDestination;

-(Transcoder*) transcoderForFileName:(NSString*) fileName;

-(void) setProgressFor: (Transcoder*) transcoder to: (double) progress;
-(void) encodeFinished: (Transcoder*) transcoder withStatus:(int) status;

-(void) log: (NSString*) format, ...;

-(void) setSelectedFile: (int) index;

-(void) updateFileInfo;
-(void) updateEncodingInfo;

// delegate method
-(void) uiChanged;

@end
