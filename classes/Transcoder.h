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

typedef enum FormatType {
    F_MPEG4,
    F_WM,
    F_WAV,
    F_NONE
} FormatType;

typedef enum VideoCodecType {
    VC_H264,
    VC_NONE
} VideoCodecType;

typedef enum AudioCodecType {
    AC_PCM,
    AC_NONE
} AudioCodecType;

@interface TranscoderFileInfo : NSObject {
  @public
    // General
    FormatType m_format;
    double m_playTime;
    double m_bitrate;
    
    // Video
    int m_videaStreamKind;
    int m_videoTrack;
    NSString* m_videoLanguage;
    VideoCodecType m_videoCodec;
    NSString* m_videoProfile;
    BOOL m_videoInterlaced;
    int m_width;
    int m_height;
    double m_pixelAspectRatio;
    double m_screenAspectRatio;
    double m_frameRate;
    
    // Audio
    int m_audioStreamKind;
    int m_audioTrack;
    NSString* m_audioLanguage;
    AudioCodecType m_audioCodec;
    double m_audioSamplingRate;
    int m_channels;
    int m_audioBitrate;

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
    pid_t m_process;
    NSMutableArray* m_inputFiles;
    NSMutableArray* m_outputFiles;
    float m_bitrate;
    AppController* m_appController;
}

-(Transcoder*) initWithController: (AppController*) controller;
-(void) setAppController: (AppController*) appController;

-(int) addInputFile: (NSString*) filename;
-(int) addOutputFile: (NSString*) filename;
-(void) setBitrate: (float) rate;
-(double) bitrate;
-(double) playTime;
-(NSString*) inputFilename;
-(int) outputFileSize;

-(BOOL) startEncode;
-(BOOL) pauseEncode;

@end
