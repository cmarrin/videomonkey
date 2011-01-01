//
//  Command.h
//  VideoMonkey
//
//  Created by Chris Marrin on 12/7/08.
//  Copyright 2008 Apple. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Transcoder;

typedef enum { OT_NONE, OT_WAIT, OT_CONTINUE, OT_PIPE } CommandOutputType;

@interface Command : NSObject {
@private
    CommandOutputType m_outputType;
    NSTask* task;
    NSPipe* messagePipe;
    NSPipe* outputPipe;
    int index;
    Transcoder* m_transcoder;
    NSString* m_command;
    NSMutableString* m_buffer;
    BOOL m_isPaused;
    NSDate* encodingStartDate;
}

@property (retain) NSDate* encodingStartDate;
@property (retain) NSPipe* messagePipe;
@property (retain) NSPipe* outputPipe;
@property (retain) NSTask* task;
@property (readonly) int index;

+(Command*) commandWithTranscoder: (Transcoder*) transcoder command: (NSString*) command outputType: (CommandOutputType) type index: (int) index;
-(void) execute: (Command*) nextCommand;
-(void) setInputPipe: (NSPipe*) pipe;
-(BOOL) needsToWait;
-(void) suspend;
-(void) resume;
-(void) terminate;

-(void) processRead: (NSNotification*) note;
-(void) processFinishEncode: (NSNotification*) note;

@end
