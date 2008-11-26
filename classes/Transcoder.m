//
//  Transcoder.m
//  VideoMonkey
//
//  Created by Chris Marrin on 11/26/08.
//  Copyright 2008 Apple. All rights reserved.
//

#import "Transcoder.h"
#import "AppController.h"

@implementation OutputFile

-(void) setFilename: (NSString*) filename
{
    [filename retain];
    [m_filename release];
    m_filename = filename;
}

-(NSString*) filename
{
    return m_filename;
}

-(void) setBitrate: (float) bitrate
{
    m_bitrate = bitrate;
}

-(float) bitrate: (float) bitrate
{
    return m_bitrate;
}

@end

@implementation Transcoder

- (Transcoder*) initWithController: (AppController*) controller
{
    self = [super init];
    [self setAppController: controller];
    return self;
}
    
-(void) setAppController: (AppController*) appController
{
    m_appController = appController;
}

- (int) addInputFile: (NSString*) filename
{
    [m_inputFiles addObject: filename];
    return [m_inputFiles count] - 1;
}

- (int) addOutputFile: (NSString*) filename
{
    OutputFile* file = [[OutputFile alloc] init];
    [m_outputFiles addObject: file];
    [file setFilename: filename];
    [file setBitrate: m_bitrate];
    return [m_inputFiles count] - 1;    
}

- (void) setBitrate: (float) rate
{
    m_bitrate = rate;
}

- (float) bitrate;
{
    return m_bitrate;
}

- (BOOL) startEncode
{
    NSMutableString* ffmpegPath = [NSMutableString stringWithString: [[NSBundle mainBundle] resourcePath]];
    [ffmpegPath appendString:@"/ffmpeg"];
    
    NSTask* task = [[NSTask alloc] init];
    NSMutableArray* args = [NSMutableArray arrayWithObjects:nil, nil];
    [task setArguments: args];
    [task setLaunchPath: ffmpegPath];
    
    NSPipe* pipe = [NSPipe pipe];
    [task setStandardError: [pipe fileHandleForWriting]];
    
    [task launch];
    
    [task waitUntilExit];
    
    NSData* data = [[pipe fileHandleForReading] availableData];
    char* s = malloc([data length] + 1);
    [data getBytes: s];
    s[[data length]] = '\0';
    printf(s);
    return NO;
}

- (BOOL) pauseEncode
{
    return NO;
}

@end
