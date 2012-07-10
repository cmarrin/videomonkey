//
//  DeviceController.m
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

#import "DeviceEntry.h"
#import "DeviceController.h"
#import "JavaScriptContext.h"
#import "XMLDocument.h"

//
//
// Application delegate interface
//
//
@interface NSObject (AppDelegate)
-(void) log: (NSString*) format, ...;
@end
 
//
//
// Static functions used in this file
//
//
static void addParam(XMLElement* paramElement, NSMutableDictionary* dictionary)
{
    NSString* key = [paramElement stringAttribute:@"id"];
    NSString* value = [paramElement stringAttribute:@"value"];
    if ([key length])
        [dictionary setValue:value forKey:key];
}

static void addCommand(XMLElement* paramElement, NSMutableDictionary* dictionary)
{
    NSString* key = [paramElement stringAttribute:@"id"];
    NSString* value = [paramElement content];
    if ([key length])
        [dictionary setValue:value forKey:key];
}

static void parseParams(XMLElement* element, NSMutableDictionary* dictionary)
{
    // handle <param>
    NSArray* array = [element elementsForName: @"param"];
    for (XMLElement* element in array)
        addParam(element, dictionary);

    // handle <command>
    array = [element elementsForName: @"command"];
    for (XMLElement* element in array)
        addCommand(element, dictionary);
}

static NSString* parseScripts(XMLElement* element)
{
    NSMutableString* script = [[NSMutableString alloc] init];
    NSArray* array = [element elementsForName: @"script"];
    for (XMLElement* element in array) {
        [script appendString:[element content]];
        [script appendString:@"\n\n"];
    }
    
    return script;
}

//
//
// Device Tab Base interface
//
//
@implementation DeviceTabBase

- (void)performCustomInitWithContext:(JavaScriptContext*) context
{
}

-(NSString*) deviceName
{
    return [self identifier];
}

-(void) setCheckboxes: (NSDictionary*) checkboxes
{
}

-(void) setMenus: (NSDictionary*) menus
{
}

-(void) setComboboxes: (NSDictionary*) comboboxes
{
}

-(void) setQuality: (NSArray*) qualityStops
{
}

- (int)checkboxState:(int) index
{
    return 0;
}

- (int)menuState:(int) index
{
    return 0;
}

- (NSString*)comboboxValue:(int) index
{
    return 0;
}

- (IBAction)sliderChanged:(id)sender {
    double value = [sender doubleValue];
    if (value != m_sliderValue) {
        m_sliderValue = value;
        [m_deviceController uiChanged];
    }
}

-(IBAction)controlChanged:(id)sender
{
    [m_deviceController uiChanged];
}

-(double) sliderValue
{
    m_sliderValue = [m_slider doubleValue];
    return m_sliderValue;
}

@end

//
//
// Device Tab interface
//
//
@implementation DeviceTab

static void setButton(NSButton* button, MyButton* item)
{
    NSString* title = [item title];
    BOOL enabled = [item enabled];
    
    if (title) {
        [button setHidden:NO];
        [button setTitle:title];
        [button sizeToFit];
        [button setEnabled:enabled];
    }
    else
        [button setHidden:YES];
}

-(void) setCheckboxes: (NSDictionary*) checkboxes
{
    setButton(m_button0, ((MyButton*) [checkboxes valueForKey:@"0"]));
    setButton(m_button1, ((MyButton*) [checkboxes valueForKey:@"1"]));
    setButton(m_button2, ((MyButton*) [checkboxes valueForKey:@"2"]));
}

