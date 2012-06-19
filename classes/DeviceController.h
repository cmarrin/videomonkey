//
//  DeviceController.h
//  DeviceController
//
//  Created by Chris Marrin on 11/12/08.

/*
Copyright (c) 2009-2011 Chris Marrin (chris@marrin.com)
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

    - Redistributions of source code must retain the above copyright notice, this 
      list of conditions and the following disclaimer.

    - Redistributions in binary form must reproduce the above copyright notice, 
      this list of conditions and the following disclaimer in the documentation 
      and/or other materials provided with the distribution.

    - Neither the name of Video Monkey nor the names of its contributors may be 
      used to endorse or promote products derived from this software without 
      specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY 
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH 
DAMAGE.
*/

#import <Cocoa/Cocoa.h>


#define VC_H264 @"h.264"
#define VC_WMV3 @"wmv3"

@class DeviceEntry;
@class JavaScriptContext;

typedef enum { ActionEncodeWrite = 0, ActionEncodeOnly, ActionWriteOnly, ActionRewriteOnly } ActionType;

@interface DeviceController : NSObject {
    IBOutlet NSTabView* m_deviceControllerTabView;
    IBOutlet NSPopUpButton* m_deviceButton;
    IBOutlet NSTextField* m_bewareMessage;
    IBOutlet NSPopUpButton* m_performanceButton;
    IBOutlet NSPopUpButton* m_actionButton;
    IBOutlet NSTextField* m_deviceName;
    IBOutlet NSImageView* m_deviceImageView;
    
    DeviceEntry* m_defaultDevice;
    NSMutableArray* m_devices;
    
    DeviceEntry* m_currentDevice;
    double m_bitrate;

    JavaScriptContext* m_context;
    id m_delegate;
    BOOL m_metadataActionsEnabled;

    NSArray* m_audioCodecStrings;
    NSArray* m_audioChannelsStrings;
    NSArray* m_audioBitrateStrings;
    NSArray* m_audioSampleRateStrings;
    NSArray* m_videoCodecStrings;
    NSArray* m_videoProfileStrings;
}

@property(readwrite,retain) NSArray* audioCodecStrings;
@property(readwrite,retain) NSArray* audioChannelsStrings;
@property(readwrite,retain) NSArray* audioBitrateStrings;
@property(readwrite,retain) NSArray* audioSampleRateStrings;
@property(readwrite,retain) NSArray* videoCodecStrings;
@property(readwrite,retain) NSArray* videoProfileStrings;

- (IBAction)selectDevice:(id)sender;
- (IBAction)changeUI:(id)sender;

- (NSString*)fileSuffix;

- (void)initWithDelegate:(id) delegate;
- (void)setCurrentParamsWithEnvironment: (NSDictionary*) env;
- (NSString*)recipe;
- (NSString*)paramForKey:(NSString*) key;
- (BOOL)hasParamForKey:(NSString*) key;

- (BOOL)shouldEncode;
- (BOOL)shouldWriteMetadata;
- (BOOL)shouldWriteMetadataToInputFile;
- (BOOL)shouldWriteMetadataToOutputFile;

- (void)processResponse:(NSString*) response forCommand:(NSString*) command;

- (void)uiChanged;

@end
