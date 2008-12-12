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
        
    // Do video if it's there
    int offset = 1;
    if ([components count] > offset && [[components objectAtIndex:offset] hasPrefix: @"-Video-"]) {
        NSArray* video = [[components objectAtIndex:offset] componentsSeparatedByString:@","];
        offset = 2;
        
        // -Video-,%StreamKindID%,%ID%,%Language%,%Format%,%Codec_Profile%,%ScanType%,%ScanOrder%,%Width%,%Height%,%PixelAspectRatio%,%DisplayAspectRatio%,%FrameRate%

        if ([video count] != 13)
            return NO;
        info->m_videaStreamKind = [[video objectAtIndex:1] intValue];
        info->m_videoTrack = [[video objectAtIndex:2] intValue];
        info->m_videoLanguage = [[video objectAtIndex:3] retain];
        info->m_videoCodec = [[video objectAtIndex:4] retain];
        info->m_videoProfile = [[video objectAtIndex:5] retain];
        info->m_videoInterlaced = [[video objectAtIndex:6] isEqualToString:@"Interlace"];
        info->m_width = [[video objectAtIndex:8] intValue];
        info->m_height = [[video objectAtIndex:9] intValue];
        info->m_pixelAspectRatio = [[video objectAtIndex:10] doubleValue];
        info->m_displayAspectRatio = [[video objectAtIndex:11] doubleValue];
        info->m_frameRate = [[video objectAtIndex:12] doubleValue];
    }
    
    // Do audio if it's there
    if ([components count] > offset && [[components objectAtIndex:offset] hasPrefix: @"-Audio-"]) {
        NSArray* audio = [[components objectAtIndex:offset] componentsSeparatedByString:@","];

        // -Audio-,%StreamKindID%,%ID%,%Language%,%Format%,%SamplingRate%,%Channels%,%BitRate%
        if ([audio count] != 8)
            return NO;
            
        info->m_audioStreamKind = [[audio objectAtIndex:1] intValue];
        info->m_audioTrack = [[audio objectAtIndex:2] intValue];
        info->m_audioLanguage = [[audio objectAtIndex:3] retain];
        info->m_audioCodec = [[audio objectAtIndex:4] retain];
        info->m_audioSamplingRate = [[audio objectAtIndex:5] doubleValue];
        info->m_channels = [[audio objectAtIndex:6] intValue];
        info->m_audioBitrate = [[audio objectAtIndex:7] doubleValue];
    }

    return YES;
}

static NSImage* getFileStatusImage(FileStatus status)
{
    NSString* name = nil;
    switch(status)
    {
        case FS_INVALID:    name = @"invalid";     break;
        case FS_VALID:      name = @"ready";       break;
        case FS_ENCODING:   name = @"converting";  break;
        case FS_FAILED:     name = @"error";       break;
        case FS_SUCCEEDED:  name = @"ok";          break;
    }
    
    if (!name)
        return nil;
        
    NSString* path = [[NSBundle mainBundle] pathForResource:name ofType:@"png"];
    return [[NSImage alloc] initWithContentsOfFile:path]; 
}

- (Transcoder*) initWithController: (AppController*) controller
{
    self = [super init];
    m_appController = controller;
    m_inputFiles = [[NSMutableArray alloc] init];
    m_outputFiles = [[NSMutableArray alloc] init];
    m_fileStatus = FS_INVALID;
    m_enabled = YES;
    m_tempAudioFileName = [[NSString stringWithFormat:@"/tmp/%p-tmpaudio.wav", self] retain];
    
    // init the progress indicator
    m_progressIndicator = [[NSProgressIndicator alloc] init];
    [m_progressIndicator setMinValue:0];
    [m_progressIndicator setMaxValue:1];
    [m_progressIndicator setIndeterminate: NO];
    [m_progressIndicator setBezeled: NO];
    
    // init the status image view
    m_statusImageView = [[NSImageView alloc] init];
    [m_statusImageView setImage: getFileStatusImage(m_fileStatus)];

    return self;
}
    
