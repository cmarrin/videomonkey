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

-(void) initWithTranscoder: (Transcoder*) transcoder
{
    self = [super init];
    if (self) {
        self->m_transcoder = transcoder;
        
        m_task = [[NSTask alloc] init];
        m_pipe = [NSPipe pipe];
    }
}

-(void) _runNextCommand
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

    // execute the first command
    NSArray* args = [NSArray arrayWithObjects: @"-c", [m_commands objectAtIndex:0], nil];
    [m_commands removeObjectAtIndex: 0];
    
    [m_task setArguments: args];
    [m_task setEnvironment:env];
    [m_task setLaunchPath: @"/bin/sh"];
    [m_task setStandardError: [m_pipe fileHandleForWriting]];
    
    // add notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processFinishEncode:) name:NSTaskDidTerminateNotification object:m_task];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processRead:) name:NSFileHandleReadCompletionNotification object:[m_pipe fileHandleForReading]];

    [[m_pipe fileHandleForReading] readInBackgroundAndNotify];
    
    [m_task launch];
}

-(void) runCommand: (NSString*) command
{
    // split the command into separate lines
    m_commands = [[NSMutableArray alloc] init];
    [m_commands addObjectsFromArray: [command componentsSeparatedByString:@";"]];
    [self _runNextCommand];
}

@end
