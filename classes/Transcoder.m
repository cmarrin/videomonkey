//
//  Transcoder.m
//  VideoMonkey
//
//  Created by Chris Marrin on 11/26/08.
//  Copyright 2008 Apple. All rights reserved.
//

#import "Transcoder.h"
#import "AppController.h"
#import "Command.h"

@implementation TranscoderFileInfo

-(void) setFormat: (NSString*) format
{
    [format retain];
    [m_format release];
    m_format = format;
}

-(void) setVideoLanguage: (NSString*) lang
{
    [lang retain];
    [m_videoLanguage release];
    m_videoLanguage = lang;
}

-(void) setVideoCodec: (NSString*) codec
{
    [codec retain];
    [m_videoCodec release];
    m_videoCodec = codec;
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
    [codec retain];
    [m_audioCodec release];
    m_audioCodec = codec;
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
    if ([general count] != 5)
        return NO;
        
    [info setFormat: [general objectAtIndex:1]];
    info->m_isQuicktime = [[general objectAtIndex:2] isEqualToString:@"QuickTime"];
    info->m_playTime = [[general objectAtIndex:3] doubleValue] / 1000;
    info->m_bitrate = [[general objectAtIndex:4] doubleValue];
    
    
    if ([info->m_format length] == 0)
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
    m_fileStatus = FS_INVALID;
    
    // init the progress indicator
    m_progressIndicator = [[NSProgressIndicator alloc] init];
    [m_progressIndicator setMinValue:0];
    [m_progressIndicator setMaxValue:1];
    [m_progressIndicator setIndeterminate: NO];
    [m_progressIndicator setBezeled: NO];

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
        m_fileStatus = FS_INVALID;
        return -1;
    }

    [m_inputFiles addObject: file];
    [file release];
    m_fileStatus = FS_VALID;
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

-(void) changeOutputFileName: (NSString*) filename
{
    if ([m_outputFiles count] > 0)
        ((TranscoderFileInfo*) [m_outputFiles objectAtIndex: 0])->m_filename = filename;
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

-(double) progress
{
    return m_progress;
}

-(NSProgressIndicator*) progressIndicator
{
    return m_progressIndicator;
}

-(FileStatus) inputFileStatus
{
    return m_fileStatus;
}

-(NSString*) inputFileName
{
    if ([m_inputFiles count] > 0)
        return ((TranscoderFileInfo*) [m_inputFiles objectAtIndex: 0])->m_filename;
    return nil;
}

-(NSString*) outputFileName
{
    if ([m_outputFiles count] > 0)
        return ((TranscoderFileInfo*) [m_outputFiles objectAtIndex: 0])->m_filename;
    return nil;
}

-(int) inputVideoWidth
{
    return ([m_inputFiles count] > 0) ? ((TranscoderFileInfo*) [m_inputFiles objectAtIndex: 0])->m_width : 0;
}

-(int) inputVideoHeight
{
    return ([m_inputFiles count] > 0) ? ((TranscoderFileInfo*) [m_inputFiles objectAtIndex: 0])->m_height : 0;
}

-(NSString*) ffmpeg_vcodec
{
    if ([m_inputFiles count] == 0)
        return nil;
    
    NSString* vcodec = ((TranscoderFileInfo*) [m_inputFiles objectAtIndex: 0])->m_videoCodec;
    if ([vcodec isEqualToString:@"h264"])
        return @"libx264";
        
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
    // assemble command
    // TODO: for now just do a stock encode
    NSString* job = [m_appController jobForDevice: @"iphone" type: @"quicktime"];
    
    NSArray* elements = [job componentsSeparatedByString:@" "];
    
    NSMutableArray* commands = [[NSMutableArray alloc] init];
    NSEnumerator* enumerator = [elements objectEnumerator];
    NSString* s;
    NSMutableString* commandString = [[NSMutableString alloc] init];
    CommandOutputType type = OT_NONE;
    
    while (s = (NSString*) [enumerator nextObject]) {
        // collect each element up to a ';' (wait) '&' (continue) or '|' (pipe) into a command
        if ([s isEqualToString:@";"])
            type = OT_WAIT;
        else if ([s isEqualToString:@"|"])
            type = OT_PIPE;
        else if ([s isEqualToString:@"&"])
            type = OT_CONTINUE;
    
        if (type == OT_NONE) {
            [commandString appendString:s];
            [commandString appendString:@" "];
        }
        else {
            // make a Command object for this command
            [commands addObject:[[Command alloc] initWithTranscoder:self command:commandString outputType:type finishId: @""]];
            type = OT_NONE;
            [commandString setString:@""];
        }
    }
    
    // add the last command (we know there will be a last command because we know the job can't end in one of the end chars)
    [commands addObject:[[Command alloc] initWithTranscoder:self command:commandString outputType:OT_CONTINUE finishId: @""]];

    // execute each command in turn
    enumerator = [commands objectEnumerator];
    Command* command;
    
    while(command = (Command*) [enumerator nextObject])
        [command execute];

    m_fileStatus = FS_ENCODING;
    return YES;
}

- (BOOL) pauseEncode
{
    return NO;
}

-(void) setProgressForCommand: (Command*) command to: (double) value
{
    // TODO: need to give each command a percentage of the progress
    m_progress = value;
    [m_progressIndicator setDoubleValue: m_progress];
    [m_appController setProgressFor: self to: m_progress];
}

-(void) commandFinished: (Command*) command
{
    if ([(NSString*) [command finishId] isEqualToString:@"done"])
        [m_appController encodeFinished:self];
}

@end
