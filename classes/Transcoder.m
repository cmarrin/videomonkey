//
//  Transcoder.m
//  VideoMonkey
//
//  Created by Chris Marrin on 11/26/08.
//  Copyright 2008 Apple. All rights reserved.
//

#import <ScriptingBridge/ScriptingBridge.h>
#import "iTunes.h"

#import "Transcoder.h"
#import "AppController.h"
#import "Command.h"
#import "DeviceController.h"
#import "FileInfoPanelController.h"
#import "Metadata.h"

FrameSize makeFrameSize(int width, int height) { return ((uint32_t) width << 16) | ((uint32_t) height & 0xffff); }
int widthFromFrameSize(FrameSize f) { return f >> 16; }
int heightFromFrameSize(FrameSize f) { return f & 0xffff; }

@implementation TranscoderFileInfo

// General
@synthesize filename;
@synthesize format;
@synthesize duration;
@synthesize bitrate;
@synthesize isQuicktime;
@synthesize fileSize;

// Video
@synthesize videaStreamKind;
@synthesize videoTrack;
@synthesize videoLanguage;
@synthesize videoCodec;
@synthesize videoProfile;
@synthesize videoInterlaced;
@synthesize videoFrameSize;
@synthesize videoAspectRatio;
@synthesize videoFrameRate;
@synthesize videoBitrate;

// Audio
@synthesize audioStreamKind;
@synthesize audioTrack;
@synthesize audioLanguage;
@synthesize audioCodec;
@synthesize audioSampleRate;
@synthesize audioChannels;
@synthesize audioBitrate;

@end


@implementation Transcoder

+(TranscoderFileInfo*) dummyFileInfo
{
    static TranscoderFileInfo* dummy;
    if (!dummy)
        dummy = [[TranscoderFileInfo alloc] init];
    return dummy;
}

-(TranscoderFileInfo*) inputFileInfo
{
    return ([m_inputFiles count] > 0) ? ((TranscoderFileInfo*) [m_inputFiles objectAtIndex: 0]) : [Transcoder dummyFileInfo];
}

-(TranscoderFileInfo*) outputFileInfo
{
    return ([m_outputFiles count] > 0) ? ((TranscoderFileInfo*) [m_outputFiles objectAtIndex: 0]) : [Transcoder dummyFileInfo];
}

// Properties
@synthesize progress = m_progress;
@synthesize enabled = m_enabled;
@synthesize metadata = m_metadata;
@synthesize fileStatus = m_fileStatus;

-(BOOL) enabled
{
    return m_enabled;    
}

-(void) setEnabled:(BOOL) enabled
{
    if (m_fileStatus == FS_ENCODING || m_fileStatus == FS_PAUSED) {
        NSBeginAlertSheet([NSString stringWithFormat:@"Unable to disable %@", [self.inputFileInfo.filename lastPathComponent]], 
                            nil, nil, nil, [[NSApplication sharedApplication] mainWindow], 
                            nil, nil, nil, nil, 
                            @"File is being encoded. Stop encoding then try again.");
        return;
    }
    
    m_enabled = enabled;
    [[AppController instance] updateEncodingInfo];    
}

-(FileInfoPanelController*) fileInfoPanelController
{
    return [[AppController instance] fileInfoPanelController];
}

