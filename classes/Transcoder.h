//
//  Transcoder.h
//  VideoMonkey
//
//  Created by Chris Marrin on 11/26/08.
//  Copyright 2008 Chris Marrin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/NSString.h>

#import <unistd.h>

#define LOG_FILE_PATH @"~/Library/Application Support/VideoMonkey/Logs"

@class AppController;
@class Command;
@class Metadata;

// FrameSize is a 32 bit integer with upper 16 bits width and lower 16 bits height
typedef uint32_t FrameSize;

typedef enum FileStatus { FS_INVALID, FS_VALID, FS_ENCODING, FS_PAUSED, FS_FAILED, FS_SUCCEEDED } FileStatus;

@interface TranscoderFileInfo : NSObject {
    // General
    NSString* filename;
    NSString* format;
    double duration;
    double bitrate;
    BOOL isQuicktime;
    double fileSize;
    
    // Video
    int videaStreamKind;
    int videoTrack;
    NSString* videoLanguage;
    NSString* videoCodec;
    NSString* videoProfile;
    BOOL videoInterlaced;
    FrameSize videoFrameSize;
    double videoBitrate;
    double pixelAspectRatio;
    double videoAspectRatio;
    double videoFrameRate;
    
    // Audio
    int audioStreamKind;
    int audioTrack;
    NSString* audioLanguage;
    NSString* audioCodec;
    double audioSampleRate;
    int audioChannels;
    double audioBitrate;
}

// General
@property(retain) NSString* filename;
@property(retain) NSString* format;
@property(assign) double duration;
@property(assign) double bitrate;
@property(assign) BOOL isQuicktime;
@property(assign) double fileSize;

// Video
@property(assign) int videaStreamKind;
@property(assign) int videoTrack;
@property(retain) NSString* videoLanguage;
@property(retain) NSString* videoCodec;
@property(retain) NSString* videoProfile;
@property(assign) BOOL videoInterlaced;
@property(assign) FrameSize videoFrameSize;
@property(assign) double pixelAspectRatio;
@property(assign) double videoAspectRatio;
@property(assign) double videoFrameRate;
@property(assign) double videoBitrate;

// Audio
@property(assign) int audioStreamKind;
@property(assign) int audioTrack;
@property(retain) NSString* audioLanguage;
@property(retain) NSString* audioCodec;
@property(assign) double audioSampleRate;
@property(assign) int audioChannels;
@property(assign) double audioBitrate;

@end

@interface Transcoder : NSObject {
  @private
    NSMutableArray* m_inputFiles;
    NSMutableArray* m_outputFiles;
    Metadata* m_metadata;
    double m_progress;
    BOOL m_enabled;
    FileStatus m_fileStatus;
    AppController* m_appController;
    
    NSTask* m_task;
    NSPipe* m_pipe;
    NSMutableArray* m_commands;
    NSProgressIndicator* m_progressIndicator;
    NSImageView* m_statusImageView;
    BOOL m_isLastCommandRunning;
    
    NSFileHandle* m_logFile;
    NSString* m_tempAudioFileName;
    NSString* m_passLogFileName;
    NSString* m_audioQuality;
}

@property (readwrite) BOOL enabled;
@property (readonly) double progress;

@property (readonly) TranscoderFileInfo* inputFileInfo;
@property (readonly) TranscoderFileInfo* outputFileInfo;
@property (readonly) Metadata* metadata;

+(Transcoder*) transcoderWithController: (AppController*) controller;

-(int) addInputFile: (NSString*) filename;
-(int) addOutputFile: (NSString*) filename;
-(void) changeOutputFileName: (NSString*) filename;

-(NSValue*) progressCell;

-(double) progress;
-(void) resetStatus;
-(NSProgressIndicator*) progressIndicator;
-(NSImageView*) statusImageView;

-(FileStatus) inputFileStatus;

-(BOOL) isInputQuicktime;
-(BOOL) hasInputAudio;
-(NSString*) tempAudioFileName;
-(NSString*) passLogFileName;

-(NSString*) audioQuality;

-(void) setParams;

-(BOOL) startEncode;
-(BOOL) pauseEncode;
-(BOOL) resumeEncode;
-(BOOL) stopEncode;

-(BOOL) addToMediaLibrary:(NSString*) filename;

-(void) setProgressForCommand: (Command*) command to: (double) value;
-(void) commandFinished: (Command*) command status: (int) status;

-(void) logToFile: (NSString*) string;
-(void) logCommand: (NSString*) commandId withFormat: (NSString*) format, ...;
-(void) log: (NSString*) format, ...;

@end
