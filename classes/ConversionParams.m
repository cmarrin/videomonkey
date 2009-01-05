//
//  ConversionParams.m
//  ConversionParams
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright Chris Marrin 2008. All rights reserved.
//

#import "ConversionParams.h"

static NSString* attribute(NSXMLElement* element, NSString* name)
{
    NSXMLNode* node = [element attributeForName:name];
    return node ? [node stringValue] : @"";
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

@implementation ConversionTab

-(NSString*) deviceName
{
    return [self identifier];
}

@end

@implementation DeviceEntry

-(void) parseQualityStops: (NSArray*) array
{
}

-(void) parsePerformanceItems: (NSArray*) array
{
}

-(void) parseRecipes: (NSArray*) array
{
}

-(void) parseParams: (NSArray*) array
{
}

-(void) parseCheckboxes: (NSArray*) array
{
}

-(void) parseMenus: (NSArray*) array
{
}

-(void) parseRadios: (NSArray*) array
{
}

+(DeviceEntry*) deviceEntryWithElement: (NSXMLElement*) element inGroup: (NSString*) group withDefaults: (DeviceEntry*) defaults
{
    return [[DeviceEntry alloc] initWithElement: element inGroup: group withDefaults: defaults];
}

-(DeviceEntry*) initWithElement: (NSXMLElement*) element inGroup: (NSString*) group withDefaults: (DeviceEntry*) defaults;
{
    m_id = [NSString stringWithString:attribute(element, @"id")];
    m_title = [NSString stringWithString:attribute(element, @"title")];
    m_groupTitle = [NSString stringWithString:group ? group : @""];
    
    // handle quality
    [self parseQualityStops:[findChildElement(element, @"quality") elementsForName: @"quality_stop"]];
    
    // handle performance
    [self parsePerformanceItems:[findChildElement(element, @"performance") elementsForName: @"performance_item"]];
    
    // handle recipes
    [self parseRecipes:[findChildElement(element, @"recipes") elementsForName: @"recipe"]];
    
    // handle params
    [self parseParams:[element elementsForName:@"param"]];
    
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
        NSString* id = attribute(element, @"id");
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
        NSString* groupTitle = attribute(deviceGroupElement, @"title");
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
