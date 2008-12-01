//
//  AppController.h
//  VideoMonkey
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright 2008 Chris Marrin. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Transcoder;

@interface AppController : NSObject {
@private
    IBOutlet NSTableView* m_fileListView;
    IBOutlet NSProgressIndicator* m_totalProgressBar;
    NSMutableArray* m_files;
    int m_draggedRow;
}

-(IBAction)startConvert:(id)sender;
-(IBAction)pauseConvert:(id)sender;
-(IBAction)stopConvert:(id)sender;

-(void) setProgressFor: (Transcoder*) transcoder to: (double) progress;
-(void) encodeFinished: (Transcoder*) transcoder;

@end
