//
//  ConversionParams.m
//  ConversionParams
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright Chris Marrin 2008. All rights reserved.
//

#import "ConversionParams.h"

static NSString* stringAttribute(NSXMLElement* element, NSString* name)
{
    NSXMLNode* node = [element attributeForName:name];
    return node ? [node stringValue] : @"";
}

static double doubleAttribute(NSXMLElement* element, NSString* name)
{
    return [stringAttribute(element, name) doubleValue];
}

static BOOL boolAttribute(NSXMLElement* element, NSString* name)
{
    return [stringAttribute(element, name) boolValue];
}

static NSString* content(NSXMLElement* element)
{
    // It seems that the content is always the first child and that leading and trailing whitespace is removed.
    // Let's assume that for now
    return [element childCount] ? [[element childAtIndex:0] stringValue] : @"";
}

static NSXMLElement* findChildElement(NSXMLElement* element, NSString* name)
{
    // return the LAST element with the passed name (later versions override earlier ones)
    return [[element elementsForName:name] lastObject];
}

static void addParam(NSXMLElement* paramElement, NSMutableDictionary* dictionary)
{
    NSString* key = stringAttribute(paramElement, @"id");
    NSString* value = stringAttribute(paramElement, @"value");
    if ([key length])
        [dictionary setValue:value forKey:key];
}

static void parseParams(NSXMLElement* element, NSMutableDictionary* dictionary)
{
    NSArray* array = [element elementsForName: @"param"];
    for (int i = 0; i < [array count]; ++i)
        addParam((NSXMLElement*) [array objectAtIndex:i], dictionary);

}

static NSString* parseScripts(NSXMLElement* element)
{
    NSMutableString* script = [[NSMutableString alloc] init];
    NSArray* array = [element elementsForName: @"script"];
    for (int i = 0; i < [array count]; ++i) {
        [script appendString:content((NSXMLElement*) [array objectAtIndex:i])];
        [script appendString:@"\n\n"];
    }
    
    return script;
}

static NSArray* parseCommands(NSXMLElement* parent)
{
    // extract the commands
    NSMutableArray* commands = [[NSMutableDictionary alloc] init];
    NSXMLElement* commandsElement = findChildElement(parent, @"commands");
    NSArray* commandArray = [commandsElement elementsForName:@"command"];
    
    for (int i = 0; i < [commandArray count]; ++i) {
        NSXMLElement* element = (NSXMLElement*) [commandArray objectAtIndex:i];
        NSString* id = stringAttribute(element, @"id");
        if ([id length])
            [commands setValue: content(element) forKey: id];
    }
    
    return commands;
}

@implementation ConversionTab

-(NSString*) deviceName
{
    return [self identifier];
}