-(void) setMenus: (NSDictionary*) menus
{    
    // menu 0 is the radio (with 2 choices) and menu 1 is the menu
    Menu* menu0 = (Menu*) [menus valueForKey:@"0"];
    Menu* menu1 = (Menu*) [menus valueForKey:@"1"];
    
    if (m_radio && menu0) {            
        [m_radioLabel setHidden:NO];
        [m_radioLabel setStringValue:[menu0 title]];
        [m_radio setHidden:NO];
            
        NSArray* itemTitles = [menu0 itemTitles];
        [m_radio renewRows:[itemTitles count] columns:1];
        for (int i = 0; i < [itemTitles count]; ++i) {
            NSButtonCell* cell = (NSButtonCell*) [m_radio cellAtRow:i column:0];
            [cell setTitle:[itemTitles objectAtIndex:i]];
        }
    }
    else {
        [m_radioLabel setHidden:YES];
        [m_radio setHidden:YES];
    }
    
    if (m_menu && menu1) {
        // handle menus
        [m_menuLabel setHidden:NO];
        [m_menuLabel setStringValue:[menu1 title]];
        [m_menu setHidden:NO];

        NSArray* itemTitles = [menu1 itemTitles];
        [m_menu removeAllItems];
        for (int i = 0; i < [itemTitles count]; ++i)
            [m_menu insertItemWithTitle:[itemTitles objectAtIndex:i] atIndex:i];
            
        [m_menu sizeToFit];
    }
    else {
        [m_menuLabel setHidden:YES];
        [m_menu setHidden:YES];
    }	
}

-(void) setQuality: (NSArray*) qualityStops
{
    // We can draw a slider with 2, 3, or 5 tick marks. 
	// If its 1 we keep it but disable it. I think it looks cleaner.
    // If we see any other number in the array we will turn off the quality slider
    [m_slider setHidden:NO];
    [m_slider setEnabled:YES];
    [m_sliderLabel1 setHidden:NO];
    [m_sliderLabel2 setHidden:NO];
    [m_sliderLabel3 setHidden:NO];
    [m_sliderLabel4 setHidden:NO];
    [m_sliderLabel5 setHidden:NO];
	
	if([qualityStops count] == 1) {
		[m_slider setEnabled:NO];
		[m_sliderLabel1 setEnabled:NO];
		[m_sliderLabel2 setEnabled:NO];
		[m_sliderLabel3 setEnabled:NO];
		[m_sliderLabel4 setEnabled:NO];
		[m_sliderLabel5 setEnabled:NO];
	}
    else if ([qualityStops count] == 2) {
        [m_slider setNumberOfTickMarks:2];
        [m_sliderLabel1 setStringValue:[(QualityStop*) [qualityStops objectAtIndex:0] title]];
        [m_sliderLabel2 setHidden:YES];
        [m_sliderLabel3 setHidden:YES];
        [m_sliderLabel4 setHidden:YES];
        [m_sliderLabel5 setStringValue:[(QualityStop*) [qualityStops objectAtIndex:1] title]];
    }
    else if ([qualityStops count] == 3) {
        [m_slider setNumberOfTickMarks:3];
        [m_sliderLabel1 setStringValue:[(QualityStop*) [qualityStops objectAtIndex:0] title]];
        [m_sliderLabel2 setHidden:YES];
        [m_sliderLabel3 setStringValue:[(QualityStop*) [qualityStops objectAtIndex:1] title]];
        [m_sliderLabel4 setHidden:YES];
        [m_sliderLabel5 setStringValue:[(QualityStop*) [qualityStops objectAtIndex:2] title]];
    }
    else if ([qualityStops count] == 5) {
        [m_slider setNumberOfTickMarks:5];
        [m_sliderLabel1 setStringValue:[(QualityStop*) [qualityStops objectAtIndex:0] title]];
        [m_sliderLabel2 setStringValue:[(QualityStop*) [qualityStops objectAtIndex:1] title]];
        [m_sliderLabel3 setStringValue:[(QualityStop*) [qualityStops objectAtIndex:2] title]];
        [m_sliderLabel4 setStringValue:[(QualityStop*) [qualityStops objectAtIndex:3] title]];
        [m_sliderLabel5 setStringValue:[(QualityStop*) [qualityStops objectAtIndex:4] title]];
    }
    else 
        [m_slider setHidden:YES];
}

