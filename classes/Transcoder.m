//
//  Transcoder.m
//  VideoMonkey
//
//  Created by Chris Marrin on 11/26/08.
//  Copyright 2008 Apple. All rights reserved.
//

#import "Transcoder.h"
#import "AppController.h"

@implementation TranscoderFileInfo

-(void) setFormat: (NSString*) format
{
    if ([format isEqualToString: @"MPEG-4"])
        m_format = F_MPEG4;
    else if ([format isEqualToString: @"Windows Media"])
        m_format = F_WM;
    else if ([format isEqualToString: @"Wave"])
        m_format = F_WAV;
    else
        m_format = F_NONE;
}

-(void) setVideoLanguage: (NSString*) lang
{
    [lang retain];
    [m_videoLanguage release];
    m_videoLanguage = lang;
}

-(void) setVideoCodec: (NSString*) codec
{
    if ([codec isEqualToString: @"AVC"])
        m_videoCodec = VC_H264;
    else
        m_videoCodec = VC_NONE;
}

-(void) setVideoProfile: (NSString*) profile
{
    [profile retain];
    [m_videoProfile release];
    m_videoProfile = profile;
}

-(void) setAudioLanguage: (NSString*) lang
{
    [lang retain];
    [m_audioLanguage release];
    m_audioLanguage = lang;
}

-(void) setAudioCodec: (NSString*) codec
{
    if ([codec isEqualToString: @"PCM"])
        m_audioCodec = AC_PCM;
    else
        m_audioCodec = AC_NONE;
}

-(void) setFilename: (NSString*) filename
{
    [filename retain];
    [m_filename release];
    m_filename = filename;
}

@end

@implementation Transcoder

-(BOOL) _validateInputFile: (TranscoderFileInfo*) info
{
    NSMutableString* mediainfoPath = [NSMutableString stringWithString: [[NSBundle mainBundle] resourcePath]];
    [mediainfoPath appendString:@"/mediainfo"];
    
    NSMutableString* mediainfoInformPath = [NSMutableString stringWithString: @"--Inform=file://"];
    [mediainfoInformPath appendString: [[NSBundle mainBundle] resourcePath]];
    [mediainfoInformPath appendString:@"/mediainfo-inform.csv"];
    
    NSTask* task = [[NSTask alloc] init];
    NSMutableArray* args = [NSMutableArray arrayWithObjects: mediainfoInformPath, info->m_filename, nil];
    [task setArguments: args];
    [task setLaunchPath: mediainfoPath];
    
    NSPipe* pipe = [NSPipe pipe];
    [task setStandardOutput:[pipe fileHandleForWriting]];
    
    [task launch];
    
    [task waitUntilExit];
    
    NSString* data = [[NSString alloc] initWithData: [[pipe fileHandleForReading] availableData] encoding: NSASCIIStringEncoding];
    
    // The first line must start with "-General-" or the file is not valid
    if (![data hasPrefix: @"-General-"])
        return NO;
    
    NSArray* components = [data componentsSeparatedByString:@"\r\n"];
    
    // We always have a General line.
    NSArray* general = [[components objectAtIndex:0] componentsSeparatedByString:@","];
    if ([general count] != 4)
        return NO;
        
    [info setFormat: [general objectAtIndex:1]];
    info->m_playTime = [[general objectAtIndex:2] doubleValue] / 1000;
    info->m_bitrate = [[general objectAtIndex:3] doubleValue];
    
    if (info->m_format == F_NONE)
        return NO;
        
    // TODO: CFM - do video and audio
    
    return YES;
}

- (Transcoder*) initWithController: (AppController*) controller
{
    self = [super init];
    [self setAppController: controller];
    m_inputFiles = [[NSMutableArray alloc] init];
    m_outputFiles = [[NSMutableArray alloc] init];
    return self;
}
    
-(void) setAppController: (AppController*) appController
{
    m_appController = appController;
}

- (int) addInputFile: (NSString*) filename
{
    TranscoderFileInfo* file = [[TranscoderFileInfo alloc] init];
    [file setFilename: filename];
    
    if (![self _validateInputFile: file ]) {
        [file release];
        return -1;
    }

    [m_inputFiles addObject: file];
    [file release];
    return [m_inputFiles count] - 1;    
}

- (int) addOutputFile: (NSString*) filename
{
    TranscoderFileInfo* file = [[TranscoderFileInfo alloc] init];
    [m_outputFiles addObject: file];
    [file release];
    [file setFilename: filename];
    return [m_outputFiles count] - 1;    
}

- (void) setBitrate: (float) rate
{
    m_bitrate = rate;
}

- (double) bitrate;
{
    return m_bitrate;
}

-(double) playTime
{
    if ([m_inputFiles count] > 0)
        return ((TranscoderFileInfo*) [m_inputFiles objectAtIndex: 0])->m_playTime;
    return -1;
}

-(NSString*) inputFilename
{
    if ([m_inputFiles count] > 0)
        return ((TranscoderFileInfo*) [m_inputFiles objectAtIndex: 0])->m_filename;
    return nil;
}

-(int) outputFileSize
{
    // The m_bitrate property holds the desired bitrate. If it is 0, the user wants the
    // output bitrate to match the input bitrate.
    double playTime = [self playTime];
    double bitrate = 0;
    
    if (m_bitrate > 0)
        bitrate = m_bitrate;
    else if ([m_inputFiles count] > 0)
        bitrate = ((TranscoderFileInfo*) [m_inputFiles objectAtIndex: 0])->m_bitrate;
        
    return (int) (playTime * bitrate / 8);
}

- (BOOL) startEncode
{
    NSMutableString* ffmpegPath = [NSMutableString stringWithString: [[NSBundle mainBundle] resourcePath]];
    [ffmpegPath appendString:@"/ffmpeg"];
    
    NSTask* task = [[NSTask alloc] init];
    NSString* inputFilename = ((TranscoderFileInfo*) [m_inputFiles objectAtIndex:0])->m_filename;
    NSMutableArray* args = [NSMutableArray arrayWithObjects: @"-y", @"-i", inputFilename, @"-sameq", @"/tmp/foo.mov", nil];
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
