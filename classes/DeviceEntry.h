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

@class DeviceController;
@class JavaScriptContext;
@class XMLElement;

@interface DeviceTabBase : NSTabViewItem {
    IBOutlet NSSlider* m_slider;
    IBOutlet DeviceController* m_deviceController;
    
    double m_sliderValue;
}

- (IBAction)sliderChanged:(id)sender;
- (IBAction)controlChanged:(id)sender;

- (void)performCustomInitWithContext:(JavaScriptContext*) context;

- (NSString*)deviceName;

- (void)setCheckboxes: (NSDictionary*) checkboxes;
- (void)setMenus: (NSDictionary*) menus;
- (void)setComboboxes: (NSDictionary*) comboboxes;
- (void)setQuality: (NSArray*) qualityStops;

- (int)checkboxState:(int) index;
- (int)menuState:(int) index;
- (NSString*)comboboxValue:(int) index;
- (double)sliderValue;

@end

@interface DeviceTab : DeviceTabBase {
    IBOutlet NSButton* m_button0;
    IBOutlet NSTextField* m_buttonLabel0;
    IBOutlet NSButton* m_button1;
    IBOutlet NSTextField* m_buttonLabel1;
    IBOutlet NSButton* m_button2;          
    IBOutlet NSTextField* m_buttonLabel2;
    IBOutlet NSPopUpButton* m_menu;
    IBOutlet NSTextField* m_menuLabel;
    
    IBOutlet NSMatrix* m_radio;
    IBOutlet NSTextField* m_radioLabel;
    
    IBOutlet NSTextField* m_sliderLabel1;
    IBOutlet NSTextField* m_sliderLabel2;
    IBOutlet NSTextField* m_sliderLabel3;
    IBOutlet NSTextField* m_sliderLabel4;
    IBOutlet NSTextField* m_sliderLabel5;
}

-(void) setCheckboxes: (NSDictionary*) checkboxes;
-(void) setMenus: (NSDictionary*) menus;
-(void) setQuality: (NSArray*) qualityStops;

-(int) checkboxState:(int) index;
-(int) menuState:(int) index;

@end

// Have a custom class for the custom tab since it is so different
@interface CustomDeviceTab : DeviceTabBase {
    IBOutlet NSPopUpButton* m_containerFormatMenu;
    IBOutlet NSPopUpButton* m_videoCodecMenu;
    IBOutlet NSPopUpButton* m_audioCodecMenu;
    IBOutlet NSPopUpButton* m_audioQualityMenu;
    IBOutlet NSPopUpButton* m_extrasMenu;
    IBOutlet NSComboBox* m_frameWidthComboBox;
    IBOutlet NSComboBox* m_frameHeightComboBox;
    IBOutlet NSComboBox* m_frameRateComboBox;
    IBOutlet NSComboBox* m_extraParamsComboBox;

    IBOutlet NSButton* m_sliderEnableButton;
    IBOutlet NSButton* m_matchInputAspectRatioButton;
}

-(IBAction)sliderEnableChanged:(id)sender;

- (void)setMenus: (NSArray*) menus;
- (void)setComboboxes: (NSArray*) comboboxes;

- (int)menuState:(int) index;
- (NSString*)comboboxValue:(int) index;

@end

#define DT_NO_MENUS @"nomenus"
#define DT_RADIO_MENU @"radiomenu"
#define DT_CUSTOM @"custom"
#define DT_DVD @"dvd"

@interface QualityStop : NSObject {
    NSString* m_title;
}

+(QualityStop*) qualityStopWithElement: (XMLElement*) element;

-(NSString*) title;

@end

@interface PerformanceItem : NSObject {
    NSString* m_title;
    
    NSMutableDictionary* m_params;
    NSString* m_script;
}

+(PerformanceItem*) performanceItemWithElement: (XMLElement*) element;

-(NSString*) title;
-(NSDictionary*) params;
-(NSString*) script;

@end

@interface MyButton : NSObject {
    NSString* m_title;
    BOOL m_enabled;
}

-(MyButton*) initWithElement: (XMLElement*) element;

-(NSString*) title;
-(BOOL) enabled;

@end

@interface Checkbox : MyButton {
    NSMutableDictionary* m_checkedParams;
    NSString* m_checkedScript;
    NSMutableDictionary* m_uncheckedParams;
    NSString* m_uncheckedScript;
}

+(Checkbox*) checkboxWithElement: (XMLElement*) element;

-(NSDictionary*) uncheckedParams;
-(NSString*) uncheckedScript;
-(NSDictionary*) checkedParams;
-(NSString*) checkedScript;

@end

@interface Menu : MyButton {
    NSMutableArray* m_itemTitles;
    NSMutableArray* m_itemParams;
    NSMutableArray* m_itemScripts;
}

+(Menu*) menuWithElement: (XMLElement*) element;
-(NSArray*) itemTitles;
-(NSArray*) itemParams;
-(NSArray*) itemScripts;

@end

@interface Combobox : MyButton {
    NSMutableDictionary* m_params;
    NSString* m_script;
}

+(Combobox*) comboboxWithElement: (XMLElement*) element;
-(NSDictionary*) params;
-(NSString*) script;

@end

@interface DeviceEntry : NSObject {
    NSString* m_icon;
    NSString* m_title;
    NSString* m_groupTitle;
    BOOL m_enabled;
    
    DeviceEntry* m_defaultDevice;
    
    NSString* m_deviceTabName;
    DeviceTabBase* m_deviceTab;
    
    NSMutableArray* m_qualityStops;
    NSMutableArray* m_performanceItems;
    NSMutableArray* m_recipes;
    NSMutableDictionary* m_params;
    NSString* m_script;
    NSMutableDictionary* m_checkboxes;
    NSMutableDictionary* m_menus;
    NSMutableDictionary* m_comboboxes;
    
    double m_minBitrate;
    double m_maxBitrate;
    int m_currentQualityStopIndex;
}

+(DeviceEntry*) deviceEntryWithElement: (XMLElement*) element inGroup: (NSString*) group withDefaults: (DeviceEntry*) defaults;
-(DeviceEntry*) initWithElement: (XMLElement*) element inGroup: (NSString*) group withDefaults: (DeviceEntry*) defaults;

-(NSString*) group;
-(NSString*) title;
-(NSString*) icon;
-(BOOL) enabled;
-(NSArray*) qualityStops;
-(NSArray*) performanceItems;
-(NSArray*) recipes;
-(void) quality: (double*) q withStop: (int*) stop;

-(void) setCurrentParamsInJavaScriptContext:(JavaScriptContext*) context performanceIndex:(int) perfIndex;
-(void) populateTabView:(NSTabView*) tabview;
-(void) populatePerformanceButton:(NSPopUpButton*) tabview;
-(void) addParamsToJavaScriptContext: (JavaScriptContext*) context performanceIndex:(int) perfIndex;
-(void) evaluateScript: (JavaScriptContext*) context performanceIndex:(int) perfIndex;

@end
