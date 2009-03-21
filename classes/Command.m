//
//  Command.m
//  VideoMonkey
//
//  Created by Chris Marrin on 12/7/08.
//  Copyright 2008 Apple. All rights reserved.
//

#import "Command.h"
#import "Transcoder.h"

@implementation Command

-(Transcoder*) initWithTranscoder: (Transcoder*) transcoder command: (NSString*) command outputType: (CommandOutputType) type identifier: (NSString*) id
{
    self = [super init];
    if (self) {
        m_transcoder = transcoder;
        m_outputType = type;
        m_command = [command retain];
        m_id = [id retain];
        m_buffer = [[NSMutableString alloc] init];
        
        m_task = [[NSTask alloc] init];
        m_messagePipe = [NSPipe pipe];
        
        if (m_outputType == OT_PIPE)
            m_outputPipe = [NSPipe pipe];
    }
    return (Transcoder*) self;
}

-(void) execute: (Command*) nextCommand
{
    m_isPaused = NO;
    
    // setup args and command
    NSMutableArray* args = [NSMutableArray arrayWithArray: [m_command componentsSeparatedByString:@" "]];
    
    NSString* launchPath = [args objectAtIndex:0];
    [args removeObjectAtIndex: 0];
    
    // log the command
    [m_transcoder logCommand: m_id withFormat:@""];
    [m_transcoder logCommand: m_id withFormat:@"Command to execute:"];
    [m_transcoder logCommand: m_id withFormat:@"    %@ %@", [launchPath lastPathComponent], [args componentsJoinedByString: @" "]];
    [m_transcoder logCommand: m_id withFormat:@""];
    
    // execute the command
    [m_task setArguments: [NSArray arrayWithObjects: @"-c", m_command, nil]];
    [m_task setLaunchPath: @"/bin/sh"];
    [m_task setStandardError: [m_messagePipe fileHandleForWriting]];
    
    if (m_outputType == OT_PIPE) {
        [m_task setStandardOutput: m_outputPipe];
        assert(nextCommand);
        if (nextCommand)
            [nextCommand setInputPipe: m_outputPipe];
    }
        
    // add notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processFinishEncode:) name:NSTaskDidTerminateNotification object:m_task];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processRead:) name:NSFileHandleReadCompletionNotification object:[m_messagePipe fileHandleForReading]];

    [[m_messagePipe fileHandleForReading] readInBackgroundAndNotify];
    
    [m_task launch];
    if (m_outputType == OT_WAIT)
        [m_task waitUntilExit];
}

-(void) suspend
{
    if (!m_isPaused) {
        [m_task suspend];
        m_isPaused = YES;
    }
}

-(void) resume
{
    if (m_isPaused) {
        [m_task resume];
        m_isPaused = NO;
    }
}

-(void) terminate
{
    [m_task terminate];
}

-(void) setInputPipe: (NSPipe*) pipe
{
    [m_task setStandardInput: [pipe fileHandleForReading]];
}

-(BOOL) needsToWait
{
    return m_outputType == OT_WAIT;
}

-(void) processFinishEncode: (NSNotification*) note
{
    int status = [m_task terminationStatus];
    
    // notify the Transcoder we're done
    [m_transcoder commandFinished: self status: status];
}

static NSDictionary* makeDictionary(NSString* s)
{
    NSMutableDictionary* dictionary = [[NSMutableDictionary alloc] init];
    NSArray* elements = [s componentsSeparatedByString:@";"];
    for (int i = 0; i < [elements count]; ++i) {
        NSArray* values = [[elements objectAtIndex:i] componentsSeparatedByString:@":"];
        if ([values count] != 2)
            continue;
        [dictionary setValue: [values objectAtIndex:1] forKey: [values objectAtIndex:0]];
    }
    
    return dictionary;
}

-(void) processResponse: (NSString*) response
{
    // If this looks like a progress line for ffmpeg, process it like that
    if (![response hasPrefix:@"frame="]) {
        if ([response length] > 0)
            [m_transcoder logCommand: m_id withFormat:@"--> %@", response];
        return;
    }
    
    // parse out the time
    NSRange range = [response rangeOfString: @"time="];
    NSString* timeString = [response substringFromIndex:(range.location + range.length)];
    double time = [timeString doubleValue];
    [m_transcoder setProgressForCommand: self to: time / [m_transcoder duration]];
}

-(void) processRead: (NSNotification*) note
{
    if (![[note name] isEqualToString:NSFileHandleReadCompletionNotification])
        return;

	NSData	*data = [[note userInfo] objectForKey:NSFileHandleNotificationDataItem];
	
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
        
        // read another buffer
		[[note object] readInBackgroundAndNotify];
    }
}

@end
