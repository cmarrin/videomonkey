//
//  Command.m
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

#import "Command.h"

#import "AppController.h"
#import "DeviceController.h"
#import "Transcoder.h"

@implementation Command

@synthesize encodingStartDate;
@synthesize messagePipe;
@synthesize outputPipe;
@synthesize task;
@synthesize index;

+(Command*) commandWithTranscoder: (Transcoder*) transcoder command: (NSString*) command outputType: (CommandOutputType) type index: (int) index
{
    Command* thisCommand = [[[Command alloc] init] autorelease];
    
    if (thisCommand) {
        thisCommand->m_transcoder = transcoder;
        thisCommand->m_outputType = type;
        thisCommand->m_command = [command retain];
        thisCommand->index = index;
        thisCommand->m_buffer = [[NSMutableString alloc] init];
        
        thisCommand.task = [[NSTask alloc] init];
        thisCommand.messagePipe = [[NSPipe pipe] retain];
        
        if (thisCommand->m_outputType == OT_PIPE)
            thisCommand.outputPipe = [NSPipe pipe];
    }
    return thisCommand;
}

-(void) execute: (Command*) nextCommand
{
    m_isPaused = NO;
    
    // setup args and command
    NSMutableArray* args = [NSMutableArray arrayWithArray: [m_command componentsSeparatedByString:@" "]];
    
    NSString* launchPath = [args objectAtIndex:0];
    [args removeObjectAtIndex: 0];
    
    // log the command
    [m_transcoder logCommand: index withFormat:@""];
    [m_transcoder logCommand: index withFormat:@"Command to execute:"];
    [m_transcoder logCommand: index withFormat:@"    %@ %@", launchPath, [args componentsJoinedByString: @" "]];
    [m_transcoder logCommand: index withFormat:@""];
    
    // execute the command
    [self.task setCurrentDirectoryPath:[m_transcoder.outputFileInfo.filename stringByDeletingLastPathComponent]];
    [self.task setArguments: [NSArray arrayWithObjects: @"-c", m_command, nil]];
    [self.task setEnvironment:[NSDictionary dictionaryWithObjectsAndKeys:[[NSBundle mainBundle] resourcePath], @"FFMPEG_DATADIR", nil]];
    [self.task setLaunchPath: @"/bin/sh"];
    [self.task setStandardError: [self.messagePipe fileHandleForWriting]];
    [self.task setStandardOutput: [self.messagePipe fileHandleForWriting]];
    
    if (m_outputType == OT_PIPE) {
        [self.task setStandardOutput: self.outputPipe];
        assert(nextCommand);
        if (nextCommand)
            [nextCommand setInputPipe: self.outputPipe];
    }
        
    // add notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processFinishEncode:) name:NSTaskDidTerminateNotification object:self.task];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processRead:) name:NSFileHandleReadCompletionNotification object:[self.messagePipe fileHandleForReading]];

    [[self.messagePipe fileHandleForReading] readInBackgroundAndNotify];
    
    self.encodingStartDate = [NSDate date];
    [self.task launch];
}

-(void) suspend
{
    if (!m_isPaused && [self.task isRunning]) {
        [self.task suspend];
        m_isPaused = YES;
    }
}

-(void) resume
{
    if (m_isPaused) {
        [self.task resume];
        m_isPaused = NO;
    }
}

-(void) terminate
{
    if (self.task && [self.task isRunning])
        [self.task terminate];
}

-(void) setInputPipe: (NSPipe*) pipe
{
    [self.task setStandardInput: [pipe fileHandleForReading]];
}

-(BOOL) needsToWait
{
    return m_outputType == OT_WAIT;
}

-(void) processResponse: (NSString*) response
{
    NSArray* array = [m_command componentsSeparatedByString:@"\""];
    NSString* command = [[array objectAtIndex:1] lastPathComponent];
    [[[AppController instance] deviceController] processResponse:response forCommand:command];

    double progress = [[[[AppController instance] deviceController] paramForKey:@"processResponseProgress"] doubleValue];
    NSString* messageString = [[[AppController instance] deviceController] paramForKey:@"processResponseMessage"];
    if (progress >= 0)
        [m_transcoder setProgressForCommand: self to: progress];
    if ([messageString length] > 0)
        [m_transcoder logCommand: index withFormat:@"--> %@", messageString];
}

-(void) processData:(NSData*) data
{
	if([data length]) {
		NSString* string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
        
        NSArray* components = [string componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\r\n"]];
        int i;
        assert([components count] > 0);
        for (i = 0; i < [components count]-1; ++i) {
            [m_buffer appendString:[components objectAtIndex:i]];
            
            // process string
            [self processResponse: m_buffer];
            
            // clear string
            [m_buffer setString: @""];
        }
        
        // if string ends in \n, it is complete, so send it too.
        if ([string hasSuffix:@"\n"] || [string hasSuffix:@"\r"]) {
            [m_buffer appendString:[components objectAtIndex:[components count]-1]];
            [self processResponse: m_buffer];
            [m_buffer setString: @""];
        }
        else {
            // put remaining component in m_buffer for next time
            [m_buffer setString: [components objectAtIndex:[components count]-1]];
        }
    }
}

-(void) processFinishEncode: (NSNotification*) note
{
    NSTimeInterval totalTime = -[encodingStartDate timeIntervalSinceNow];
    [m_transcoder logCommand: index withFormat:@"=============================="];
    int min = (int)((totalTime + 30) / 60);
    int sec = (int)(totalTime - min*60 + 0.5);
    
    if (min == 0)
        [m_transcoder logCommand: index withFormat:@"| Command ran in %d seconds", sec];
    else if (min <= 10)
        [m_transcoder logCommand: index withFormat:@" | Command ran in %d min %d sec", min, sec];
    else {
        if (sec >= 30)
            min += 1;
        [m_transcoder logCommand: index withFormat:@"| Command ran in %d minutes", min];
    }
        
    [m_transcoder logCommand: index withFormat:@"=============================="];

    int status = [self.task terminationStatus];
    
    // notify the Transcoder we're done
    [m_transcoder commandFinished: self status: status];
}

-(void) processRead: (NSNotification*) note
{
    if (![[note name] isEqualToString:NSFileHandleReadCompletionNotification])
        return;

	NSData* data = [[note userInfo] objectForKey:NSFileHandleNotificationDataItem];
	
    [self processData:data];
	if ([data length]) {
        // read another buffer
		[[note object] readInBackgroundAndNotify];
    }
}

@end
