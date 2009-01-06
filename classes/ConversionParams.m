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
    NSArray* array = [element elementsForName:name];
    if (!array || [array count] == 0)
        return nil;
        
    return [array objectAtIndex:0];
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

@implementation ConversionTab

-(NSString*) deviceName
{
    return [self identifier];
}

@end

@implementation QualityStop

+(QualityStop*) qualityStopWithElement: (NSXMLElement*) element withDefaults: (DeviceEntry*) defaults
{
    QualityStop* obj = [[QualityStop alloc] init];

    obj->m_title = [NSString stringWithString:stringAttribute(element, @"title")];
    obj->m_bitrate = doubleAttribute(element, @"bitrate");
    obj->m_sizeRatio = doubleAttribute(element, @"size");
    
    NSString* audio = stringAttribute(element, @"audio");
    if ([audio isEqualToString:@"low"]) {
        obj->m_audioBitrate = 16000;
        obj->m_audioSampleRate = 11025;
        obj->m_audioChannels = 1;
    }
    else if ([audio isEqualToString:@"medium"]) {
        obj->m_audioBitrate = 32000;
        obj->m_audioSampleRate = 22050;
        obj->m_audioChannels = 1;
    }
    else {
        obj->m_audioBitrate = 128000;
        obj->m_audioSampleRate = 48000;
        obj->m_audioChannels = 2;
    }
    
    return obj;
}

@end

@implementation PerformanceItem

+(PerformanceItem*) performanceItemWithElement: (NSXMLElement*) element withDefaults: (DeviceEntry*) defaults
{
    PerformanceItem* obj = [[PerformanceItem alloc] init];

    obj->m_title = [NSString stringWithString:stringAttribute(element, @"title")];
    
    // add params
    obj->m_params = [[NSMutableDictionary alloc] init];
    parseParams(element, obj->m_params);

    return obj;
}

@end

@implementation Recipe

+(Recipe*) recipeWithElement: (NSXMLElement*) element withDefaults: (DeviceEntry*) defaults
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

+(Checkbox*) checkboxWithElement: (NSXMLElement*) element withDefaults: (DeviceEntry*) defaults
{
    Checkbox* obj = [[Checkbox alloc] init];

    obj->m_title = [NSString stringWithString:stringAttribute(element, @"title")];
    obj->m_checkedParams = [[NSMutableDictionary alloc] init];
    obj->m_uncheckedParams = [[NSMutableDictionary alloc] init];
    
    parseParams(findChildElement(element, @"checked_params"), obj->m_checkedParams);
    parseParams(findChildElement(element, @"unchecked_params"), obj->m_uncheckedParams);

    return obj;
}

@end

@implementation Menu

+(Menu*) menuWithElement: (NSXMLElement*) element withDefaults: (DeviceEntry*) defaults
{
    Menu* obj = [[Menu alloc] init];

    obj->m_title = [NSString stringWithString:stringAttribute(element, @"title")];
    
    // parse all the items
    obj->m_itemTitle = [[NSMutableArray alloc] init];
    obj->m_itemParams = [[NSMutableArray alloc] init];

    NSArray* menuItems = [element elementsForName:@"menu_item"];
    for (int i = 0; i < [menuItems count]; ++i) {
        NSXMLElement* itemElement = (NSXMLElement*) [menuItems objectAtIndex:i];
        [obj->m_itemTitle addObject: stringAttribute(itemElement, @"title")];
        
        NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
        [obj->m_itemParams addObject: params];
        parseParams(itemElement, params);
    }

    return obj;
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
        [m_qualityStops insertObject:[QualityStop qualityStopWithElement: element withDefaults: nil] atIndex:which];
    }
}

-(void) parsePerformanceItems: (NSArray*) array
{
    for (int i = 0; i < [array count]; ++i) {
        NSXMLElement* element = (NSXMLElement*) [array objectAtIndex:i];
        [m_performanceItems addObject: [PerformanceItem performanceItemWithElement: element withDefaults: nil]];
    }
}

-(void) parseRecipes: (NSArray*) array
{
    for (int i = 0; i < [array count]; ++i) {
        NSXMLElement* element = (NSXMLElement*) [array objectAtIndex:i];

        [m_recipes addObject:[Recipe recipeWithElement: element withDefaults: nil]];
    }
}

-(void) parseCheckboxes: (NSArray*) array
{
    for (int i = 0; i < [array count]; ++i) {
        NSXMLElement* element = (NSXMLElement*) [array objectAtIndex:i];
        int which = (int) doubleAttribute(element, @"which");
        if (which < 0 || which > MAX_CHECKBOXES)
            continue;
        [m_checkboxes insertObject:[Checkbox checkboxWithElement: element withDefaults: nil] atIndex:which];
    }
}

-(void) parseMenus: (NSArray*) array
{
    for (int i = 0; i < [array count]; ++i) {
        NSXMLElement* element = (NSXMLElement*) [array objectAtIndex:i];
        int which = (int) doubleAttribute(element, @"which");
        if (which < 0 || which > MAX_MENUS)
            continue;
        [m_menus insertObject:[Menu menuWithElement: element withDefaults: nil] atIndex:which];
    }
}

-(void) parseRadios: (NSArray*) array
{
    for (int i = 0; i < [array count]; ++i) {
        NSXMLElement* element = (NSXMLElement*) [array objectAtIndex:i];
        int which = (int) doubleAttribute(element, @"which");
        if (which < 0 || which > MAX_RADIOS)
            continue;
        [m_radios insertObject:[Menu menuWithElement: element withDefaults: nil] atIndex:which];
    }
}

