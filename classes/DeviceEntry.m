//
//  DeviceController.m
//  DeviceController
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright Chris Marrin 2008. All rights reserved.
//

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
// Device Tab interface
//
//
@implementation DeviceTab

-(NSString*) deviceName
{
    return [self identifier];
}

static void setButton(NSButton* button, NSString* title)
{
    if (title) {
        [button setHidden:NO];
        [button setTitle:title];
        [button sizeToFit];
    }
    else
        [button setHidden:YES];
}

-(void) setCheckboxes: (NSArray*) checkboxes
{
    int size = [checkboxes count];
    setButton(m_button0, (size > 0) ? [(Checkbox*) [checkboxes objectAtIndex:0] title] : nil);
    setButton(m_button1, (size > 1) ? [(Checkbox*) [checkboxes objectAtIndex:1] title] : nil);
}

-(void) setMenus: (NSArray*) menus
{
    int size = [menus count];
    
    if (m_radio) {
        if (size > 0) {
            Menu* menu = (Menu*) [menus objectAtIndex:0];
            
            [m_radioLabel0 setHidden:NO];
            [m_radioLabel0 setStringValue:  [menu title]];
            [m_radio setHidden:NO];
            
            NSArray* itemTitles = [menu itemTitles];
            [m_radio renewRows:[itemTitles count] columns:1];
            for (int i = 0; i < [itemTitles count]; ++i) {
                NSButtonCell* cell = (NSButtonCell*) [m_radio cellAtRow:i column:0];
                [cell setTitle:[itemTitles objectAtIndex:i]];
            }
        }
        else {
            [m_radioLabel0 setHidden:YES];
            [m_radio setHidden:YES];
        }
    }
    else {
        // handle menus
        setButton(m_button2, (size > 0) ? [(Menu*) [menus objectAtIndex:0] title] : nil);
        setButton(m_button3, (size > 1) ? [(Menu*) [menus objectAtIndex:1] title] : nil);
        
        // FIXME: add items
    }
}

