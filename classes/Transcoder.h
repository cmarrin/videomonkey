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

@interface OutputFile : NSObject {
  @private
    float bitrate;
    NSString* filename;
}

@end

@interface Transcoder : NSObject {
  @private
    pid_t m_process;
    NSMutableArray/*<NSString>*/* m_inputFiles;
    NSMutableArray/*<OutputFile>*/* m_outputFiles;
}

- (BOOL) addInputFile: (NSString*) filename;
- (BOOL) addOutputFile: (NSString*) filename;
- (void) setBitRate: (float) rate;
- (BOOL) startEncode;
- (BOOL) pauseEncode;

/*
float ffmpeg_getProgress(ffmpeg_Context);
float ffmpeg_getFloatParam(ffmpeg_Context, const char* name);
const char* ffmpeg_getStringParam(ffmpeg_Context, const char* name);
*/

@end
