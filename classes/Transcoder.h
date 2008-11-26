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

@interface OutputFile : NSObject {
  @private
    float m_bitrate;
    NSString* m_filename;
}

-(void) setFilename: (NSString*) filename;
-(NSString*) filename;
-(void) setBitrate: (float) bitrate;
-(float) bitrate: (float) bitrate;

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
-(float) bitrate;
-(BOOL) startEncode;
-(BOOL) pauseEncode;

@end
