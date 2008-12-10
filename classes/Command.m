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
        m_command = [NSString stringWithString:command];
        m_id = id;
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
    // build the environment
    NSMutableDictionary* env = [[NSMutableDictionary alloc] init];
    
    // fill in the commands
    NSString* cmdPath = [NSString stringWithString: [[NSBundle mainBundle] resourcePath]];
    NSMutableString* cmd = [NSMutableString stringWithString: cmdPath];
    [cmd appendString:@"/bin/ffmpeg"];
    [env setValue: [NSString stringWithString:cmd] forKey: @"ffmpeg"];
    
    [cmd setString: cmdPath];
    [cmd appendString:@"/bin/qt_export"];
    [env setValue: [NSString stringWithString:cmd] forKey: @"qt_export"];

    [cmd setString: cmdPath];
    [cmd appendString:@"/bin/movtoy4m"];
    [env setValue: [NSString stringWithString:cmd] forKey: @"movtoy4m"];

    [cmd setString: cmdPath];
    [cmd appendString:@"/bin/yuvadjust"];
    [env setValue: [NSString stringWithString:cmd] forKey: @"yuvadjust"];
    
    // fill in the filenames
    [env setValue: [m_transcoder inputFileName] forKey: @"input_file"];
    [env setValue: [m_transcoder outputFileName] forKey: @"output_file"];
    
    NSString* tmpfile = [NSString stringWithFormat:@"/tmp/%p-tmpaudio.wav", self];
    [[NSFileManager defaultManager] removeFileAtPath:tmpfile handler:nil];
    [env setValue: tmpfile forKey: @"tmp_audio_file"];
    
    // fill in params
    [env setValue: [NSString stringWithFormat: @"%d", [m_transcoder inputVideoWidth]] forKey: @"input_video_width"];
    [env setValue: [NSString stringWithFormat: @"%d", [m_transcoder inputVideoHeight]] forKey: @"input_video_width"];
    [env setValue: [NSString stringWithFormat: @"%g", [m_transcoder bitrate]] forKey: @"input_video_width"];
    [env setValue: [m_transcoder ffmpeg_vcodec] forKey: @"ffmpeg_vcodec"];

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
    // TODO: deal with return code
    
    // notify the Transcoder we're done
    [m_transcoder commandFinished: self];
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

-(void) handleResponse: (NSString*) response
{
    if (![response hasPrefix:@"#progress:"])
        return;
        
    NSDictionary* dictionary = makeDictionary(response);
    
    // see if we're done
    if ([[dictionary objectForKey: @"#progress"] isEqualToString:@"done"]) {
        [m_transcoder setProgressForCommand: self to: 1];
    }
    else {
        // parse out the time
        id val = [dictionary objectForKey: @"time"];
        if (val && [val isKindOfClass: [NSString class]]) {
            double time = [val doubleValue];
            [m_transcoder setProgressForCommand: self to: time / [m_transcoder playTime]];
        }
    }
    
    [dictionary release];
}

-(void) processRead: (NSNotification*) note
{
    if (![[note name] isEqualToString:NSFileHandleReadCompletionNotification])
        return;

	NSData	*data = [[note userInfo] objectForKey:NSFileHandleNotificationDataItem];
	
	if([data length]) {
		NSString* string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
        
        NSArray* components = [string componentsSeparatedByString: @"\n"];
        int i;
        assert([components count] > 0);
        for (i = 0; i < [components count]-1; ++i) {
            [m_buffer appendString:[components objectAtIndex:i]];
            
            // process string
            [self handleResponse: m_buffer];
            
            // clear string
            [m_buffer setString: @""];
        }
        
        // if string ends in \n, it is complete, so send it too.
        if ([string hasSuffix:@"\n"]) {
            [m_buffer appendString:[components objectAtIndex:[components count]-1]];
            [self handleResponse: m_buffer];
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

-(void) processResponse_ffmpeg: (NSString*) response
{
    // for now we ignore everything but the progress lines, which 
    if (![response hasPrefix:@"#progress:"])
        return;
        
    NSDictionary* dictionary = makeDictionary(response);
    
    // see if we're done
    if ([[dictionary objectForKey: @"#progress"] isEqualToString:@"done"]) {
        [m_transcoder setProgressForCommand: self to: 1];
    }
    else {
        // parse out the time
        id val = [dictionary objectForKey: @"time"];
        if (val && [val isKindOfClass: [NSString class]]) {
            double time = [val doubleValue];
            [m_transcoder setProgressForCommand: self to: time / [m_transcoder playTime]];
        }
    }
    
    [dictionary release];
}

@end
