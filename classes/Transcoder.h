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

// FrameSize is a 32 bit integer with upper 16 bits width and lower 16 bits height
typedef uint32_t FrameSize;

typedef enum FileStatus { FS_INVALID, FS_VALID, FS_ENCODING, FS_PAUSED, FS_FAILED, FS_SUCCEEDED } FileStatus;

@interface TranscoderFileInfo : NSObject {
    // General
    NSString* filename;
    NSString* format;
    double duration;
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
    double displayAspectRatio;
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
@property(readonly) double bitrate;
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
@property(assign) double displayAspectRatio;
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

// Input properties
@property (retain,readonly) NSString* inputFileName;
@property (retain,readonly) NSString* inputFormat;
@property (readonly) double inputDuration;
@property (readonly) double inputFileSize;
@property (readonly) double inputBitrate;

@property (retain,readonly) NSString* inputVideoCodec;
@property (retain,readonly) NSString* inputVideoProfile;
@property (readonly) BOOL inputVideoInterlaced;
@property (readonly) FrameSize inputVideoFrameSize;
@property (readonly) double inputVideoAspectRatio;
@property (readonly) double inputVideoFramerate;
@property (readonly) double inputVideoBitrate;

@property (retain,readonly) NSString* inputAudioCodec;
@property (readonly) double inputAudioSampleRate;
@property (readonly) int inputAudioChannels;
@property (readonly) double inputAudioBitrate;

// Output properties
@property (retain,readwrite) NSString* outputFileName;
@property (retain,readwrite) NSString* outputFormat;
@property (readwrite) double outputDuration;
@property (readonly) double outputFileSize;
@property (readonly) double outputBitrate;

@property (retain,readwrite) NSString* outputVideoCodec;
@property (retain,readwrite) NSString* outputVideoProfile;
@property (readwrite) BOOL outputVideoInterlaced;
@property (readwrite) FrameSize outputVideoFrameSize;
@property (readwrite) double outputVideoAspectRatio;
@property (readwrite) double outputVideoFramerate;

@property (retain,readwrite) NSString* outputAudioCodec;
@property (readwrite) double outputAudioSampleRate;
@property (readwrite) int outputAudioChannels;
@property (readwrite) double outputAudioBitrate;

-(Transcoder*) initWithController: (AppController*) controller;

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

@end
