//
//  ConversionParams.m
//  ConversionParams
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright Chris Marrin 2008. All rights reserved.
//

#import "ConversionParams.h"

@implementation ConversionTab

-(NSString*) deviceName
{
    return [self identifier];
}

@end

@implementation DeviceEntry

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

// Command file contains an outer <videomonkey> element with one of each children:
//
//  <commands> - command strings used by all devices, with children:
//      <command> - command string, contained text is the string of the command, with attributes:
//          id - name of the command (referenced by other commands)
//
//  <default_device> - parameters used by any device when not overridden, with children:
//      <quality> - set of stops for quality slider, with children:
//          <quality_stop> - one quality stop, with attributes:
//              which - index of this quality stop (0-5)
//                  Quality stop 0 is untitled and is used to hold lowest values for slider.
//                  Quality stop 5 is the rightmost tick mark and holds the highest slider values.
//              title - the title of the tick mark
//              bitrate - highest bitrate for this tick mark (or minimum bitrate when which=0)
//              audio - audio quality: low (16k, 1ch, 11025), medium (32k, 1ch, 22050), high (128k, 2ch, 48000)
//              size - relative video size (e.g., 0.5 is half size horiz and vert)
//
//      <performance> - values for performance menu, with children:
//          <performance_item> - one item in menu, with attributes and children:
//              title - title of this item in menu
//              <param> - a param (in runtime param dictionary) to use when this item is selected, with atributes:
//                  id - name of this param
//                  value - string value of this param (can use $ and ! as in commands)
//
//      <param> - see above. Param to use if none of the same name is given in device spec.
//
//      <recipes> - default recipes to use. Content is recipe string, with attributes
//          is_quicktime - boolean, true is special quicktime processing is needed
//          has_audio - boolean, true if source has audio
//          is_2pass - boolean, true if 2 pass is requested
//
//  <devices> - List of devices in device menu, with children:
//      <device_group> - A grouping of devices. Each groups has a title and groups are separated by a line, with attributes and children:
//          title - title for this group
//          <device> - device in this group, with same children as <default_device> and additional attributes and children:
//              title - title for this device
//              id - internal identifier to use for this device
//              tab - which tab in the GUI to use for this device (see below)
//              <checkbox> - in tabs with checkboxes this describes a checkbox, with attributes:
//                  which - which checkbox (0-n)
//                  title - title on the checkbox
//                  id - name of the param described by this checkbox
//                  checked - value to use for this param when box is checked
//                  unchecked - value to use for this param when box is unchecked

static NSXMLElement* findChildElement(NSXMLElement* element, NSString* name)
{
    NSArray* array = [element elementsForName:name];
    if (!array || [array count] == 0)
        return nil;
        
    return [array objectAtIndex:0];
}

static NSString* attribute(NSXMLElement* element, NSString* name)
{
    NSXMLNode* node = [element attributeForName:name];
    return node ? [node stringValue] : nil;
}

static NSString* content(NSXMLElement* element)
{
    // It seems that the content is always the first child and that leading and trailing whitespace is removed.
    // Let's assume that for now
    return [element childCount] ? [[element childAtIndex:0] stringValue] : nil;
}

-(DeviceEntry*) makeDeviceEntry: (NSXMLElement*) element inGroup: (NSString*) group withDefaults: (DeviceEntry*) defaults
{
    DeviceEntry* device = [[DeviceEntry alloc] init];
    
    // handle quality
    
    // handle performance
    
    // handle recipe
    
    // handle params
    
    // handle checkboxes
    
    // handle menus
    
    // handle radios
    
    return device;
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
    DeviceEntry* defaultDevice = [self makeDeviceEntry: findChildElement([doc rootElement], @"default_device") inGroup: nil withDefaults: nil];
        
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
            DeviceEntry* entry = [self makeDeviceEntry: deviceElement inGroup: groupTitle withDefaults: defaultDevice];
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
