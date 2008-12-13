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

@class AppController;
@class Command;

typedef enum FileStatus { FS_INVALID, FS_VALID, FS_ENCODING, FS_PAUSED, FS_FAILED, FS_SUCCEEDED } FileStatus;

@interface TranscoderFileInfo : NSObject {
  @public
    // General
    NSString* m_format;
    double m_playTime;
    double m_bitrate;
    BOOL m_isQuicktime;
    
    // Video
    int m_videaStreamKind;
    int m_videoTrack;
    NSString* m_videoLanguage;
    NSString* m_videoCodec;
    NSString* m_videoProfile;
    BOOL m_videoInterlaced;
    int m_width;
    int m_height;
    double m_pixelAspectRatio;
    double m_displayAspectRatio;
    double m_frameRate;
    
    // Audio
    int m_audioStreamKind;
    int m_audioTrack;
    NSString* m_audioLanguage;
    NSString* m_audioCodec;
    double m_audioSamplingRate;
    int m_channels;
    double m_audioBitrate;

    NSString* m_filename;
}

-(void) setFormat: (NSString*) format;
-(void) setVideoLanguage: (NSString*) lang;
-(void) setVideoCodec: (NSString*) codec;
-(void) setVideoProfile: (NSString*) profile;
-(void) setAudioLanguage: (NSString*) lang;
-(void) setAudioCodec: (NSString*) codec;
-(void) setFilename: (NSString*) filename;

@end

@interface Transcoder : NSObject {
  @private
    NSMutableArray* m_inputFiles;
    NSMutableArray* m_outputFiles;
    double m_bitrate;
    double m_totalDuration;
    double m_progress;
    BOOL m_enabled;
    FileStatus m_fileStatus;
    AppController* m_appController;
    
    NSTask* m_task;
    NSPipe* m_pipe;
    NSMutableArray* m_commands;
    NSProgressIndicator* m_progressIndicator;
    NSImageView* m_statusImageView;
    
    NSFileHandle* logFile;
    NSString* m_tempAudioFileName;
}

-(Transcoder*) initWithController: (AppController*) controller;

-(int) addInputFile: (NSString*) filename;
-(int) addOutputFile: (NSString*) filename;
-(void) changeOutputFileName: (NSString*) filename;
-(void) setBitrate: (float) rate;
-(double) bitrate;
-(double) playTime;

-(double) progress;
-(BOOL) isEnabled;
-(void) setEnabled: (BOOL) b;
-(NSProgressIndicator*) progressIndicator;
-(NSImageView*) statusImageView;

-(FileStatus) inputFileStatus;
-(NSString*) inputFileName;
-(int) inputVideoWidth;
-(int) inputVideoHeight;
-(int) inputVideoWidthDiv2;
-(int) inputVideoHeightDiv2;
-(int) inputVideoWidthDiv16;
-(int) inputVideoHeightDiv16;
-(BOOL) isInputQuicktime;
-(BOOL) hasInputAudio;
-(NSString*) outputFileName;
-(int) outputFileSize;
-(NSString*) tempAudioFileName;

-(NSString*) ffmpeg_vcodec;

-(BOOL) startEncode;
-(BOOL) pauseEncode;
-(BOOL) resumeEncode;
-(BOOL) stopEncode;

-(void) setProgressForCommand: (Command*) command to: (double) value;
-(void) commandFinished: (Command*) command status: (int) status;

-(void) log: (NSString*) format, ...;

@end
