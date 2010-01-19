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
        m_messagePipe = [[NSPipe pipe] retain];
        
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
    [m_task setStandardOutput: [m_messagePipe fileHandleForWriting]];
    
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
}

-(void) suspend
{
    if (!m_isPaused && [m_task isRunning]) {
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
    if (m_task && [m_task isRunning])
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

-(void) processResponse: (NSString*) response
{
    // FIXME: These should go into some sort of callback functions
    if ([response hasPrefix:@"frame="]) {
        // This looks like a progress line for ffmpeg, process it like that
        // parse out the frame
        NSRange range = [response rangeOfString: @"frame="];
        NSString* s = [response substringFromIndex:(range.location + range.length)];
        double frame = [s doubleValue];
        double totalFrames = m_transcoder.outputFileInfo.duration * m_transcoder.outputFileInfo.videoFrameRate;
        double percentage = frame / totalFrames;
        
        [m_transcoder setProgressForCommand: self to: percentage];
    }
    else if ([response hasPrefix:@" Progress: "]) {
        // This looks like a progress line for AtomicParsley, process it like that
        // parse out the progress
        NSRange range = [response rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]];
        NSString* s = [response substringFromIndex:(range.location)];
        double percentage = [s doubleValue] / 100;
        
        [m_transcoder setProgressForCommand: self to: percentage];
    }
    else if ([response length] > 0)
        [m_transcoder logCommand: m_id withFormat:@"--> %@", response];
    
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
    int status = [m_task terminationStatus];
    
    // notify the Transcoder we're done
    [m_transcoder commandFinished: self status: status];
}

-(void) processRead: (NSNotification*) note
{
    if (![[note name] isEqualToString:NSFileHandleReadCompletionNotification])
        return;

	NSData	*data = [[note userInfo] objectForKey:NSFileHandleNotificationDataItem];
	
    [self processData:data];
	if([data length]) {
        // read another buffer
		[[note object] readInBackgroundAndNotify];
    }
}

@end