-(BOOL) _validateInputFile: (TranscoderFileInfo*) info
{
    NSMutableString* mediainfoPath = [NSMutableString stringWithString: [[NSBundle mainBundle] resourcePath]];
    [mediainfoPath appendString:@"/bin/mediainfo"];
    
    NSMutableString* mediainfoInformPath = [NSMutableString stringWithString: @"--Inform=file://"];
    [mediainfoInformPath appendString: [[NSBundle mainBundle] resourcePath]];
    [mediainfoInformPath appendString:@"/mediainfo-inform.csv"];
    
    NSTask* task = [[NSTask alloc] init];
    NSMutableArray* args = [NSMutableArray arrayWithObjects: mediainfoInformPath, [info filename], nil];
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
    
    NSArray* components = [data componentsSeparatedByString:@"\n"];
    
    // We always have a General line.
    NSArray* general = [[components objectAtIndex:0] componentsSeparatedByString:@","];
    if ([general count] != 6)
        return NO;
        
    [info setFormat: [general objectAtIndex:1]];
    info.isQuicktime = [[general objectAtIndex:2] isEqualToString:@"QuickTime"];
    info.duration = [[general objectAtIndex:3] doubleValue] / 1000;
    info.fileSize = [[general objectAtIndex:5] doubleValue];

    if ([info.format length] == 0)
        return NO;
        
    // Do video if it's there
    int offset = 1;
    if ([components count] > offset && [[components objectAtIndex:offset] hasPrefix: @"-Video-"]) {
        NSArray* video = [[components objectAtIndex:offset] componentsSeparatedByString:@","];
        offset = 2;
        
        // -Video-,%StreamKindID%,%ID%,%Language%,%Format%,%Codec_Profile%,%ScanType%,%ScanOrder%,%Width%,%Height%,%PixelAspectRatio%,%DisplayAspectRatio%,%FrameRate%.%Bitrate%

        if ([video count] != 14)
            return NO;
            
        info.videaStreamKind = [[video objectAtIndex:1] intValue];
        info.videoTrack = [[video objectAtIndex:2] intValue];
        info.videoLanguage = [[video objectAtIndex:3] retain];
        info.videoCodec = [[video objectAtIndex:4] retain];
        info.videoProfile = [[video objectAtIndex:5] retain];
        info.videoInterlaced = [[video objectAtIndex:6] isEqualToString:@"Interlace"];
        FrameSize frameSize = makeFrameSize([[video objectAtIndex:8] intValue], [[video objectAtIndex:9] intValue]);
        info.videoFrameSize = frameSize;
        info.videoAspectRatio = [[video objectAtIndex:11] doubleValue];
        info.videoFrameRate = [[video objectAtIndex:12] doubleValue];
        info.videoBitrate = [[video objectAtIndex:13] doubleValue];
        
        // standardize video codec name
        NSString* f = VC_H264;
        if ([info.videoCodec caseInsensitiveCompare:@"vc-1"] == NSOrderedSame || [info.videoCodec caseInsensitiveCompare:@"wmv3"] == NSOrderedSame)
            f = VC_WMV3;
        else if ([info.videoCodec caseInsensitiveCompare:@"avc"] == NSOrderedSame || [info.videoCodec caseInsensitiveCompare:@"avc1"] == NSOrderedSame)
            f = VC_H264;
    
        info.videoCodec = f;
    }
    
    // Do audio if it's there
    if ([components count] > offset && [[components objectAtIndex:offset] hasPrefix: @"-Audio-"]) {
        NSArray* audio = [[components objectAtIndex:offset] componentsSeparatedByString:@","];

        // -Audio-,%StreamKindID%,%ID%,%Language%,%Format%,%SamplingRate%,%Channels%,%BitRate%
        if ([audio count] != 8)
            return NO;
            
        info.audioStreamKind = [[audio objectAtIndex:1] intValue];
        info.audioTrack = [[audio objectAtIndex:2] intValue];
        info.audioLanguage = [[audio objectAtIndex:3] retain];
        info.audioCodec = [[audio objectAtIndex:4] retain];
        info.audioSampleRate = [[audio objectAtIndex:5] doubleValue];
        info.audioChannels = [[audio objectAtIndex:6] intValue];
        info.audioBitrate = [[audio objectAtIndex:7] doubleValue];
    }
    
    // compute some values
    info.bitrate = info.videoBitrate + info.audioBitrate;

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

+(Transcoder*) transcoder
{
    Transcoder* transcoder = [[Transcoder alloc] init];
    transcoder->m_inputFiles = [[NSMutableArray alloc] init];
    transcoder->m_outputFiles = [[NSMutableArray alloc] init];
    transcoder->m_fileStatus = FS_INVALID;
    transcoder->m_enabled = YES;
    transcoder->m_tempAudioFileName = [[NSString stringWithFormat:@"/tmp/%p-tmpaudio.wav", transcoder] retain];
    transcoder->m_passLogFileName = [[NSString stringWithFormat:@"/tmp/%p-tmppass.log", transcoder] retain];
    
    // init the progress indicator
    transcoder->m_progressIndicator = [[NSProgressIndicator alloc] init];
    [transcoder->m_progressIndicator setMinValue:0];
    [transcoder->m_progressIndicator setMaxValue:1];
    [transcoder->m_progressIndicator setIndeterminate: NO];
    [transcoder->m_progressIndicator setBezeled: NO];
    
    // init the status image view
    transcoder->m_statusImageView = [[NSImageView alloc] init];
    [transcoder->m_statusImageView setImage: getFileStatusImage(transcoder->m_fileStatus)];

    return transcoder;
}

-(void) dealloc
{
    [m_progressIndicator removeFromSuperview];
    [m_statusImageView removeFromSuperview];
    [m_progressIndicator release];
    [m_statusImageView release];
    
    [super dealloc];
}
    
-(void) createMetadata
{
    self.metadata = [Metadata metadataWithTranscoder:self];
}

- (int) addInputFile: (NSString*) filename
{
    TranscoderFileInfo* file = [[TranscoderFileInfo alloc] init];
    file.filename = filename;
    
    if (![self _validateInputFile: file ]) {
        [file release];
        m_fileStatus = FS_INVALID;
        m_enabled = false;
        [m_statusImageView setImage: getFileStatusImage(m_fileStatus)];
        return -1;
    }

    [m_inputFiles addObject: file];
    [file release];
    m_fileStatus = FS_VALID;
    [m_statusImageView setImage: getFileStatusImage(m_fileStatus)];
    
    // read the metadata
    [self createMetadata];
    if ([[[AppController instance] fileInfoPanelController] autoSearch])
        [self.metadata searchAgain];
    
    return [m_inputFiles count] - 1;    
}

- (int) addOutputFile: (NSString*) filename
{
    TranscoderFileInfo* file = [[TranscoderFileInfo alloc] init];
    [m_outputFiles addObject: file];
    [file release];
    file.filename = filename;
    return [m_outputFiles count] - 1;    
}

-(void) changeOutputFileName: (NSString*) filename
{
    if ([m_outputFiles count] > 0)
        [[m_outputFiles objectAtIndex: 0] setFilename: filename];
}

-(NSValue*) progressCell
{
    return [NSValue valueWithPointer:self];
}

-(void) resetStatus
{
    // If we're enabled, set the status to FS_VALID, even if we were M_FAILED or M_INVALID.
    // This gives the encoder a chance to run, just in case we were wrong about it.
    if (m_enabled) {
        m_fileStatus = FS_VALID;
        [m_statusImageView setImage: getFileStatusImage(m_fileStatus)];
    }
}

-(NSProgressIndicator*) progressIndicator
{
    return m_progressIndicator;
}

-(NSImageView*) statusImageView
{
    return m_statusImageView;
}

-(FileStatus) fileStatus
{
    return m_fileStatus;
}

-(BOOL) isInputQuicktime
{
    return [[self inputFileInfo] isQuicktime];
}

-(BOOL) hasInputAudio
{
    return [[self inputFileInfo] audioSampleRate] != 0;
}

-(NSString*) tempAudioFileName
{
    return m_tempAudioFileName;
}

-(NSString*) passLogFileName
{
    return m_passLogFileName;
}

-(NSString*) audioQuality
{
    return m_audioQuality;
}

-(void) setParams
{
    if ([m_outputFiles count] == 0)
        return;
        
    // build the environment
    NSMutableDictionary* env = [[NSMutableDictionary alloc] init];

    // fill in the environment
    NSString* cmdPath = [NSString stringWithString: [[NSBundle mainBundle] resourcePath]];
    [env setValue: [cmdPath stringByAppendingPathComponent: @"bin/ffmpeg"] forKey: @"ffmpeg"];
    [env setValue: [cmdPath stringByAppendingPathComponent: @"bin/qt_export"] forKey: @"qt_export"];
    [env setValue: [cmdPath stringByAppendingPathComponent: @"bin/movtoy4m"] forKey: @"movtoy4m"];
    [env setValue: [cmdPath stringByAppendingPathComponent: @"bin/yuvadjust"] forKey: @"yuvadjust"];
    [env setValue: [cmdPath stringByAppendingPathComponent: @"bin/yuvcorrect"] forKey: @"yuvcorrect"];
    [env setValue: [cmdPath stringByAppendingPathComponent: @"bin/AtomicParsley"] forKey: @"AtomicParsley"];

    // fill in the filenames
    [env setValue: self.inputFileInfo.filename forKey: @"input_file"];
    [env setValue: self.outputFileInfo.filename forKey: @"output_file"];
    [env setValue: [self tempAudioFileName] forKey: @"tmp_audio_file"];
    [env setValue: [self passLogFileName] forKey: @"pass_log_file"];
    
    // fill in params
    FrameSize frameSize = self.inputFileInfo.videoFrameSize;
    [env setValue: [[NSNumber numberWithInt: widthFromFrameSize(frameSize)] stringValue] forKey: @"input_video_width"];
    [env setValue: [[NSNumber numberWithInt: heightFromFrameSize(frameSize)] stringValue] forKey: @"input_video_height"];
    [env setValue: [[NSNumber numberWithDouble: self.inputFileInfo.videoFrameRate] stringValue] forKey: @"input_frame_rate"];
    [env setValue: [[NSNumber numberWithDouble: self.inputFileInfo.videoAspectRatio] stringValue] forKey: @"input_video_aspect"];
    [env setValue: [[NSNumber numberWithInt: self.inputFileInfo.videoBitrate] stringValue] forKey: @"input_video_bitrate"];
    
    [env setValue: ([self isInputQuicktime] ? @"true" : @"false") forKey: @"is_quicktime"];
    [env setValue: ([self hasInputAudio] ? @"true" : @"false") forKey: @"has_audio"];
    [env setValue: ([[AppController instance] limitParams] ? @"true" : @"false") forKey: @"limit_output_params"];
    
    // set the number of CPUs
    [env setValue: [[NSNumber numberWithInt: [[AppController instance] numCPUs]] stringValue] forKey: @"num_cpus"];

    [env setValue: self.inputFileInfo.videoCodec forKey: @"input_video_codec"];

    // set the params
    [[[AppController instance] deviceController] setCurrentParamsWithEnvironment:env];
    
    // save some of the values
    int width = [[[[AppController instance] deviceController] paramForKey:@"output_video_width"] intValue];
    int height = [[[[AppController instance] deviceController] paramForKey:@"output_video_height"] intValue];
    if (width > 32767)
        width = 32767;
    if (height > 32767)
        height = 32767;
        
    frameSize = makeFrameSize(width, height);
    self.outputFileInfo.videoFrameSize = frameSize;
    self.outputFileInfo.videoAspectRatio = (double) width / (double) height;
    
    self.outputFileInfo.format = [[[AppController instance] deviceController] paramForKey:@"output_format_name"];

    self.outputFileInfo.videoCodec = [[[AppController instance] deviceController] paramForKey:@"output_video_codec_name"];
    NSString* profile = [[[AppController instance] deviceController] paramForKey:@"output_video_profile_name"];
    int level = [[[[AppController instance] deviceController] paramForKey:@"output_video_level_name"] intValue];
    self.outputFileInfo.videoProfile = [NSString stringWithFormat:@"%@@%d.%d", profile, level/10, level%10];
    self.outputFileInfo.videoFrameRate = [[[[AppController instance] deviceController] paramForKey:@"output_video_frame_rate"] floatValue];
    self.outputFileInfo.videoBitrate = [[[[AppController instance] deviceController] paramForKey:@"output_video_bitrate"] floatValue];
    
    m_audioQuality = [[[AppController instance] deviceController] paramForKey:@"audio_quality"];

    self.outputFileInfo.audioCodec = [[[AppController instance] deviceController] paramForKey:@"output_audio_codec_name"];
    self.outputFileInfo.audioBitrate = [[[[AppController instance] deviceController] paramForKey:@"output_audio_bitrate"] floatValue];
    self.outputFileInfo.audioSampleRate = [[[[AppController instance] deviceController] paramForKey:@"output_audio_sample_rate"] floatValue];
    self.outputFileInfo.audioChannels = [[[[AppController instance] deviceController] paramForKey:@"output_audio_channels"] intValue];

    self.outputFileInfo.bitrate = self.outputFileInfo.videoBitrate + self.outputFileInfo.audioBitrate;
    self.outputFileInfo.fileSize = self.outputFileInfo.duration * self.outputFileInfo.bitrate / 8;
}

-(void) finish: (int) status
{
    BOOL deleteOutputFile = NO;
    BOOL moveOutputFileToTrash = NO;
    
    m_fileStatus = (status == 0) ? FS_SUCCEEDED : (status == 255) ? FS_VALID : FS_FAILED;
    
    if (status == 0) {
        [[AppController instance] log: @"Succeeded!\n"];
        
        if ([[AppController instance] addToMediaLibrary]) {
            NSString* filename = [[[AppController instance] deviceController] shouldWriteMetadataToInputFile] ?
                                self.inputFileInfo.filename : self.outputFileInfo.filename;
            if (![self addToMediaLibrary: filename]) {
                m_fileStatus = FS_FAILED;
            }
            else if ([[AppController instance] deleteFromDestination] && ![[[AppController instance] deviceController] shouldWriteMetadataToInputFile])
                moveOutputFileToTrash = YES;
        }
    }
    else {
        deleteOutputFile = YES;
        [[AppController instance] log: @"FAILED with error code: %d\n", status];
    }
        
    [m_statusImageView setImage: getFileStatusImage(m_fileStatus)];
    if (m_fileStatus != FS_VALID)
        m_enabled = false;
    m_progress = (status == 0) ? 1 : 0;
    [m_progressIndicator setDoubleValue: m_progress];
    [[AppController instance] encodeFinished:self withStatus:status];
    [m_logFile closeFile];
    [m_logFile release];
    m_logFile = nil;
    
    // toss output file if not successful
    if (deleteOutputFile)
        [[NSFileManager defaultManager] removeFileAtPath:self.outputFileInfo.filename handler:nil];
    else if (moveOutputFileToTrash)
        [[NSWorkspace sharedWorkspace] 
            performFileOperation:NSWorkspaceRecycleOperation 
            source:[self.outputFileInfo.filename stringByDeletingLastPathComponent]
            destination:@""
            files:[NSArray arrayWithObject:[self.outputFileInfo.filename lastPathComponent]]
            tag:nil];
            
    // In case metadata was written, cleanup after it
    [self.metadata cleanupAfterMetadataWrite];
}

-(void) startNextCommands
{
    Command* command = [m_commands objectAtIndex:m_currentCommandIndex];
    
    while (1) {
        if ([m_commands count]-1 == m_currentCommandIndex)
            m_isLastCommandRunning = YES;
            
        Command* nextCommand = m_isLastCommandRunning ? nil : [m_commands objectAtIndex:m_currentCommandIndex+1];
        [command execute: nextCommand];
        m_currentCommandIndex++;
        if (!nextCommand || [command needsToWait])
            return;
        command = nextCommand;
    }
}

- (BOOL) startEncode
{
    if ([m_outputFiles count] == 0 || !m_enabled)
        return NO;
    
    // Make sure the output file doesn't exist
    if ([[NSFileManager defaultManager] fileExistsAtPath: self.outputFileInfo.filename]) {
        NSRunAlertPanel(@"Internal Error", 
                        [NSString stringWithFormat:@"The output file '%@' exists. Video Monkey should never write to an existing file.", self.outputFileInfo.filename], 
                        nil, nil, nil);
        return NO;
    }

    // initialize progress values
    m_progress = 0;
    [m_progressIndicator setDoubleValue: m_progress];
    
    // open the log file
    if (m_logFile) {
        [m_logFile closeFile];
        [m_logFile release];
    }
    
    [[AppController instance] log: @"============================================================================\n"];
    [[AppController instance] log: @"Begin transcode: %@ --> %@\n", [self.inputFileInfo.filename lastPathComponent], [self.outputFileInfo.filename lastPathComponent]];
    
    // Make sure path exists
    NSString* logFilePath = [LOG_FILE_PATH stringByStandardizingPath];
    if (![[NSFileManager defaultManager] fileExistsAtPath: logFilePath])
        [[NSFileManager defaultManager] createDirectoryAtPath:logFilePath withIntermediateDirectories:YES attributes:nil error: nil];
        
    NSString* logFileName = [NSString stringWithFormat:@"%@/%@-%@.log",
                                logFilePath, [self.outputFileInfo.filename lastPathComponent], [[NSDate date] description]];
    [[NSFileManager defaultManager] removeFileAtPath:logFileName handler:nil];
    [[NSFileManager defaultManager] createFileAtPath:logFileName contents:nil attributes:nil];
                                
    m_logFile = [[NSFileHandle fileHandleForWritingAtPath:logFileName] retain];
    
    // make sure the tmp tmp files do not exist
    [[NSFileManager defaultManager] removeFileAtPath:m_tempAudioFileName handler:nil];
    [[NSFileManager defaultManager] removeFileAtPath:m_passLogFileName handler:nil];
    
    [self setParams];

    // get recipe
    NSString* recipe = [[[AppController instance] deviceController] recipe];

    if ([recipe length] == 0) {
        [[AppController instance] log:@"*** ERROR: No recipe returned, probably due to a previous JavaScript error\n"];
        [self finish: -1];
        return NO;
    }
    
    // split out each command separately
    NSArray* elements = [recipe componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@";&|"]];
    
    m_commands = [[NSMutableArray alloc] init];
    NSEnumerator* enumerator = [elements objectEnumerator];
    NSString* s;
    int commandId = 0;
    int index = 0;
    
    if ([[[AppController instance] deviceController] shouldEncode]) {
        while (s = (NSString*) [enumerator nextObject]) {
            CommandOutputType type = OT_NONE;
            
            // in splitting the commands, we've lost it's separator, so we have to reconstruct it from the original string
            index += [s length];
            unichar sep = (index < [recipe length]) ? [recipe characterAtIndex:index] : ';';
            index++;
            
            switch(sep)
            {
                case ';': type = OT_WAIT; break;
                case '|': type = OT_PIPE; break;
                case '&': type = OT_CONTINUE; break;
            }
            
            s = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if (![s length])
                continue;

            // make a Command object for this command
            [m_commands addObject:[[Command alloc] initWithTranscoder:self command:s 
                                outputType:type identifier:[[NSNumber numberWithInt:commandId++] stringValue]]];
        }
    }
    
    if ([[[AppController instance] deviceController] shouldWriteMetadata]) {
        // Before writing metadata, make sure it can be done
        BOOL canWrite = true;
        
        if (![[[AppController instance] deviceController] shouldEncode]) {
            if ([[[AppController instance] deviceController] shouldWriteMetadataToOutputFile]) {
                if (![self.metadata canWriteMetadataToOutputFile])
                    canWrite = false;
            }
            else {
                if (![self.metadata canWriteMetadataToInputFile])
                    canWrite = false;
            }
        }
        
        NSString* filename = [[[AppController instance] deviceController] shouldWriteMetadataToOutputFile] ?
                                self.outputFileInfo.filename :
                                self.inputFileInfo.filename;
        NSString* metadataCommand = [self.metadata metadataCommand:filename];
                                
        if ([metadataCommand length] > 0) {
            if (canWrite) {
                // Add command for writing metadata
                [m_commands addObject:[[Command alloc] initWithTranscoder:self command:metadataCommand
                            outputType:OT_WAIT identifier:[[NSNumber numberWithInt:commandId] stringValue]]];
            }
            else {
                // Can't write metadata to this type of file
                if ([[[AppController instance] deviceController] shouldWriteMetadataToOutputFile])
                    [[AppController instance] log: @"WARNING! Unable to write metadata to output file. "
                                        "Either you haven't yet encoded it and the file doesn't exist, "
                                        "or this file format does not support metadata.\n"];
                else
                    [[AppController instance] log: @"WARNING! Unable to write metadata to input file. "
                                        "This file format probably does not support metadata.\n"];
            }
        }
    }
    
    // execute each command in turn
    if ([m_commands count] > 0) {
        m_isLastCommandRunning = NO;
        m_currentCommandIndex = 0;
        [self startNextCommands];

        m_fileStatus = FS_ENCODING;
        [m_statusImageView setImage: getFileStatusImage(m_fileStatus)];
        return YES;
    }
    else {
        [self finish: -1];
        return NO;
    }
}