-(int) checkboxState:(int) index
{
    NSButton* button = (index == 0) ? m_button0 : (index == 1) ? m_button1 : ((index == 2) ? m_button2 : nil);
    
    // return 1 if button is one, 0 if it is off, or -1 if it is hidden
    return button ? ([button isHidden] ? -1 : (([button state] == NSOnState) ? 1 : 0)) : -1;
}

-(int) menuState:(int) index
{
    if (index == 0 && m_radio)
        // return -1 if radio is hidden or index of selected item
        return [m_radio isHidden] ? -1 : [m_radio selectedRow];
        
    NSPopUpButton* button = (NSPopUpButton*) ((index == 1) ? m_menu : nil);
    
    // return -1 if button is hidden or index of selected item
    return button ? ([button isHidden] ? -1 : [button indexOfSelectedItem]) : -1;
}

@end

//
//
// Custom Device Tab interface
//
//
@implementation CustomDeviceTab

- (void)performCustomInitWithContext:(JavaScriptContext*) context
{
    // Initialize the slider enable
    [m_sliderEnableButton setState: NSOnState];
    [m_slider setEnabled:YES];
    
    // Set the current menu values from the params
    [m_containerFormatMenu selectItemWithTitle:[context stringParamForKey:@"output_format_name" showError:YES]];
    [m_videoCodecMenu selectItemWithTitle:[context stringParamForKey:@"output_video_codec_name" showError:YES]];
    [m_audioCodecMenu selectItemWithTitle:[context stringParamForKey:@"output_audio_codec_name" showError:YES]];
}

- (IBAction)sliderEnableChanged:(id)sender
{
    [m_slider setEnabled:[sender state] == NSOnState];
}

- (void)setMenus: (NSArray*) menus
{
    int size = [menus count];

    for (int i = 0; i < size; ++i) {
        Menu* menu = [menus objectAtIndex:i];
        NSPopUpButton* menuButton;
        
        switch(i) {
            case 0: menuButton = m_containerFormatMenu; break;
            case 1: menuButton = m_videoCodecMenu; break;
            case 2: menuButton = m_audioCodecMenu; break;
            case 3: menuButton = m_audioQualityMenu; break;
            case 4: menuButton = m_extrasMenu; break;
            default: continue;
        }
        
        // init menu
        NSArray* itemTitles = [menu itemTitles];
        for (int i = 0; i < [itemTitles count]; ++i) {
            // If this is the extras menu, it's a pulldown, so indexing starts at 1
            [menuButton addItemWithTitle:[itemTitles objectAtIndex:i]];
        }
    }
}

- (void)setComboboxes: (NSArray*) comboboxes
{
}

- (int)menuState:(int) index
{
    switch (index) {
        case 0: return [m_containerFormatMenu indexOfSelectedItem];
        case 1: return [m_videoCodecMenu indexOfSelectedItem];
        case 2: return [m_audioCodecMenu indexOfSelectedItem];
        case 3: return [m_audioQualityMenu indexOfSelectedItem];
        case 4: return [m_extrasMenu indexOfSelectedItem];
        default: return 0;
    }
}

- (NSString*)comboboxValue:(int) index
{
    switch (index) {
        case 0: return [m_frameWidthComboBox stringValue];
        case 1: return [m_frameHeightComboBox stringValue];
        case 2: return [m_frameRateComboBox stringValue];
        case 3: return [m_extraParamsComboBox stringValue];
        default: return 0;
    }
}
@end

//
//
// QualityStop interface
//
//
@implementation QualityStop

+ (QualityStop*)qualityStopWithElement: (XMLElement*) element
{
    QualityStop* obj = [[[QualityStop alloc] init] autorelease];

    obj->m_title = [[element stringAttribute:@"title"] retain];
    return obj;
}