static void setButton(NSButton* button, NSString* title)
{
    if (title) {
        [button setHidden:NO];
        [button setTitle:title];
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
            [m_radioLabel0 setHidden:NO];
            [m_radioLabel0 setStringValue:  [(Menu*) [menus objectAtIndex:0] title]];
            [m_radio setHidden:NO];
            
            // FIXME: add radio buttons
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

@end

@implementation QualityStop

+(QualityStop*) qualityStopWithElement: (NSXMLElement*) element
{
    QualityStop* obj = [[QualityStop alloc] init];

    obj->m_title = [NSString stringWithString:stringAttribute(element, @"title")];
    obj->m_bitrate = doubleAttribute(element, @"bitrate");

    // add params
    obj->m_params = [[NSMutableDictionary alloc] init];
    parseParams(element, obj->m_params);

    // add scripts
    obj->m_script = parseScripts(element);

    return obj;
}

@end

@implementation PerformanceItem

+(PerformanceItem*) performanceItemWithElement: (NSXMLElement*) element
{
    PerformanceItem* obj = [[PerformanceItem alloc] init];

    obj->m_title = [NSString stringWithString:stringAttribute(element, @"title")];
    
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

@end

@implementation Recipe

+(Recipe*) recipeWithElement: (NSXMLElement*) element
{
    Recipe* obj = [[Recipe alloc] init];

    obj->m_recipe = [NSString stringWithString:content(element)];
    
    obj->m_isQuicktime = boolAttribute(element, @"is_quicktime");
    obj->m_hasAudio = boolAttribute(element, @"has_audio");
    obj->m_is2Pass = boolAttribute(element, @"is_2pass");

    return obj;
}

@end

@implementation Checkbox

+(Checkbox*) checkboxWithElement: (NSXMLElement*) element
{
    Checkbox* obj = [[Checkbox alloc] init];

    obj->m_title = [NSString stringWithString:stringAttribute(element, @"title")];
    obj->m_checkedParams = [[NSMutableDictionary alloc] init];
    obj->m_uncheckedParams = [[NSMutableDictionary alloc] init];
    
    parseParams(findChildElement(element, @"checked_params"), obj->m_checkedParams);
    parseParams(findChildElement(element, @"unchecked_params"), obj->m_uncheckedParams);

    return obj;
}

-(NSString*) title
{
    return m_title;
}

@end

@implementation Menu

+(Menu*) menuWithElement: (NSXMLElement*) element
{
    Menu* obj = [[Menu alloc] init];

    obj->m_title = [NSString stringWithString:stringAttribute(element, @"title")];
    
    // parse all the items
    obj->m_itemTitles = [[NSMutableArray alloc] init];
    obj->m_itemParams = [[NSMutableArray alloc] init];

    NSArray* menuItems = [element elementsForName:@"menu_item"];
    for (int i = 0; i < [menuItems count]; ++i) {
        NSXMLElement* itemElement = (NSXMLElement*) [menuItems objectAtIndex:i];
        [obj->m_itemTitles addObject: stringAttribute(itemElement, @"title")];
        
        NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
        [obj->m_itemParams addObject: params];
        parseParams(itemElement, params);
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

-(NSString*) title
{
    return m_title;
}

@end

@implementation DeviceEntry

-(void) parseQualityStops: (NSArray*) array
{
    for (int i = 0; i < [array count]; ++i) {
        NSXMLElement* element = (NSXMLElement*) [array objectAtIndex:i];
        int which = (int) doubleAttribute(element, @"which");
        if (which < 0 || which > 5)
            continue;
        [m_qualityStops insertObject:[QualityStop qualityStopWithElement: element] atIndex:which];
    }
}

-(void) parsePerformanceItems: (NSArray*) array
{
    for (int i = 0; i < [array count]; ++i) {
        NSXMLElement* element = (NSXMLElement*) [array objectAtIndex:i];
        [m_performanceItems addObject: [PerformanceItem performanceItemWithElement: element]];
    }
}

-(void) parseRecipes: (NSArray*) array
{
    for (int i = 0; i < [array count]; ++i) {
        NSXMLElement* element = (NSXMLElement*) [array objectAtIndex:i];

        [m_recipes addObject:[Recipe recipeWithElement: element]];
    }
}

-(void) parseCheckboxes: (NSArray*) array
{
    for (int i = 0; i < [array count]; ++i) {
        NSXMLElement* element = (NSXMLElement*) [array objectAtIndex:i];
        int which = (int) doubleAttribute(element, @"which");
        if (which < 0 || which > MAX_CHECKBOXES)
            continue;
        [m_checkboxes insertObject:[Checkbox checkboxWithElement: element] atIndex:which];
    }
}

-(void) parseMenus: (NSArray*) array
{
    for (int i = 0; i < [array count]; ++i) {
        NSXMLElement* element = (NSXMLElement*) [array objectAtIndex:i];
        int which = (int) doubleAttribute(element, @"which");
        if (which < 0 || which > MAX_MENUS)
            continue;
        [m_menus insertObject:[Menu menuWithElement: element] atIndex:which];
    }
}

+(DeviceEntry*) deviceEntryWithElement: (NSXMLElement*) element inGroup: (NSString*) group withDefaults: (DeviceEntry*) defaults
{
    return [[DeviceEntry alloc] initWithElement: element inGroup: group withDefaults: defaults];
}

-(DeviceEntry*) initWithElement: (NSXMLElement*) element inGroup: (NSString*) group withDefaults: (DeviceEntry*) defaults;
{
    m_defaultDevice = defaults;
    m_id = [NSString stringWithString:stringAttribute(element, @"id")];
    m_title = [NSString stringWithString:stringAttribute(element, @"title")];
    m_groupTitle = [NSString stringWithString:group ? group : @""];
    
    m_qualityStops = [NSMutableArray arrayWithCapacity:6];
    m_performanceItems = [[NSMutableArray alloc] init];
    m_recipes = [[NSMutableArray alloc] init];
    m_params = [[NSMutableDictionary alloc] init];
    m_checkboxes = [[NSMutableArray alloc] init];
    m_menus = [[NSMutableArray alloc] init];
    
    // handle quality
    [self parseQualityStops:[findChildElement(element, @"quality") elementsForName: @"quality_stop"]];
    
    // handle performance
    [self parsePerformanceItems:[findChildElement(element, @"performance") elementsForName: @"performance_item"]];
    
    // handle recipes
    [self parseRecipes:[findChildElement(element, @"recipes") elementsForName: @"recipe"]];
    
    // handle params
    parseParams(element, m_params);
    
    // handle checkboxes
    [self parseCheckboxes:[element elementsForName:@"checkbox"]];
    
    // handle menus
    [self parseMenus:[element elementsForName:@"menu"]];
    
    // Set the device tab enum
    if ([m_menus count] == 0)
        m_deviceTab = DT_NO_MENUS;
    else if ([m_menus count] == 1 && [[(Menu*) [m_menus objectAtIndex:0] itemTitles] count] <= 3)
        m_deviceTab = DT_RADIO_2_CHECK;
    else
        m_deviceTab = DT_2_MENU_2_CHECK;
    
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

-(NSString*) id
{
    return m_id;
}

-(NSArray*) performanceItems
{
    return [m_performanceItems count] ? m_performanceItems : [m_defaultDevice performanceItems];
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

-(NSString*) recipe
{
    // FIXME: need to return the real recipe
    return @"abc;def|ghi&jkl";
}

-(void) setCurrentDevice:(NSTabView*) tabview
{
    [tabview selectTabViewItemWithIdentifier:m_deviceTab];
    ConversionTab* tab = (ConversionTab*) [tabview selectedTabViewItem];
    
    [tab setCheckboxes: m_checkboxes];
    [tab setMenus: m_menus];
}

@end

@implementation ConversionParams

-(void) setPerformance: (int) index
{
    switch(index)
    {
        case 0: m_currentPerformance = @"fastest"; m_isTwoPass = NO;    break;
        case 1: m_currentPerformance = @"default"; m_isTwoPass = NO;    break;
        case 2: m_currentPerformance = @"normal"; m_isTwoPass = NO;     break;
        case 3: m_currentPerformance = @"normal"; m_isTwoPass = YES;    break;
        case 4: m_currentPerformance = @"hq"; m_isTwoPass = NO;         break;
        case 5: m_currentPerformance = @"hq"; m_isTwoPass = YES;        break;
    }
}

-(void) initCommands
{
    NSURL* url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"commands" ofType:@"xml"]];
    NSError* error;
    NSXMLDocument* doc = [[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentValidate error:&error];
    NSString* desc = [error localizedDescription];
    
    if ([desc length] != 0) {
        NSRunAlertPanel(@"Error parsing commands.xml", desc, nil, nil, nil);
        return;
    }
    
    if (!doc || ![[[doc rootElement] name] isEqualToString:@"videomonkey"]) {
        NSRunAlertPanel(@"Error in commands.xml", @"root element is not <videomonkey>", nil, nil, nil);
        return;
    }
        
    // extract the defaults
    m_defaultDevice = [DeviceEntry deviceEntryWithElement: findChildElement([doc rootElement], @"default_device") inGroup: nil withDefaults: nil];
        
    // Build the device list
    m_devices = [[NSMutableArray alloc] init];
    
    NSXMLElement* devicesElement = findChildElement([doc rootElement], @"devices");
    NSArray* deviceGroups = [devicesElement elementsForName:@"device_group"];
    
    for (int i = 0; i < [deviceGroups count]; ++i) {
        NSXMLElement* deviceGroupElement = (NSXMLElement*) [deviceGroups objectAtIndex:i];
        NSString* groupTitle = stringAttribute(deviceGroupElement, @"title");
        NSArray* devices = [deviceGroupElement elementsForName:@"device"];
        
        for (int j = 0; j < [devices count]; ++j) {
            NSXMLElement* deviceElement = (NSXMLElement*) [devices objectAtIndex:j];
            DeviceEntry* entry = [DeviceEntry deviceEntryWithElement: deviceElement inGroup: groupTitle withDefaults: m_defaultDevice];
            if (entry)
                [m_devices addObject: entry];
        }
    }
    
    // build the environment
    m_environment = [[NSMutableDictionary alloc] init];

    // fill in the environment
    NSString* cmdPath = [NSString stringWithString: [[NSBundle mainBundle] resourcePath]];
    [m_environment setValue: [cmdPath stringByAppendingPathComponent: @"bin/ffmpeg"] forKey: @"ffmpeg"];
    [m_environment setValue: [cmdPath stringByAppendingPathComponent: @"bin/qt_export"] forKey: @"qt_export"];
    [m_environment setValue: [cmdPath stringByAppendingPathComponent: @"bin/movtoy4m"] forKey: @"movtoy4m"];
    [m_environment setValue: [cmdPath stringByAppendingPathComponent: @"bin/yuvadjust"] forKey: @"yuvadjust"];
    [m_environment setValue: [cmdPath stringByAppendingPathComponent: @"bin/yuvcorrect"] forKey: @"yuvcorrect"];
}

static void addMenuItem(NSPopUpButton* button, NSString* title, int tag)
{
    NSMenuItem* item = [[NSMenuItem alloc] init];
    [item setTitle:title];
    [item setTag:tag];
    if (tag < 0)
        [item setEnabled:NO];
    else
        [item setIndentationLevel:1];
        
    [[button menu] addItem:item];
}

-(DeviceEntry*) findDeviceEntryWithIndex: (int) index
{
    int currentItem = 0;
    
    for (int i = 0; i < [m_devices count]; ++i) {
        DeviceEntry* entry = (DeviceEntry*) [m_devices objectAtIndex:i];
        if (!entry)
            continue;
        if (currentItem++ == index)
            return entry;
    }
    return nil;
}

- (void) awakeFromNib
{
    // load the XML file with all the commands and device setup
    [self initCommands];
    
    // populate the device menu
    [m_deviceButton removeAllItems];
    
    // This assumes all items for a group are consecutive
    NSString* currentGroup = @"";
    int currentItem = 0;
    
    for (int i = 0; i < [m_devices count]; ++i) {
        DeviceEntry* entry = (DeviceEntry*) [m_devices objectAtIndex:i];
        if (!entry)
            continue;
            
        NSString* group = [entry group];
        if (![group isEqualToString:currentGroup]) {
            currentGroup = group;
            addMenuItem(m_deviceButton, currentGroup, -1);
        }
        
        addMenuItem(m_deviceButton, [entry title], currentItem++);
    }
    
    // set the selected item
    // FIXME: need to get this from prefs
    [m_deviceButton selectItemWithTag:0];
    
    m_currentDevice = [self findDeviceEntryWithIndex:0];
    [m_currentDevice setCurrentDevice: m_conversionParamsTabView];

    // populate the performance menu
    [m_performanceButton removeAllItems];
    NSArray* performanceItems = [m_currentDevice performanceItems];
    
    for (int i = 0; i < [performanceItems count]; ++i) {
        PerformanceItem* item = (PerformanceItem*) [performanceItems objectAtIndex:i];
        if (!item)
            continue;
        
        addMenuItem(m_performanceButton, [item title], i);
    }
    
    // set the selected item
    // FIXME: need to get this from prefs
    [m_performanceButton selectItemWithTag:2];
    [self setPerformance: [m_performanceButton indexOfSelectedItem]];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    return [menuItem isEnabled];
}

- (IBAction)selectDevice:(id)sender {
    int tag = [[sender selectedItem] tag];
    m_currentDevice = [self findDeviceEntryWithIndex:tag];
    [m_currentDevice setCurrentDevice: m_conversionParamsTabView];
}

- (IBAction)selectPerformance:(id)sender {
    [self setPerformance: [sender indexOfSelectedItem]];
}

-(BOOL) isTwoPass
{
    return m_isTwoPass;
}

-(NSString*) performance
{
    return m_currentPerformance;
}

-(NSString*) fileSuffix
{
    return [m_currentDevice fileSuffix];
}

-(NSString*) videoFormat
{
    return [m_currentDevice videoFormat];
}

-(NSString*) recipe
{
    return [m_currentDevice recipe];
}

@end