- (BOOL) pauseEncode
{
    NSEnumerator* enumerator = [m_commands objectEnumerator];
    Command* command;
    
    while(command = [enumerator nextObject])
        [command suspend];
        
    m_fileStatus = FS_PAUSED;
    return YES;
}

-(BOOL) resumeEncode
{
    NSEnumerator* enumerator = [m_commands objectEnumerator];
    Command* command;
    
    while(command = [enumerator nextObject])
        [command resume];
        
    m_fileStatus = FS_ENCODING;
    return YES;
}

-(BOOL) stopEncode
{
    NSEnumerator* enumerator = [m_commands objectEnumerator];
    Command* command;
    
    while(command = [enumerator nextObject])
        [command terminate];
        
    [self finish: 255];
    return YES;
}

-(BOOL) addToMediaLibrary:(NSString*) filename
{
    iTunesApplication* iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    NSURL *file = [NSURL fileURLWithPath: filename];
    iTunesTrack* track;
    NSString* errorString = nil;
    
    @try {
        track = [iTunes add: [NSArray arrayWithObject:file] to: nil];
        if (!track)
            errorString = @"File could not be added to iTunes (probably an invalid type)";
    }
    @catch (NSException* e) {
        NSError* error = [NSError errorWithDomain:NSCocoaErrorDomain code:[[[e userInfo] valueForKey:@"ErrorNumber"] intValue] userInfo:[e userInfo]];
        errorString = [error localizedDescription];
    }
    
    if (!errorString) {
        [[AppController instance] log: @"Copy to iTunes succeeded!\n"];
        return YES;
    }
    
    // Error
    [[AppController instance] log: @"Copy to iTunes FAILED with error: %@\n", errorString];
    return NO;
}

