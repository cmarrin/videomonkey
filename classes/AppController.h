//
//  AppController.h
//  VideoMonkey
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright 2008 Chris Marrin. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ConversionParams;
@class MoviePanelController;
@class Transcoder;

typedef enum { RS_STOPPED, RS_RUNNING, RS_PAUSED } RunStateType;

@interface AppController : NSObject {
@private
    IBOutlet NSTableView* m_fileListView;
    IBOutlet NSProgressIndicator* m_totalProgressBar;
    IBOutlet NSTextField* m_saveToPathTextField;
    IBOutlet NSToolbarItem* m_startEncodeItem;
    IBOutlet NSToolbarItem* m_pauseEncodeItem;
    IBOutlet NSToolbarItem* m_stopEncodeItem;
    IBOutlet ConversionParams* m_conversionParams;
    IBOutlet MoviePanelController* m_moviePanel;
    IBOutlet NSDrawer* m_consoleDrawer;
    IBOutlet NSTextView* m_consoleView;
    
    NSMutableArray* m_files;
    int m_draggedRow;
    NSString* m_savePath;
    int m_currentEncoding;
    RunStateType m_runState;
    BOOL m_isTerminated;
}

-(IBAction)clickFileEnable:(id)sender;
-(IBAction)startEncode:(id)sender;
-(IBAction)pauseEncode:(id)sender;
-(IBAction)stopEncode:(id)sender;
-(IBAction)toggleConsoleDrawer:(id)sender;

-(IBAction)changeSaveToText:(id)sender;
-(IBAction)selectSaveToPath:(id)sender;

-(void) setProgressFor: (Transcoder*) transcoder to: (double) progress;
-(void) encodeFinished: (Transcoder*) transcoder;

-(void) setRunState: (RunStateType) state;

-(ConversionParams*) conversionParams;
-(NSTextView*) consoleView;

@end