- (int) addInputFile: (NSString*) filename
{
    TranscoderFileInfo* file = [[TranscoderFileInfo alloc] init];
    [file setFilename: filename];
    
    if (![self _validateInputFile: file ]) {
        [file release];
        m_fileStatus = FS_INVALID;
        [m_statusImageView setImage: getFileStatusImage(m_fileStatus)];
        return -1;
    }

    [m_inputFiles addObject: file];
    [file release];
    m_fileStatus = FS_VALID;
    [m_statusImageView setImage: getFileStatusImage(m_fileStatus)];
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
        [[m_outputFiles objectAtIndex: 0] setFilename: filename];
}

- (void) setBitrate: (float) rate
{
    m_bitrate = rate;
}

- (double) bitrate;
{
    // TODO: CFM - for now we will just match the input bitrate
    if ([m_inputFiles count] > 0)
        return ((TranscoderFileInfo*) [m_inputFiles objectAtIndex: 0])->m_bitrate;
    return 100000;
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

-(BOOL) isEnabled
{
    return m_enabled;
}

-(NSProgressIndicator*) progressIndicator
{
    return m_progressIndicator;
}

-(NSImageView*) statusImageView
{
    return m_statusImageView;
}

-(FileStatus) inputFileStatus
{
    return m_fileStatus;
}

-(NSString*) inputFileName
{
    return ([m_inputFiles count] > 0) ? ((TranscoderFileInfo*) [m_inputFiles objectAtIndex: 0])->m_filename : nil;
}

-(BOOL) isInputQuicktime
{
    return ([m_inputFiles count] > 0) ? ((TranscoderFileInfo*) [m_inputFiles objectAtIndex: 0])->m_isQuicktime : NO;
}

-(BOOL) hasInputAudio
{
    return ([m_inputFiles count] > 0) ? (((TranscoderFileInfo*) [m_inputFiles objectAtIndex: 0])->m_audioSamplingRate != 0) : NO;
}

-(NSString*) outputFileName
{
    return ([m_outputFiles count] > 0) ? ((TranscoderFileInfo*) [m_outputFiles objectAtIndex: 0])->m_filename : nil;
}

-(int) inputVideoWidth
{
    return ([m_inputFiles count] > 0) ? ((TranscoderFileInfo*) [m_inputFiles objectAtIndex: 0])->m_width : 0;
}

-(int) inputVideoHeight
{
    return ([m_inputFiles count] > 0) ? ((TranscoderFileInfo*) [m_inputFiles objectAtIndex: 0])->m_height : 0;
}

-(int) inputVideoWidthDiv2
{
    if ([m_inputFiles count] == 0)
        return 100;
        
    int w = ((TranscoderFileInfo*) [m_inputFiles objectAtIndex: 0])->m_width;
    return (w & 1) ? w+1 : w;
}

-(int) inputVideoHeightDiv2
{
    if ([m_inputFiles count] == 0)
        return 100;
        
    int h = ((TranscoderFileInfo*) [m_inputFiles objectAtIndex: 0])->m_height;
    return (h & 1) ? h+1 : h;
}

-(int) inputVideoWidthDiv16
{
    if ([m_inputFiles count] == 0)
        return 100;
        
    int w = ((TranscoderFileInfo*) [m_inputFiles objectAtIndex: 0])->m_width;
    return (w+15) & (~(16-1));
}

-(int) inputVideoHeightDiv16
{
    if ([m_inputFiles count] == 0)
        return 100;
        
    int h = ((TranscoderFileInfo*) [m_inputFiles objectAtIndex: 0])->m_height;
    return (h+15) & (~(16-1));
}

-(NSString*) ffmpeg_vcodec
{
    if ([m_outputFiles count] == 0)
        return @"libx264";
    
    // TODO: CFM - we eventually need to return accurate strings here
    NSString* vcodec = ((TranscoderFileInfo*) [m_outputFiles objectAtIndex: 0])->m_videoCodec;
    if ([vcodec isEqualToString:@"h264"])
        return @"libx264";
        
    return @"libx264";
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

-(NSString*) tempAudioFileName
{
    return m_tempAudioFileName;
}

- (BOOL) startEncode
{
    if ([m_outputFiles count] == 0)
        return NO;
        
    // open the log file
    if (logFile) {
        [logFile closeFile];
        [logFile release];
    }
        
    NSString* logFileName = [NSString stringWithFormat:@"~/Library/Application Support/VideoMonkey/Logs/%@-%@.log",
                                [self outputFileName], [[NSDate date] description]];
                                
    logFile = [NSFileHandle fileHandleForWritingAtPath:logFileName];
    
    // make sure the tmp audio file does not exist
    [[NSFileManager defaultManager] removeFileAtPath:m_tempAudioFileName handler:nil];

    // assemble command
    // TODO: always for iphone for now
    NSString* jobType = [NSString stringWithFormat:@"%@-%@", [self isInputQuicktime] ? @"quicktime" : @"normal", [self hasInputAudio] ? @"av" : @"v"];
    NSString* job = [m_appController jobForDevice: @"iphone" type: jobType];
    
    NSArray* elements = [job componentsSeparatedByString:@" "];
    
    NSMutableArray* commands = [[NSMutableArray alloc] init];
    NSEnumerator* enumerator = [elements objectEnumerator];
    NSString* s;
    NSMutableString* commandString = [[NSMutableString alloc] init];
    CommandOutputType type = OT_NONE;
    BOOL isFirst = YES;
    int commandId = 0;
    
    while (s = (NSString*) [enumerator nextObject]) {
        // collect each element up to a ';' (wait) '&' (continue) or '|' (pipe) into a command
        if ([s isEqualToString:@";"])
            type = OT_WAIT;
        else if ([s isEqualToString:@"|"])
            type = OT_PIPE;
        else if ([s isEqualToString:@"&"])
            type = OT_CONTINUE;
    
        if (type == OT_NONE) {
            if (!isFirst)
                [commandString appendString:@" "];
            isFirst = NO;
            [commandString appendString:s];
        }
        else {
            // make a Command object for this command
            [commands addObject:[[Command alloc] initWithTranscoder:self command:[NSString stringWithString: commandString] 
                                outputType:type finishId:[[NSNumber numberWithInt:commandId] stringValue]]];
            type = OT_NONE;
            [commandString setString:@""];
            isFirst = YES;
        }
    }
    
    // add the last command (we know there will be a last command because we know the job can't end in one of the end chars)
    [commands addObject:[[Command alloc] initWithTranscoder:self command:commandString outputType:OT_CONTINUE finishId: @"last"]];

    // execute each command in turn
    enumerator = [commands objectEnumerator];
    Command* command = [enumerator nextObject];
    
    while(command) {
        Command* nextCommand = [enumerator nextObject];
        [command execute: nextCommand];
        command = nextCommand;
    }

    m_fileStatus = FS_ENCODING;
    [m_statusImageView setImage: getFileStatusImage(m_fileStatus)];
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
    if ([(NSString*) [command finishId] isEqualToString:@"last"]) {
        m_fileStatus = FS_SUCCEEDED;
        [m_statusImageView setImage: getFileStatusImage(m_fileStatus)];
        m_progress = 1;
        [m_progressIndicator setDoubleValue: m_progress];
        [m_appController encodeFinished:self];
        [logFile closeFile];
        [logFile release];
        logFile = nil;
    }
}

-(void) log: (NSString*) format, ...
{
    va_list args;
    va_start(args, format);
    NSString* s = [[NSString alloc] initWithFormat:format arguments: args];
    
    // Output to stderr
    fprintf(stderr, [s UTF8String]);
    
    // Output to log file
    if (logFile)
        [logFile writeData:[s dataUsingEncoding:NSUTF8StringEncoding]];
}

@end