-(void) setProgressForCommand: (Command*) command to: (double) value
{
    // TODO: need to give each command a percentage of the progress
    m_progress = value;
    [m_progressIndicator setDoubleValue: m_progress];
    [[AppController instance] setProgressFor: self to: m_progress];
}

-(void) commandFinished: (Command*) command status: (int) status
{
    if (m_isLastCommandRunning)
        [self finish: status];
    else
        [self startNextCommands];
}

-(void) updateFileInfo
{
    [[AppController instance] updateFileInfo];
}

-(void) logToFile: (NSString*) string
{
    // Output to log file
    if (m_logFile)
        [m_logFile writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

-(void) logCommand: (NSString*) commandId withFormat: (NSString*) format, ...
{
    va_list args;
    va_start(args, format);
    NSString* string = [[NSString alloc] initWithFormat:format arguments:args];
    [[AppController instance] log: @"    [Command %@] %@\n", commandId, string];
}

-(void) log: (NSString*) format, ...
{
    va_list args;
    va_start(args, format);
    NSString* s = [[NSString alloc] initWithFormat:format arguments: args];
    [[AppController instance] log: s];
}

- (id)valueForUndefinedKey:(NSString *)key
{
    NSLog(@"*** Transcoder::valueForUndefinedKey:%@\n", key);
    return nil;
}

@end