-(NSString*) title
{
    return m_title;
}

@end

//
//
// PerformanceItem interface
//
//
@implementation PerformanceItem

+(PerformanceItem*) performanceItemWithElement: (XMLElement*) element
{
    PerformanceItem* obj = [[[PerformanceItem alloc] init] autorelease];

    obj->m_title = [[element stringAttribute:@"title"] retain];
    
    // add params
    obj->m_params = [[NSMutableDictionary alloc] init];
    parseParams(element, obj->m_params);

    // add scripts
    obj->m_script = parseScripts(element);

    return obj;
}

-(NSString*) title
{
    return m_title;
}

-(NSDictionary*) params
{
    return m_params;
}

-(NSString*) script
{
    return m_script;
}

@end

//
//
// Button interface
//
//
@implementation MyButton

-(MyButton*) initWithElement: (XMLElement*) element
{
    m_title = [[element stringAttribute:@"title"] retain];
    m_enabled = [element boolAttribute:@"enabled" withDefault: true];

    return self;
}

-(NSString*) title
{
    return m_title;
}

-(BOOL) enabled
{
    return m_enabled;
}

@end

//
//
// Checkbox interface
//
//
@implementation Checkbox

+(Checkbox*) checkboxWithElement: (XMLElement*) element
{
    Checkbox* obj = [[[Checkbox alloc] initWithElement:element] autorelease];

    obj->m_checkedParams = [[NSMutableDictionary alloc] init];
    obj->m_uncheckedParams = [[NSMutableDictionary alloc] init];
    
    XMLElement* e = [element lastElementForName:@"checked_item"];
    parseParams(e, obj->m_checkedParams);
    obj->m_checkedScript = parseScripts(e);

    e = [element lastElementForName:@"unchecked_item"];
    parseParams(e, obj->m_uncheckedParams);
    obj->m_uncheckedScript = parseScripts(e);

    return obj;
}

-(NSDictionary*) uncheckedParams
{
    return m_uncheckedParams;
}

-(NSString*) uncheckedScript
{
    return m_uncheckedScript;
}

-(NSDictionary*) checkedParams
{
    return m_checkedParams;
}

-(NSString*) checkedScript
{
    return m_checkedScript;
}

@end

//
//
// Menu interface
//
//
@implementation Menu

+(Menu*) menuWithElement: (XMLElement*) element
{
    Menu* obj = [[[Menu alloc] initWithElement: element] autorelease];

    // parse all the items
    obj->m_itemTitles = [[NSMutableArray alloc] init];
    obj->m_itemParams = [[NSMutableArray alloc] init];
    obj->m_itemScripts = [[NSMutableArray alloc] init];

    NSArray* menuItems = [element elementsForName:@"menu_item"];
    for (int i = 0; i < [menuItems count]; ++i) {
        XMLElement* itemElement = (XMLElement*) [menuItems objectAtIndex:i];
        [obj->m_itemTitles addObject: [itemElement stringAttribute:@"title"]];
        
        NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
        [obj->m_itemParams addObject: params];
        parseParams(itemElement, params);
        [params release];
        
        [obj->m_itemScripts addObject: parseScripts(itemElement)];
    }

    return obj;
}

-(NSArray*) itemTitles
{
    return m_itemTitles;
}

-(NSArray*) itemParams
{
    return m_itemParams;
}

-(NSArray*) itemScripts
{
    return m_itemScripts;
}

@end

//
//
// Combobox interface
//
//
@implementation Combobox

+(Combobox*) comboboxWithElement: (XMLElement*) element
{
    Combobox* obj = [[[Combobox alloc] initWithElement: element] autorelease];

    obj->m_params = [[NSMutableDictionary alloc] init];
    
    parseParams(element, obj->m_params);
    obj->m_script = parseScripts(element);

    return obj;
}

-(NSDictionary*) params
{
    return m_params;
}

