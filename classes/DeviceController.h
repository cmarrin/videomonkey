//
//  DeviceController.h
//  DeviceController
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright Chris Marrin 2008. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JavaScriptContext;

#define VC_H264 @"h.264"
#define VC_WMV3 @"wmv3"

@class DeviceEntry;

@interface DeviceController : NSObject {
    IBOutlet NSTabView* m_deviceControllerTabView;
    IBOutlet NSPopUpButton* m_deviceButton;
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
}

-(IBAction)selectDevice:(id)sender;
-(IBAction)selectPerformance:(id)sender;

-(NSString*) fileSuffix;

-(void) setDelegate:(id) delegate;
-(void) setCurrentParamsWithEnvironment: (NSDictionary*) env;
-(NSString*) recipe;
-(NSString*) paramForKey:(NSString*) key;

-(BOOL) shouldEncode;
-(BOOL) shouldWriteMetadata;
-(BOOL) shouldWriteMetadataToInputFile;
-(BOOL) shouldWriteMetadataToOutputFile;

-(void) uiChanged;

@end
