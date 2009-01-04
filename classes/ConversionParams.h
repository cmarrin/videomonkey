//
//  ConversionParams.h
//  ConversionParams
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright Chris Marrin 2008. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ConversionTab : NSTabViewItem {
    IBOutlet NSButton* m_button0;
    IBOutlet NSTextField* m_buttonLabel0;
    IBOutlet NSButton* m_button1;
    IBOutlet NSTextField* m_buttonLabel1;
    IBOutlet NSButton* m_button2;           // menu 0
    IBOutlet NSTextField* m_buttonLabel2;
    IBOutlet NSButton* m_button3;           // menu 1
    IBOutlet NSTextField* m_buttonLabel3;
    
    IBOutlet NSMatrix* m_radio;
    IBOutlet NSTextField* m_radioLabel0;
    
    IBOutlet NSSlider* m_slider;
    IBOutlet NSTextField* m_sliderLabel1;
    IBOutlet NSTextField* m_sliderLabel2;
    IBOutlet NSTextField* m_sliderLabel3;
    IBOutlet NSTextField* m_sliderLabel4;
    IBOutlet NSTextField* m_sliderLabel5;
}

-(NSString*) deviceName;
@end

typedef enum { DT_NONE, DT_LONG_Q_2_CHECK, DT_SHORT_Q_2_RADIO_2_CHECK, DT_SHORT_Q_2_MENU_1_CHECK, DT_DVD } DeviceTabType;

@interface DeviceEntry : NSObject {
    NSString* m_id;
    
    NSDictionary* m_commands;
    DeviceTabType m_deviceTab;
    
    NSString* m_buttonLabel0;
    NSString* m_buttonLabel1;
    NSString* m_buttonLabel2;
    NSString* m_buttonLabel3;
    
    NSString* m_radioTitle;
    NSString* m_radioLabel0;
    NSString* m_radioLabel1;
    
    NSString* m_sliderLabel1;
    NSString* m_sliderLabel2;
    NSString* m_sliderLabel3;
    NSString* m_sliderLabel4;
    NSString* m_sliderLabel5;
}

-(NSString*) id;
@end

#define VC_H264 @"h.264"
#define VC_WMV3 @"wmv3"

@interface ConversionParams : NSObject {
    IBOutlet float *m_quality;
    IBOutlet NSTabView* m_conversionParamsTabView;
    IBOutlet NSPopUpButton* m_conversionParamsButton;
    IBOutlet NSPopUpButton* m_performanceButton;
    
    NSDictionary* m_commands;
    NSDictionary* m_environment;

    ConversionTab* m_currentTabViewItem;
    NSString* m_currentPerformance;
    BOOL m_isTwoPass;
}

-(IBAction)selectTab:(id)sender;
-(IBAction)selectPerformance:(id)sender;
-(IBAction)paramChanged:(id)sender;

-(BOOL) isTwoPass;
-(NSString*) performance;
-(NSString*) device;
@end