-(NSString*) script
{
    return m_script;
}

@end

//
//
// DeviceEntry interface
//
//
@implementation DeviceEntry

-(void) parseQualityStops: (NSArray*) array
{
    for (int i = 0; i < [array count]; ++i) {
        XMLElement* element = (XMLElement*) [array objectAtIndex:i];
        [m_qualityStops addObject:[QualityStop qualityStopWithElement: element]];
    }
    
    // The only legal number of quality stops is 0, 1, 2, 3, and 5
	// 1 is Disabled
    int count = [m_qualityStops count];
    if (count != 1 && count != 2 && count != 3 && count != 5)
        [m_qualityStops removeAllObjects];
}

-(void) parsePerformanceItems: (NSArray*) array
{
    for (int i = 0; i < [array count]; ++i) {
        XMLElement* element = (XMLElement*) [array objectAtIndex:i];
        [m_performanceItems addObject: [PerformanceItem performanceItemWithElement: element]];
    }
}

-(void) parseCheckboxes: (NSArray*) array
{
    for (int i = 0; i < [array count]; ++i) {
        XMLElement* element = (XMLElement*) [array objectAtIndex:i];
        int which = (int) [element doubleAttribute:@"which"];
        if (which < 0)
            continue;
        [m_checkboxes setValue:[Checkbox checkboxWithElement: element] forKey:[[NSNumber numberWithInt:which] stringValue]];
    }
}

-(void) parseMenus: (NSArray*) array
{
    for (int i = 0; i < [array count]; ++i) {
        XMLElement* element = (XMLElement*) [array objectAtIndex:i];
        int which = (int) [element doubleAttribute:@"which"];
        if (which < 0)
            continue;
        [m_menus setValue:[Menu menuWithElement: element] forKey:[[NSNumber numberWithInt:which] stringValue]];
    }
}

-(void) parseComboboxes: (NSArray*) array
{
    for (int i = 0; i < [array count]; ++i) {
        XMLElement* element = (XMLElement*) [array objectAtIndex:i];
        int which = (int) [element doubleAttribute:@"which"];
        if (which < 0)
            continue;
        [m_comboboxes setValue:[Menu menuWithElement: element] forKey:[[NSNumber numberWithInt:which] stringValue]];
    }
}

+(DeviceEntry*) deviceEntryWithElement: (XMLElement*) element inGroup: (NSString*) group withDefaults: (DeviceEntry*) defaults
{
    return [[[DeviceEntry alloc] initWithElement: element inGroup: group withDefaults: defaults] autorelease];
}

-(DeviceEntry*) initWithElement: (XMLElement*) element inGroup: (NSString*) group withDefaults: (DeviceEntry*) defaults;
{
    if (self = [super init]) {
        m_defaultDevice = [defaults retain];
        m_icon = [[element stringAttribute:@"icon"] retain];
        m_title = [[element stringAttribute:@"title"] retain];
        m_groupTitle = [group retain];
        m_enabled = [element boolAttribute:@"enabled" withDefault: true];
        
        m_qualityStops = [[NSMutableArray alloc] init];
        m_performanceItems = [[NSMutableArray alloc] init];
        m_recipes = [[NSMutableArray alloc] init];
        m_params = [[NSMutableDictionary alloc] init];
        m_checkboxes = [[NSMutableDictionary alloc] init];
        m_menus = [[NSMutableDictionary alloc] init];
        m_comboboxes = [[NSMutableDictionary alloc] init];
        
        // handle quality
        [self parseQualityStops:[[element lastElementForName:@"quality"] elementsForName: @"quality_stop"]];
        
        // handle performance
        [self parsePerformanceItems:[[element lastElementForName:@"performance"] elementsForName: @"performance_item"]];
        
        // handle params
        parseParams(element, m_params);
        
        // handle scripts
        m_script = parseScripts(element);
        
        // handle checkboxes
        [self parseCheckboxes:[element elementsForName:@"checkbox"]];
        
        // handle menus
        [self parseMenus:[element elementsForName:@"menu"]];
        
        // handle comboboxes
        [self parseComboboxes:[element elementsForName:@"combobox"]];
        
        // Set the device tab enum
        if ([m_icon isEqualToString:@"custom"])
            m_deviceTabName = DT_CUSTOM;
        else if ([m_menus count] == 0)
            m_deviceTabName = DT_NO_MENUS;
        else
            m_deviceTabName = DT_RADIO_MENU;
    }
    return self;
}

