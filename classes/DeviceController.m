//
//  DeviceController.m
//  DeviceController
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright Chris Marrin 2008. All rights reserved.
//

#import "DeviceController.h"
#import "DeviceEntry.h"
#import "JavaScriptContext.h"
#import "XMLDocument.h"

@interface NSObject (AppDelegate)
-(void) log: (NSString*) format, ...;
-(void) uiChanged;
@end
 
static NSImage* getImage(NSString* name)
{
    NSString* path = [[NSBundle mainBundle] pathForResource:name ofType:@"png"];
    return [[NSImage alloc] initWithContentsOfFile:path];
}

static void addMenuItem(NSPopUpButton* button, NSString* title, NSString* icon, int tag, BOOL enabled)
{
    NSMenuItem* item = [[NSMenuItem alloc] init];
    [item setTag:tag];
    if (tag < 0) {
        [item setEnabled:NO];
        NSAttributedString*  s =[[NSAttributedString alloc] initWithString:title 
                                attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSFont boldSystemFontOfSize:0], NSFontAttributeName, 
                                    [NSColor blackColor], NSForegroundColorAttributeName,
                                    nil]];
        [item setAttributedTitle:s];
    }
    else {
        [item setIndentationLevel:1];
        [item setTitle:title];
        [item setEnabled:enabled];
        if (icon) {
            NSString* iconName = [NSString stringWithFormat:@"tiny%@", icon];
            NSImage* image = getImage(iconName);
            if (!image)
                NSRunAlertPanel(@"Image not found", [NSString stringWithFormat:@"Image file '%@' does not exist", iconName], nil, nil, nil);
            else
                [item setImage: image];
        }
    }
        
    [[button menu] addItem:item];
}

static void addMenuSeparator(NSPopUpButton* button)
{
    NSMenuItem* item = [NSMenuItem separatorItem];
    [[button menu] addItem:item];
}

@implementation DeviceController

-(void) initCommands
{
    NSURL* url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"commands" ofType:@"xml"]];
    XMLDocument* doc = [XMLDocument xmlDocumentWithContentsOfURL:url];

    // extract the defaults
    m_defaultDevice = [DeviceEntry deviceEntryWithElement: [[doc rootElement] findChildElement:@"default_device"] inGroup: nil withDefaults: nil];
    [m_defaultDevice retain];
    
    // Build the device list
    m_devices = [[NSMutableArray alloc] init];
    
    XMLElement* devicesElement = [[doc rootElement] findChildElement:@"devices"];
    NSArray* deviceGroups = [devicesElement elementsForName:@"device_group"];
    
    for (int i = 0; i < [deviceGroups count]; ++i) {
        XMLElement* deviceGroupElement = (XMLElement*) [deviceGroups objectAtIndex:i];
        NSString* groupTitle = stringAttribute(deviceGroupElement, @"title");

        DeviceEntry* commonDevice = [DeviceEntry deviceEntryWithElement: findChildElement(deviceGroupElement, @"common_device") inGroup: groupTitle withDefaults: m_defaultDevice];

        NSArray* devices = [deviceGroupElement elementsForName:@"device"];
        
        for (int j = 0; j < [devices count]; ++j) {
            XMLElement* deviceElement = (XMLElement*) [devices objectAtIndex:j];
            DeviceEntry* entry = [DeviceEntry deviceEntryWithElement: deviceElement inGroup: groupTitle withDefaults: commonDevice];
            if (entry)
                [m_devices addObject: entry];
        }
    }
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

