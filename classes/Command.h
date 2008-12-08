//
//  Command.h
//  VideoMonkey
//
//  Created by Chris Marrin on 12/7/08.
//  Copyright 2008 Apple. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Transcoder;

@interface Command : NSObject {
@private
    NSMutableArray* m_commands;
    NSTask* m_task;
    NSPipe* m_pipe;
    Transcoder* m_transcoder;
}

-(void) initWithTranscoder: (Transcoder*) transcoder;
-(void) runCommand: (NSString*) command;

@end