- (void)dealloc
{
    [m_defaultDevice release];
    [m_icon release];
    [m_title  release];
    [m_groupTitle  release];
    [m_qualityStops  release];
    [m_performanceItems  release];
    [m_recipes  release];
    [m_params  release];
    [m_checkboxes  release];
    [m_menus  release];
    [m_comboboxes  release];
    [super dealloc];
}

-(NSString*) group
{
    return m_groupTitle;
}

-(NSString*) title
{
    return m_title;
}

-(NSString*) icon
{
    return m_icon;
}

-(BOOL) enabled
{
    return m_enabled;
}

-(NSArray*) qualityStops
{
    return [m_qualityStops count] ? m_qualityStops : [m_defaultDevice qualityStops];
}

-(NSArray*) performanceItems
{
    return [m_performanceItems count] ? m_performanceItems : [m_defaultDevice performanceItems];
}

-(NSArray*) recipes
{
    return [m_recipes count] ? m_recipes : [m_defaultDevice recipes];
}

-(int) qualityStop
{
    int count = [[self qualityStops] count];
    double sliderValue = [m_deviceTab sliderValue];
    
    if (sliderValue > 1)
        sliderValue = 1;
    else if (sliderValue < 0)
        sliderValue = 0;
    
    return (sliderValue == 1) ? (count-1) : ((int) (sliderValue * (count-1)));
}

-(void) quality: (double*) q withStop: (int*) stop
{
    int count = [[self qualityStops] count];
    double sliderValue = [m_deviceTab sliderValue];
    
    if (sliderValue > 1)
        sliderValue = 1;
    else if (sliderValue < 0)
        sliderValue = 0;
    
    if (sliderValue == 1) {
        *stop = count-1;
        *q = 1;
    }
    else {
        sliderValue *= count;
        *stop = (int) sliderValue;    
        *q = fmod(sliderValue, 1);
    }
}

-(void) setCurrentParamsInJavaScriptContext:(JavaScriptContext*) context performanceIndex:(int) perfIndex
{
    // Add params and commands from this device
    [self addParamsToJavaScriptContext: context performanceIndex:perfIndex];
    
    // set the quality
    int qualityStop;
    double quality;
    [self quality: &quality withStop: &qualityStop];
    [context setStringParam:[[NSNumber numberWithDouble: quality] stringValue] forKey:@"quality"];
    [context setStringParam:[[NSNumber numberWithInt: qualityStop] stringValue] forKey:@"quality_stop"];
    
    // set the current device title
    [context setStringParam:m_title forKey:@"title"];

    // Execute script from this device
    [self evaluateScript: context performanceIndex:perfIndex];
    
    // Set the device UI according to the current params
    [m_deviceTab performCustomInitWithContext:context];
}

-(void) populateTabView:(NSTabView*) tabview
{
    [tabview selectTabViewItemWithIdentifier:m_deviceTabName];
    m_deviceTab = (DeviceTab*) [tabview selectedTabViewItem];
    
    [m_deviceTab setCheckboxes: m_checkboxes];
    [m_deviceTab setMenus: m_menus];
    [m_deviceTab setComboboxes: m_comboboxes];
    [m_deviceTab setQuality: [self qualityStops]];
}