-(NSString*) replaceParams:(NSString*) recipeString
{
    if (!recipeString)
        return nil;
        
    NSString* string = recipeString;
    NSMutableString* tmpString = [[NSMutableString alloc] init];
    BOOL didSubstitute = YES;
    
    while (didSubstitute) {
       didSubstitute = NO;
       
        NSArray* array = [string componentsSeparatedByString:@"$"];
        [tmpString setString:[array objectAtIndex:0]];
        
        BOOL firstTime = YES;
        BOOL skipNext = NO;
         
        for (NSString* s in array) {
            if (firstTime) {
                firstTime = NO;
                continue;
            }
                
            if (skipNext) {
                [tmpString appendString:s];
                skipNext = NO;
                continue;
            }
                
            // if s is of 0 length, it means there is a $$ sequence, in which case we output it as a literal $
            // But we can't do that yet, because we would catch it as a substitution on the next pass. So we leave
            // it doubled for now
            if ([s length] == 0) {
                skipNext = YES;
                [tmpString appendString:@"$$"];
            }
            
            // pick out the param name
            NSString* param;
            NSString* other;
            
            if ([s characterAtIndex:0] == '(') {
                // pick out param between parens
                NSRange range = [s rangeOfString: @")"];
                if (range.location == NSNotFound) {
                    // invalid
                    param = @"";
                    other = @"";
                }
                else {
                    param = [[s substringFromIndex:1] substringToIndex:range.location-1];
                    other = [s substringFromIndex:range.location+1];
                }
            }
            else {
                // pick out param
                NSMutableCharacterSet* nonIdentifierSet = [NSMutableCharacterSet alphanumericCharacterSet];
                [nonIdentifierSet addCharactersInString:@"_"];
                [nonIdentifierSet invert];
                NSRange range = [s rangeOfCharacterFromSet:nonIdentifierSet];
                if (range.location == NSNotFound) {
                    param = s;
                    other = @"";
                }
                else {
                    param = [s substringToIndex:range.location];
                    other = [s substringFromIndex:range.location];
                }
            }
            
            // do param substitution
            didSubstitute = YES;
            NSString* substitution = [m_context stringParamForKey: param];
            if (substitution)
                [tmpString appendString:substitution];
            [tmpString appendString:other];
        }
        
        string = tmpString;
    }
    
    // All done substituting, now replace $$ with $
    NSArray* array = [string componentsSeparatedByString:@"$$"];
    string = [array componentsJoinedByString:@"$"];

    // Finally, get rid of all '\n' chars and extra whitespace
    array = [string componentsSeparatedByString:@"\n"];
    [tmpString setString:@""];
    BOOL isFirst = YES;
    for (NSString* s in array) {
        if (!isFirst)
            [tmpString appendString:@" "];
        else
            isFirst = NO;
        [tmpString appendString:[s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
    }
    
    return tmpString;
}

-(void) setCurrentDevice: (DeviceEntry*) device
{
    m_currentDevice = device;
    [m_currentDevice populateTabView: m_deviceControllerTabView];
    [m_currentDevice populatePerformanceButton: m_performanceButton];

	// set the device name and image
    if (m_currentDevice) {
        [m_deviceImageView setImage:getImage([m_currentDevice icon])];
        [m_deviceName setStringValue:[m_currentDevice title]];
    }
}

- (void) awakeFromNib
{
    // Create JS context
    m_context = [[JavaScriptContext alloc] init];
    
    // make sure delegate sets up the context
    [self setDelegate: m_delegate];

    // load the XML file with all the commands and device setup
    [self initCommands];
    
    int deviceIndex = [m_deviceButton indexOfSelectedItem];
    int performanceIndex = [m_performanceButton indexOfSelectedItem];
    
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
            if (i != 0)
                addMenuSeparator(m_deviceButton);
            addMenuItem(m_deviceButton, currentGroup, nil, -1, false);
        }
        
        addMenuItem(m_deviceButton, [entry title], [entry icon], currentItem++, [entry enabled]);
    }
    
    // set the selected item
    [m_deviceButton selectItemAtIndex:deviceIndex];
    [self setCurrentDevice:[self findDeviceEntryWithIndex:[[m_deviceButton itemAtIndex: deviceIndex] tag]]];

    // set the selected item
    // FIXME: need to get this from prefs
    [m_performanceButton selectItemAtIndex:performanceIndex];
    
    [self setCurrentParamsWithEnvironment:nil];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    return [menuItem isEnabled];
}

- (IBAction)selectDevice:(id)sender {
    [self setCurrentDevice:[self findDeviceEntryWithIndex:[[sender selectedItem] tag]]];
    [self uiChanged];
}

- (IBAction)selectPerformance:(id)sender {
    [self uiChanged];
}

-(NSString*) fileSuffix
{
    return [m_currentDevice fileSuffix];
}

-(NSString*) videoFormat
{
    return [m_currentDevice videoFormat];
}

static JSValueRef _jsLog(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, 
                         const JSValueRef arguments[], JSValueRef* exception)
{
    JSObjectRef global = JSContextGetGlobalObject(ctx);
    JSStringRef propString = JSStringCreateWithUTF8CString("$app");
    JSValueRef jsValue = JSObjectGetProperty(ctx, global, propString, NULL);
    JSObjectRef obj = JSValueToObject(ctx, jsValue, NULL);
    id delegate = (id) JSObjectGetPrivate(obj);

    // make a string out of the args
    NSMutableString* string = [[NSMutableString alloc] init];
    for (int i = 0; i < argumentCount; ++i) {
        JSStringRef jsString = JSValueToStringCopy(ctx, arguments[i], NULL);
        [string appendString:[NSString stringWithJSString:jsString]];
    }
    
    if ([delegate respondsToSelector: @selector(log:)])
        [delegate log:[NSString stringWithFormat:@"JS log: %@\n", string]];
    
    return JSValueMakeUndefined(ctx);
}

-(void) setDelegate:(id) delegate
{
    m_delegate = delegate;
    
    if (m_context) {
        // Add log method
        [m_context addGlobalObject:@"$app" ofClass:NULL withPrivateData:m_delegate];
        [m_context addGlobalFunctionProperty:@"log" withCallback:_jsLog];
    }
}

-(void) setCurrentParamsWithEnvironment: (NSDictionary*) env
{
    if (env)
        [m_context addParams:env];
        
    [m_currentDevice setCurrentParamsInJavaScriptContext:m_context performanceIndex:[m_performanceButton indexOfSelectedItem]];
}

-(NSString*) recipe
{
    NSString* recipe = [m_context stringParamForKey:@"recipe"];
    return [self replaceParams: recipe];
}

-(NSString*) paramForKey:(NSString*) key
{
    return [m_context stringParamForKey: key];
}

-(void) uiChanged
{
    [m_delegate uiChanged];
}

@end