-(void) setQuality: (NSArray*) qualityStops
{
    // We can draw a slider with 2, 3, or 5 tick marks. 
    // If we see any other number in the array we will turn off the quality slider
    [m_slider setHidden:NO];
    [m_sliderLabel1 setHidden:NO];
    [m_sliderLabel2 setHidden:NO];
    [m_sliderLabel3 setHidden:NO];
    [m_sliderLabel4 setHidden:NO];
    [m_sliderLabel5 setHidden:NO];
    
    if ([qualityStops count] == 2) {
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
    NSButton* button = (index == 0) ? m_button0 : ((index == 1) ? m_button1 : nil);
    
    // return 1 if button is one, 0 if it is off, or -1 if it is hidden
    return button ? ([button isHidden] ? -1 : (([button state] == NSOnState) ? 1 : 0)) : -1;
}

-(int) menuState:(int) index
{
    if (index == 0 && m_radio)
        // return -1 if radio is hidden or index of selected item
        return [m_radio isHidden] ? -1 : [m_radio selectedRow];
        
    NSPopUpButton* button = (NSPopUpButton*) ((index == 0) ? m_button2 : ((index == 1) ? m_button3 : nil));
    
    // return -1 if button is hidden or index of selected item
    return button ? ([button isHidden] ? -1 : [button indexOfSelectedItem]) : -1;
}

-(int) qualityState
{
    if (!m_slider)
        return -1;
    
    double ticks = [m_slider numberOfTickMarks] - 1;
    double value = [m_slider doubleValue];
    if (value < 0)
        value = 0;
    else if (value > 1)
        value = 1;
        
    return (int) (value * ticks + 0.5);
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
// QualityStop interface
//
//
@implementation QualityStop

+(QualityStop*) qualityStopWithElement: (XMLElement*) element
{
    QualityStop* obj = [[QualityStop alloc] init];

    obj->m_title = [NSString stringWithString:[element stringAttribute:@"title"]];
    obj->m_bitrate = [element doubleAttribute:@"bitrate"];

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

-(double) bitrate
{
    return m_bitrate;
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
    PerformanceItem* obj = [[PerformanceItem alloc] init];

    obj->m_title = [NSString stringWithString:[element stringAttribute:@"title"]];
    
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
// Checkbox interface
//
//
@implementation Checkbox

+(Checkbox*) checkboxWithElement: (XMLElement*) element
{
    Checkbox* obj = [[Checkbox alloc] init];

    obj->m_title = [NSString stringWithString:[element stringAttribute:@"title"]];
    obj->m_checkedParams = [[NSMutableDictionary alloc] init];
    obj->m_uncheckedParams = [[NSMutableDictionary alloc] init];
    
    XMLElement* e = [element lastElementForName:@"checked_params"];
    parseParams(e, obj->m_checkedParams);
    obj->m_checkedScript = parseScripts(e);

    e = [element lastElementForName:@"unchecked_params"];
    parseParams(e, obj->m_uncheckedParams);
    obj->m_uncheckedScript = parseScripts(e);

    return obj;
}

-(NSString*) title
{
    return m_title;
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
    Menu* obj = [[Menu alloc] init];

    obj->m_title = [NSString stringWithString:[element stringAttribute:@"title"]];
    
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

-(NSString*) title
{
    return m_title;
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
    
    // The only legal number of quality stops is 0, 2, 3, and 5
    int count = [m_qualityStops count];
    if (count != 2 && count != 3 && count != 5)
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
        if (which < 0 || which > MAX_CHECKBOXES)
            continue;
        [m_checkboxes insertObject:[Checkbox checkboxWithElement: element] atIndex:which];
    }
}

-(void) parseMenus: (NSArray*) array
{
    for (int i = 0; i < [array count]; ++i) {
        XMLElement* element = (XMLElement*) [array objectAtIndex:i];
        int which = (int) [element doubleAttribute:@"which"];
        if (which < 0 || which > MAX_MENUS)
            continue;
        [m_menus insertObject:[Menu menuWithElement: element] atIndex:which];
    }
}

+(DeviceEntry*) deviceEntryWithElement: (XMLElement*) element inGroup: (NSString*) group withDefaults: (DeviceEntry*) defaults
{
    return [[DeviceEntry alloc] initWithElement: element inGroup: group withDefaults: defaults];
}

-(DeviceEntry*) initWithElement: (XMLElement*) element inGroup: (NSString*) group withDefaults: (DeviceEntry*) defaults;
{
    m_defaultDevice = [defaults retain];
    m_icon = [NSString stringWithString:[element stringAttribute:@"icon"]];
    m_title = [NSString stringWithString:[element stringAttribute:@"title"]];
    m_groupTitle = [NSString stringWithString:group ? group : @""];
    m_enabled = [element boolAttribute:@"enabled" withDefault: true];
    
    m_qualityStops = [[NSMutableArray alloc] init];
    m_performanceItems = [[NSMutableArray alloc] init];
    m_recipes = [[NSMutableArray alloc] init];
    m_params = [[NSMutableDictionary alloc] init];
    m_checkboxes = [[NSMutableArray alloc] init];
    m_menus = [[NSMutableArray alloc] init];
    
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
    
    // Set the device tab enum
    if ([m_menus count] == 0)
        m_deviceTabName = DT_NO_MENUS;
    else if ([m_menus count] == 1 && [[(Menu*) [m_menus objectAtIndex:0] itemTitles] count] <= 3)
        m_deviceTabName = DT_RADIO_2_CHECK;
    else
        m_deviceTabName = DT_2_MENU_2_CHECK;
    
    return self;
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

-(NSString*) paramWithDefault:(NSString*) key
{
    NSString* v = [m_params objectForKey:key];
    return (v && [v length]) ? v : [m_defaultDevice paramWithDefault: key];
}

-(NSString*) fileSuffix
{
    return [self paramWithDefault: @"video_suffix"];
}

-(NSString*) videoFormat
{
    return [self paramWithDefault: @"ffmpeg_vcodec"];
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
        *stop = count-2;
        *q = 1;
    }
    else {
        sliderValue *= count - 1;
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
}

-(void) populateTabView:(NSTabView*) tabview
{
    [tabview selectTabViewItemWithIdentifier:m_deviceTabName];
    m_deviceTab = (DeviceTab*) [tabview selectedTabViewItem];
    
    [m_deviceTab setCheckboxes: m_checkboxes];
    [m_deviceTab setMenus: m_menus];
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
    }
}

-(void) addParamsToJavaScriptContext: (JavaScriptContext*) context performanceIndex:(int) perfIndex
{
    // Add params and commands from default device (recursive)
    if (m_defaultDevice)
        [m_defaultDevice addParamsToJavaScriptContext: context performanceIndex:perfIndex];
    
    // Add global params and commands
    [context addParams: m_params];

    // Add params and commands from currently selected quality stop
    int state = [m_deviceTab qualityState];
    if (state >= 0 && [[self qualityStops] count] > state)
        [context addParams: [(QualityStop*) [[self qualityStops] objectAtIndex:state] params]];
    
    // Add params and commands from currently selected performance item
    if (perfIndex >= 0 && [m_performanceItems count] > perfIndex)
        [context addParams: [(PerformanceItem*) [m_performanceItems objectAtIndex:perfIndex] params]];

    // Add params and commands from currently selected checkboxes
    int i = 0;
    for (Checkbox* checkbox in m_checkboxes) {
        int state = [m_deviceTab checkboxState:i];
        if (state == 0)
            [context addParams: [checkbox uncheckedParams]];
        else if (state == 1)
            [context addParams: [checkbox checkedParams]];
        i++;
    }
    
    // Add params and commands from currently selected menu items
    i = 0;
    for (Menu* menu in m_menus) {
        int state = [m_deviceTab menuState:i];
        if (state >= 0)
            [context addParams: (NSDictionary*) [[menu itemParams] objectAtIndex:state]];
        i++;
    }    
}

-(void) evaluateScript: (JavaScriptContext*) context performanceIndex:(int) perfIndex
{
    // Execute script from default device (recursive)
    if (m_defaultDevice)
        [m_defaultDevice evaluateScript: context performanceIndex:perfIndex];
    
    // Evaluate global script
    [context evaluateJavaScript:m_script];

    // Evaluate scripts from currently selected checkboxes
    int i = 0;
    for (Checkbox* checkbox in m_checkboxes) {
        int state = [m_deviceTab checkboxState:i];
        if (state == 0)
            [context evaluateJavaScript: [checkbox uncheckedScript]];
        else if (state == 1)
            [context evaluateJavaScript: [checkbox checkedScript]];
        i++;
    }
    
    // Evaluate scripts from currently selected menu items
    i = 0;
    for (Menu* menu in m_menus) {
        int state = [m_deviceTab menuState:i];
        if (state >= 0)
            [context evaluateJavaScript: (NSString*)[[menu itemScripts] objectAtIndex:state]];
        i++;
    }
    
    // Evaluate scripts from currently selected quality stop
    int state = [m_deviceTab qualityState];
    if (state >= 0 && [[self qualityStops] count] > state)
        [context evaluateJavaScript: [(QualityStop*) [[self qualityStops] objectAtIndex:state] script]];
    
    // Evaluate scripts from currently selected performance item
    if (perfIndex >= 0 && [m_performanceItems count] > perfIndex)
        [context evaluateJavaScript: [(PerformanceItem*) [m_performanceItems objectAtIndex:perfIndex] script]];
}

@end
