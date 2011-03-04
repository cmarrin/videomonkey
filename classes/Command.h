//
//  Command.h
//  VideoMonkey
//
//  Created by Chris Marrin on 12/7/08.

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
