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

-(void) initWithTranscoder: (Transcoder*) transcoder outputType: (OutputType) type
{
    self = [super init];
    if (self) {
        m_transcoder = transcoder;
        m_outputType = type;
        m_task = [[NSTask alloc] init];
        m_messagePipe = [NSPipe pipe];
        
        if (m_outputType == OT_PIPE)
            m_outputPipe = [NSPipe pipe];
    }
}

-(void) runCommand: (NSString*) command
{        
    // build the environment
    NSMutableDictionary* env = [[NSMutableDictionary alloc] init];
    
    // fill in the commands
    NSString* cmdPath = [NSString stringWithString: [[NSBundle mainBundle] resourcePath]];
    NSMutableString* cmd = [NSMutableString stringWithString: cmdPath];
    [cmd appendString:@"/ffmpeg"];
    [env setValue: cmd forKey: @"ffmpeg"];
    
    [cmd setString: cmdPath];
    [cmd appendString:@"/qt_export"];
    [env setValue: cmd forKey: @"qt_export"];

    [cmd setString: cmdPath];
    [cmd appendString:@"/movtoy4m"];
    [env setValue: cmd forKey: @"movtoy4m"];

    [cmd setString: cmdPath];
    [cmd appendString:@"/yuvadjust"];
    [env setValue: cmd forKey: @"yuvadjust"];
    
    // fill in the filenames
    [env setValue: [m_transcoder inputFileName] forKey: @"input_file"];
    [env setValue: [m_transcoder outputFileName] forKey: @"output_file"];
    
    NSString* tmpfile = [NSString stringWithFormat:@"/tmp/%p-tmpaudio.wav", self];
    [[NSFileManager defaultManager] removeFileAtPath:tmpfile handler:nil];
    [env setValue: tmpfile forKey: @"tmp_audio_file"];
    
    // fill in params
    [env setValue: [NSNumber numberWithInt: [m_transcoder inputVideoWidth]] forKey: @"input_file_width"];
    [env setValue: [NSNumber numberWithInt: [m_transcoder inputVideoHeight]] forKey: @"input_file_height"];
    [env setValue: [NSNumber numberWithDouble: [m_transcoder bitrate]] forKey: @"bitrate"];
    [env setValue: [m_transcoder ffmpeg_vcodec] forKey: @"ffmpeg_vcodec"];

    // setup args and command
    NSMutableArray* args = [NSMutableArray arrayWithArray: [command componentsSeparatedByString:@" "]];
    NSString* launchPath = [args objectAtIndex:0];
    if ([launchPath characterAtIndex:0] == '$')
        launchPath = [env valueForKey: [cmd substringFromIndex: 1]];
    
    [args removeObjectAtIndex: 0];
    
    // execute the command
    [m_task setArguments: args];
    [m_task setEnvironment:env];
    [m_task setLaunchPath: launchPath];
    [m_task setStandardError: [m_messagePipe fileHandleForWriting]];
    
    if (m_outputType == OT_PIPE)
        [m_task setStandardOutput: m_outputPipe];
        
    // add notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processFinishEncode:) name:NSTaskDidTerminateNotification object:m_task];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processRead:) name:NSFileHandleReadCompletionNotification object:[m_messagePipe fileHandleForReading]];

    [[m_messagePipe fileHandleForReading] readInBackgroundAndNotify];
    
    [m_task launch];
    if (m_outputType == OT_WAIT)
        [m_task waitUntilExit];
}

-(NSPipe*) outputPipe
{
    return m_outputPipe;
}

-(void) setInputPipe: (NSPipe*) pipe
{
    [m_task setStandardInput: [pipe fileHandleForReading]];
}

-(BOOL) needsToWait
{
    return m_outputType == OT_WAIT;
}

@end
