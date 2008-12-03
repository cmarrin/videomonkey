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
    if ([general count] != 4)
        return NO;
        
    [info setFormat: [general objectAtIndex:1]];
    info->m_playTime = [[general objectAtIndex:2] doubleValue] / 1000;
    info->m_bitrate = [[general objectAtIndex:3] doubleValue];
    
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
    m_buffer = [[NSMutableString alloc] init];
    m_fileStatus = FS_INVALID;
    
    // init the progress indicator
    m_progressIndicator = [[NSProgressIndicator alloc] init];
    [m_progressIndicator setMinValue:0];
    [m_progressIndicator setMaxValue:1];
    [m_progressIndicator setIndeterminate: NO];

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
    
    m_task = [[NSTask alloc] init];
    [m_task retain];
    NSString* inputFilename = ((TranscoderFileInfo*) [m_inputFiles objectAtIndex:0])->m_filename;
    NSMutableArray* args = [NSMutableArray arrayWithObjects: 
                                            @"-nobanner", 
                                            @"-stream_messages", 
                                            @"-v", @"-1",
                                            @"-y", 
                                            @"-i", inputFilename, 
                                            @"-sameq", 
                                            @"/tmp/foo.mov", // output file
                                            nil];
    [m_task setArguments: args];
    [m_task setLaunchPath: ffmpegPath];
    
    m_pipe = [NSPipe pipe];
    [m_pipe retain];
    [m_task setStandardError: [m_pipe fileHandleForWriting]];
    
    // add notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processFinishEncode:) name:NSTaskDidTerminateNotification object:m_task];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processRead:) name:NSFileHandleReadCompletionNotification object:[m_pipe fileHandleForReading]];

    [[m_pipe fileHandleForReading] readInBackgroundAndNotify];
    
    [m_task launch];
    
    m_fileStatus = FS_ENCODING;
    return YES;
}

- (BOOL) pauseEncode
{
    return NO;
}

-(void) processFinishEncode: (NSNotification*) note
{
    // TODO: deal with return code
    
    // task ended
    [m_task release];
    [m_pipe release];
    
    // notify the AppController we're done
    m_fileStatus = FS_SUCCEEDED;
    [m_appController encodeFinished: self];
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
        m_progress = 1;
        [m_progressIndicator setDoubleValue: m_progress];
        [m_appController setProgressFor: self to: 1];
    }
    else {
        // parse out the time
        id val = [dictionary objectForKey: @"time"];
        if (val && [val isKindOfClass: [NSString class]]) {
            double time = [val doubleValue];
            m_progress = time / [self playTime];
            [m_progressIndicator setDoubleValue: m_progress];
            [m_appController setProgressFor: self to: m_progress];
        }
    }
    
    [dictionary release];
}

@end
