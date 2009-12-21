//
//  DeviceController.h
//  DeviceController
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright Chris Marrin 2008. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define MAX_CHECKBOXES 4
#define MAX_MENUS 4
#define MAX_RADIOS 4
#define MAX_POPUPS 2

@class DeviceController;
@class JavaScriptContext;
@class XMLElement;

@interface DeviceTab : NSTabViewItem {
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
    
    IBOutlet NSSlider* m_slider;
    IBOutlet NSTextField* m_sliderLabel1;
    IBOutlet NSTextField* m_sliderLabel2;
    IBOutlet NSTextField* m_sliderLabel3;
    IBOutlet NSTextField* m_sliderLabel4;
    IBOutlet NSTextField* m_sliderLabel5;
    
    IBOutlet DeviceController* m_deviceController;
    
    double m_sliderValue;
}

-(IBAction)sliderChanged:(id)sender;
-(IBAction)controlChanged:(id)sender;

-(NSString*) deviceName;

-(void) setCheckboxes: (NSArray*) checkboxes;
-(void) setMenus: (NSArray*) menus;
-(void) setQuality: (NSArray*) qualityStops;

-(int) checkboxState:(int) index;
-(int) menuState:(int) index;
-(double) sliderValue;

@end

#define DT_NO_MENUS @"nomenus"
#define DT_RADIO_MENU @"radiomenu"
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

@interface DeviceEntry : NSObject {
    NSString* m_icon;
    NSString* m_title;
    NSString* m_groupTitle;
    BOOL m_enabled;
    
    DeviceEntry* m_defaultDevice;
    
    NSString* m_deviceTabName;
    DeviceTab* m_deviceTab;
    
    NSMutableArray* m_qualityStops;
    NSMutableArray* m_performanceItems;
    NSMutableArray* m_recipes;
    NSMutableDictionary* m_params;
    NSString* m_script;
    NSMutableArray* m_checkboxes;
    NSMutableArray* m_menus;
    
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
-(NSString*) fileSuffix;
-(void) quality: (double*) q withStop: (int*) stop;

-(void) setCurrentParamsInJavaScriptContext:(JavaScriptContext*) context performanceIndex:(int) perfIndex;
-(void) populateTabView:(NSTabView*) tabview;
-(void) populatePerformanceButton:(NSPopUpButton*) tabview;
-(void) addParamsToJavaScriptContext: (JavaScriptContext*) context performanceIndex:(int) perfIndex;
-(void) evaluateScript: (JavaScriptContext*) context performanceIndex:(int) perfIndex;

@end
