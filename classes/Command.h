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
    NSTask* m_task;
    NSPipe* m_messagePipe;
    NSPipe* m_outputPipe;
    Transcoder* m_transcoder;
    NSString* m_command;
    NSString* m_id;
    NSMutableString* m_buffer;
    BOOL m_isPaused;
}

-(Transcoder*) initWithTranscoder: (Transcoder*) transcoder command: (NSString*) command outputType: (CommandOutputType) type identifier: (NSString*) id;
-(void) execute: (Command*) nextCommand;
-(void) setInputPipe: (NSPipe*) pipe;
-(BOOL) needsToWait;
-(void) suspend;
-(void) resume;
-(void) terminate;

-(void) processRead: (NSNotification*) note;
-(void) processFinishEncode: (NSNotification*) note;

@end
