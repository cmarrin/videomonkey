//
//  AppController.h
//  VideoMonkey
//
//  Created by Chris Marrin on 11/12/08.

/*
Copyright (c) 2009-2011 Chris Marrin (chris@marrin.com)
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

    - Redistributions of source code must retain the above copyright notice, this 
      list of conditions and the following disclaimer.

    - Redistributions in binary form must reproduce the above copyright notice, 
      this list of conditions and the following disclaimer in the documentation 
      and/or other materials provided with the distribution.

    - Neither the name of Video Monkey nor the names of its contributors may be 
      used to endorse or promote products derived from this software without 
      specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY 
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH 
DAMAGE.
*/

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
    IBOutlet MoviePanelController* m_moviePanelController;
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

@property (readonly) NSString* savePath;
@property (readonly) DeviceController* deviceController;
@property (readonly) FileInfoPanelController* fileInfoPanelController;
@property (readonly) MoviePanelController* moviePanelController;
@property (readonly) FileListController* fileListController;
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

-(void) setProgressFor: (Transcoder*) transcoder to: (double) progress;
-(void) encodeFinished: (Transcoder*) transcoder withStatus:(int) status;

-(void) log: (NSString*) format, ...;

-(void) updateFileInfo;
-(void) updateEncodingInfo;

// delegate method
-(void) uiChanged;

@end
