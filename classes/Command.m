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

-(Transcoder*) initWithTranscoder: (Transcoder*) transcoder command: (NSString*) command outputType: (CommandOutputType) type finishId: (id) id
{
    self = [super init];
    if (self) {
        m_transcoder = transcoder;
        m_outputType = type;
        m_command = [command retain];
        m_id = [NSString stringWithString:id];
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
    
    // build the environment
    NSMutableDictionary* env = [[NSMutableDictionary alloc] init];
    
    // fill in the commands
    NSString* cmdPath = [NSString stringWithString: [[NSBundle mainBundle] resourcePath]];
    
    [env setValue: [cmdPath stringByAppendingPathComponent: @"bin/ffmpeg"] forKey: @"ffmpeg"];
    [env setValue: [cmdPath stringByAppendingPathComponent: @"bin/qt_export"] forKey: @"qt_export"];
    [env setValue: [cmdPath stringByAppendingPathComponent: @"bin/movtoy4m"] forKey: @"movtoy4m"];
    [env setValue: [cmdPath stringByAppendingPathComponent: @"bin/yuvadjust"] forKey: @"yuvadjust"];

    // fill in the filenames
    [env setValue: [m_transcoder inputFileName] forKey: @"input_file"];
    [env setValue: [m_transcoder outputFileName] forKey: @"output_file"];
    [env setValue: [m_transcoder tempAudioFileName] forKey: @"tmp_audio_file"];
    
    // fill in params
    [env setValue: [[NSNumber numberWithInt: [m_transcoder inputVideoWidth]] stringValue] forKey: @"input_video_width"];
    [env setValue: [[NSNumber numberWithInt: [m_transcoder inputVideoHeight]] stringValue] forKey: @"input_video_height"];
    [env setValue: [[NSNumber numberWithInt: [m_transcoder inputVideoWidthDiv16]] stringValue] forKey: @"output_video_width"];
    [env setValue: [[NSNumber numberWithInt: [m_transcoder inputVideoHeightDiv16]] stringValue] forKey: @"output_video_height"];
    [env setValue: [[NSNumber numberWithInt: [m_transcoder bitrate]] stringValue] forKey: @"bitrate"];
    [env setValue: [m_transcoder ffmpeg_vcodec] forKey: @"ffmpeg_vcodec"];
    
    NSString* videoSize = [NSString stringWithFormat: @"%dx%d", [m_transcoder inputVideoWidthDiv16], [m_transcoder inputVideoHeightDiv16]];
    [env setValue: videoSize forKey: @"ffmpeg_output_video_size"];

    // setup args and command
    NSMutableArray* args = [NSMutableArray arrayWithArray: [m_command componentsSeparatedByString:@" "]];
    
    // do '$' replacement
    for (int i = 0; i < [args count]; ++i) {
        NSString* s = [args objectAtIndex:i];
        if ([s characterAtIndex:0] == '$') {
            NSString* replacement = [env valueForKey: [s substringFromIndex: 1]];
            if (replacement)
                [args replaceObjectAtIndex:i withObject:replacement];
        }
    }
    
    NSString* launchPath = [args objectAtIndex:0];
    [args removeObjectAtIndex: 0];
    
    // log the command
    [m_transcoder log: @"[Command %@] execute: %@ %@\n", 
                            [m_id isEqualToString:@"last"] ? @"X" : m_id, 
                            [launchPath lastPathComponent], 
                            [args componentsJoinedByString: @" "]];
    
    // execute the command
    [m_task setArguments: args];
    [m_task setEnvironment:env];
    [m_task setLaunchPath: launchPath];
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

-(id) finishId
{
    return m_id;
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

-(void) processResponse_generic: (NSString*) response
{
    [m_transcoder log: @"[Command %@] %@\n", [m_id isEqualToString:@"last"] ? @"X" : m_id, response];
}

-(void) processResponse_ffmpeg: (NSString*) response
{
    // for now we ignore everything but the progress lines, which 
    if (![response hasPrefix:@"frame="]) {
        if ([response length] > 0)
            [m_transcoder log: @"[Command %@] %@\n", [m_id isEqualToString:@"last"] ? @"X" : m_id, response];
        return;
    }
    
    // parse out the time
    NSRange range = [response rangeOfString: @"time="];
    NSString* timeString = [response substringFromIndex:(range.location + range.length)];
    double time = [timeString doubleValue];
    [m_transcoder setProgressForCommand: self to: time / [m_transcoder playTime]];
}

-(void) processResponse: (NSString*) response
{
    if ([m_command hasPrefix:@"$ffmpeg"])
        [self processResponse_ffmpeg: response];
    else
        [self processResponse_generic: response];
}

-(void) processRead: (NSNotification*) note
{
    if (![m_task isRunning])
        return;
        
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
