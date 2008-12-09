//
//  Command.h
//  VideoMonkey
//
//  Created by Chris Marrin on 12/7/08.
//  Copyright 2008 Apple. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Transcoder;

typedef enum { OT_WAIT, OT_CONTINUE, OT_PIPE } OutputType;

@interface Command : NSObject {
@private
    OutputType m_outputType;
    NSTask* m_task;
    NSPipe* m_messagePipe;
    NSPipe* m_outputPipe;
    Transcoder* m_transcoder;
}

-(void) initWithTranscoder: (Transcoder*) transcoder outputType: (OutputType) type;
-(void) runCommand: (NSString*) command;
-(NSPipe*) outputPipe;
-(void) setInputPipe: (NSPipe*) pipe;
-(BOOL) needsToWait;

@end
