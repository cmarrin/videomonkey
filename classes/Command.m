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

@synthesize encodingStartDate;
@synthesize messagePipe;
@synthesize outputPipe;
@synthesize task;

+(Command*) commandWithTranscoder: (Transcoder*) transcoder command: (NSString*) command outputType: (CommandOutputType) type identifier: (NSString*) id
{
    Command* thisCommand = [[[Command alloc] init] autorelease];
    
    if (thisCommand) {
        thisCommand->m_transcoder = transcoder;
        thisCommand->m_outputType = type;
        thisCommand->m_command = [command retain];
        thisCommand->m_id = [id retain];
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
    [m_transcoder logCommand: m_id withFormat:@""];
    [m_transcoder logCommand: m_id withFormat:@"Command to execute:"];
    [m_transcoder logCommand: m_id withFormat:@"    %@ %@", launchPath, [args componentsJoinedByString: @" "]];
    [m_transcoder logCommand: m_id withFormat:@""];
    
    // execute the command
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
    NSTimeInterval totalTime = -[encodingStartDate timeIntervalSinceNow];
    [m_transcoder logCommand: m_id withFormat:@"=============================="];
    int min = (int)((totalTime + 30) / 60);
    int sec = (int)(totalTime - min*60 + 0.5);
    
    if (min == 0)
        [m_transcoder logCommand: m_id withFormat:@"| Command ran in %d seconds", sec];
    else if (min <= 10)
        [m_transcoder logCommand: m_id withFormat:@" | Command ran in %d min %d sec", min, sec];
    else {
        if (sec >= 30)
            min += 1;
        [m_transcoder logCommand: m_id withFormat:@"| Command ran in %d minutes", min];
    }
        
    [m_transcoder logCommand: m_id withFormat:@"=============================="];

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
	if([data length]) {
        // read another buffer
		[[note object] readInBackgroundAndNotify];
    }
}

@end