-(void) populatePerformanceButton: (NSPopUpButton*) button
{
    [button removeAllItems];
    NSArray* performanceItems = [self performanceItems];
    
    for (int i = 0; i < [performanceItems count]; ++i) {
        PerformanceItem* item = (PerformanceItem*) [performanceItems objectAtIndex:i];
        if (!item)
            continue;

        NSMenuItem* menuItem = [[NSMenuItem alloc] init];
        [menuItem setTag:i];
        [menuItem setTitle:[item title]];
        [[button menu] addItem:menuItem];
        [menuItem release];
    }

    // FIXME: Ultimately performance should be saved in user defaults on a per-device basis. For now we'll
    // just set it to 'normal'
    [button selectItemAtIndex:2];
}

-(void) addParamsToJavaScriptContext: (JavaScriptContext*) context performanceIndex:(int) perfIndex
{
    // Add params and commands from default device (recursive)
    if (m_defaultDevice)
        [m_defaultDevice addParamsToJavaScriptContext: context performanceIndex:perfIndex];
    
    // Add global params and commands
    [context addParams: m_params];

    // Add params and commands from currently selected performance item
    if (perfIndex >= 0 && [m_performanceItems count] > perfIndex)
        [context addParams: [(PerformanceItem*) [m_performanceItems objectAtIndex:perfIndex] params]];

    // Add params and commands from currently selected checkboxes
    for (NSString* which in m_checkboxes) {
        int i = [which intValue];
        Checkbox* checkbox = [m_checkboxes valueForKey:which];
        
        int state = [m_deviceTab checkboxState:i];
        if (state == 0)
            [context addParams: [checkbox uncheckedParams]];
        else if (state == 1)
            [context addParams: [checkbox checkedParams]];
    }
    
    // Add params and commands from currently selected menu items
    for (NSString* which in m_menus) {
        int i = [which intValue];
        Menu* menu = [m_menus valueForKey:which];
        
        int state = [m_deviceTab menuState:i];
        if (state >= 0)
            [context addParams: (NSDictionary*) [[menu itemParams] objectAtIndex:state]];
    }
}

-(void) evaluateScript: (JavaScriptContext*) context performanceIndex:(int) perfIndex
{
    // Execute script in the following order:
    // 1) <default_device>
    // 2) selected <performance_item> from <default_device>
    // 3) <common_device> for selected <device>
    // 4) selected <performance_item> from <common_device> for selected <device>
    // 5) selected <device>
    // 6) selected <performance_item> from selected <device>
    // 7) <checked_item> or <unchecked_item> entry from each <checkbox> in selected <device>
    // 8) selected <menu_item> entry from each <menu> in selected <device>
	
    // Execute script from default device (recursive)
    if (m_defaultDevice)
        [m_defaultDevice evaluateScript: context performanceIndex:perfIndex];
    
    // Evaluate global script
    [context evaluateJavaScript:m_script];

    // Evaluate scripts from currently selected performance item
    if (perfIndex >= 0 && [m_performanceItems count] > perfIndex)
        [context evaluateJavaScript: [(PerformanceItem*) [m_performanceItems objectAtIndex:perfIndex] script]];

    // Evaluate scripts from currently selected checkboxes
    for (NSString* which in m_checkboxes) {
        int i = [which intValue];
        Checkbox* checkbox = [m_checkboxes valueForKey:which];
        
        int state = [m_deviceTab checkboxState:i];
        if (state == 0)
            [context evaluateJavaScript: [checkbox uncheckedScript]];
        else if (state == 1)
            [context evaluateJavaScript: [checkbox checkedScript]];
        i++;
    }
    
    // Evaluate scripts from currently selected menu items
    for (NSString* which in m_menus) {
        int i = [which intValue];
        Menu* menu = [m_menus valueForKey:which];
        
        int state = [m_deviceTab menuState:i];
        if (state >= 0)
            [context evaluateJavaScript: (NSString*)[[menu itemScripts] objectAtIndex:state]];
        i++;
    }
}

@end