+(DeviceEntry*) deviceEntryWithElement: (NSXMLElement*) element inGroup: (NSString*) group withDefaults: (DeviceEntry*) defaults
{
    return [[DeviceEntry alloc] initWithElement: element inGroup: group withDefaults: defaults];
}

-(DeviceEntry*) initWithElement: (NSXMLElement*) element inGroup: (NSString*) group withDefaults: (DeviceEntry*) defaults;
{
    m_id = [NSString stringWithString:stringAttribute(element, @"id")];
    m_title = [NSString stringWithString:stringAttribute(element, @"title")];
    m_groupTitle = [NSString stringWithString:group ? group : @""];
    
    m_qualityStops = [NSMutableArray arrayWithCapacity:6];
    m_performanceItems = [NSMutableArray arrayWithCapacity:6];
    m_recipes = [NSMutableArray arrayWithCapacity:4];
    m_checkboxes = [NSMutableArray arrayWithCapacity:2];
    m_menus = [NSMutableArray arrayWithCapacity:2];
    m_radios = [NSMutableArray arrayWithCapacity:2];
    
    m_params = [[NSMutableDictionary alloc] init];
    
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
    
    // handle radios
    [self parseRadios:[element elementsForName:@"radio"]];
    
    return self;
}

-(NSString*) id
{
    return m_id;
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
    NSXMLDocument* doc = [[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentTidyXML error:nil];
    if (!doc || ![[[doc rootElement] name] isEqualToString:@"videomonkey"])
        return;
        
    // extract the commands
    m_commands = [[NSMutableDictionary alloc] init];
    NSXMLElement* commandsElement = findChildElement([doc rootElement], @"commands");
    NSArray* commandArray = [commandsElement elementsForName:@"command"];
    
    for (int i = 0; i < [commandArray count]; ++i) {
        NSXMLElement* element = (NSXMLElement*) [commandArray objectAtIndex:i];
        NSString* id = stringAttribute(element, @"id");
        if ([id length])
            [m_commands setValue: content(element) forKey: id];
    }
    
    // extract the defaults
    DeviceEntry* defaultDevice = [DeviceEntry deviceEntryWithElement: findChildElement([doc rootElement], @"default_device") inGroup: nil withDefaults: nil];
        
    // Build the device list
    NSMutableDictionary* m_devices = [[NSMutableDictionary alloc] init];
    
    NSXMLElement* devicesElement = findChildElement([doc rootElement], @"devices");
    NSArray* deviceGroups = [devicesElement elementsForName:@"device_group"];
    
    for (int i = 0; i < [deviceGroups count]; ++i) {
        NSXMLElement* deviceGroupElement = (NSXMLElement*) [deviceGroups objectAtIndex:i];
        NSString* groupTitle = stringAttribute(deviceGroupElement, @"title");
        NSArray* devices = [deviceGroupElement elementsForName:@"device"];
        
        for (int j = 0; j < [devices count]; ++j) {
            NSXMLElement* deviceElement = (NSXMLElement*) [devices objectAtIndex:i];
            DeviceEntry* entry = [DeviceEntry deviceEntryWithElement: deviceElement inGroup: groupTitle withDefaults: defaultDevice];
            if (entry)
                [m_devices setValue: entry forKey: [entry id]];
        }
    }
    
    // build the environment
    m_environment = [[NSMutableDictionary alloc] init];

    // fill in the commands
    NSString* cmdPath = [NSString stringWithString: [[NSBundle mainBundle] resourcePath]];
    [m_environment setValue: [cmdPath stringByAppendingPathComponent: @"bin/ffmpeg"] forKey: @"ffmpeg"];
    [m_environment setValue: [cmdPath stringByAppendingPathComponent: @"bin/qt_export"] forKey: @"qt_export"];
    [m_environment setValue: [cmdPath stringByAppendingPathComponent: @"bin/movtoy4m"] forKey: @"movtoy4m"];
    [m_environment setValue: [cmdPath stringByAppendingPathComponent: @"bin/yuvadjust"] forKey: @"yuvadjust"];
    [m_environment setValue: [cmdPath stringByAppendingPathComponent: @"bin/yuvcorrect"] forKey: @"yuvcorrect"];
}

- (void) awakeFromNib
{
    // load the XML file with all the commands and device setup
    [self initCommands];

    [m_conversionParamsButton selectItemAtIndex:1];
    m_currentTabViewItem = [[m_conversionParamsButton selectedItem] representedObject];
    [m_conversionParamsTabView selectTabViewItem: m_currentTabViewItem];
    
    [m_performanceButton selectItemAtIndex:2];
    [self setPerformance: [m_performanceButton indexOfSelectedItem]];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    return [menuItem isEnabled];
}

- (IBAction)selectTab:(id)sender {
    m_currentTabViewItem = [sender representedObject];
    [m_conversionParamsTabView selectTabViewItem: m_currentTabViewItem];
}

- (IBAction)selectPerformance:(id)sender {
    [self setPerformance: [sender indexOfSelectedItem]];
}

- (IBAction)paramChanged:(id)sender {
    //printf("paramChanged: quality=%d\n", (int) [m_currentTabViewItem h264]);
}

-(BOOL) isTwoPass
{
    return m_isTwoPass;
}

-(NSString*) performance
{
    return m_currentPerformance;
}

-(NSString*) device
{
    return [m_currentTabViewItem deviceName];
}

@end
