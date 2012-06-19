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

#import "DeviceController.h"

#import "AppController.h"
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
    [item setTag:-1];
    [[button menu] addItem:item];
}

@implementation DeviceController

@synthesize audioCodecStrings = m_audioCodecStrings;
@synthesize audioChannelsStrings = m_audioChannelsStrings;
@synthesize audioBitrateStrings = m_audioBitrateStrings;
@synthesize audioSampleRateStrings = m_audioSampleRateStrings;
@synthesize videoCodecStrings = m_videoCodecStrings;
@synthesize videoProfileStrings = m_videoProfileStrings;

-(void) initCommands
{
    NSURL* url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"commands" ofType:@"xml"]];
    XMLDocument* doc = [XMLDocument xmlDocumentWithContentsOfURL:url withInfo:@"loading commands.xml"];

    // extract the defaults
    m_defaultDevice = [DeviceEntry deviceEntryWithElement: [[doc rootElement] lastElementForName:@"default_device"] inGroup: nil withDefaults: nil];
    [m_defaultDevice retain];
    
    // Build the device list
    m_devices = [[NSMutableArray alloc] init];
    
    XMLElement* devicesElement = [[doc rootElement] lastElementForName:@"devices"];
    NSArray* deviceGroups = [devicesElement elementsForName:@"device_group"];
    
    for (int i = 0; i < [deviceGroups count]; ++i) {
        XMLElement* deviceGroupElement = (XMLElement*) [deviceGroups objectAtIndex:i];
        NSString* groupTitle = [deviceGroupElement stringAttribute:@"title"];

        DeviceEntry* commonDevice = [DeviceEntry deviceEntryWithElement: [deviceGroupElement lastElementForName:@"common_device"] inGroup: groupTitle withDefaults: m_defaultDevice];

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
                continue;
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
            NSString* substitution = [m_context stringParamForKey: param showError:YES];
            if (substitution)
                [tmpString appendString:substitution];
            [tmpString appendString:other];
        }
        
        string = tmpString;
    }
    
    // All done substituting, now replace $$ with \$
    NSArray* array = [string componentsSeparatedByString:@"$$"];
    string = [array componentsJoinedByString:@"\\$"];

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

- (void)initWithDelegate:(id)delegate
{
    // Create JS context
    m_context = [[JavaScriptContext alloc] init];
    
    // make sure delegate sets up the context
    [self setDelegate: delegate];

    // load the XML file with all the commands and device setup
    [self initCommands];
    
    id userDevice = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"currentDeviceIndex"];
    int deviceIndex = userDevice ? [userDevice intValue] : -1;
    
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
    
    [m_actionButton selectItemAtIndex:ActionEncodeWrite];
    m_metadataActionsEnabled = YES;

    // set the selected item
    if ([m_deviceButton selectItemWithTag:deviceIndex]) {
		DeviceEntry* deviceEntry = [self findDeviceEntryWithIndex:deviceIndex];
		
		// if the deviceEntry is nil, it mean we had an invalid deviceIndex (probably a bad index from the pref file)
		// fix that here
		if (!deviceEntry) {
			deviceIndex = 0;
			[m_deviceButton selectItemWithTag:deviceIndex];
			deviceEntry = [self findDeviceEntryWithIndex:deviceIndex];
			[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:[NSNumber numberWithInt:deviceIndex] forKey:@"currentDeviceIndex"];
		}
		
		[self setCurrentDevice:deviceEntry];
	}
	
    [self setCurrentParamsWithEnvironment:nil];
    
    // Initialize the advanced override menus
    NSString* string = [self paramForKey:@"advanced_audio_codec"];
    self.audioCodecStrings = [string componentsSeparatedByString:@","];
    string = [self paramForKey:@"advanced_audio_channels"];
    self.audioChannelsStrings = [string componentsSeparatedByString:@","];
    string = [self paramForKey:@"advanced_audio_bitrate"];
    self.audioBitrateStrings = [string componentsSeparatedByString:@","];
    string = [self paramForKey:@"advanced_audio_sample_rate"];
    self.audioSampleRateStrings = [string componentsSeparatedByString:@","];
    string = [self paramForKey:@"advanced_video_codec"];
    self.videoCodecStrings = [string componentsSeparatedByString:@","];
    string = [self paramForKey:@"advanced_video_profile"];
    self.videoProfileStrings = [string componentsSeparatedByString:@","];

    [self uiChanged];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    return [menuItem isEnabled];
}

- (IBAction)selectDevice:(id)sender
{
    int deviceIndex = [[sender selectedItem] tag];
    [[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:[NSNumber numberWithInt:deviceIndex] forKey:@"currentDeviceIndex"];
    [self setCurrentDevice:[self findDeviceEntryWithIndex:deviceIndex]];
    [self uiChanged];
}

- (IBAction)changeUI:(id)sender
{
    [self uiChanged];
}

-(NSString*) fileSuffix
{
    return [self paramForKey:@"video_suffix"];
}

-(void) setCurrentParamsWithEnvironment: (NSDictionary*) env
{
    if (env)
        [m_context addParams:env];
        
    [m_currentDevice setCurrentParamsInJavaScriptContext:m_context performanceIndex:[m_performanceButton indexOfSelectedItem]];
}

-(NSString*) recipe
{
    NSString* recipe = [self paramForKey:@"recipe"];
    return [self replaceParams: recipe];
}


- (BOOL)hasParamForKey:(NSString*) key
{
    return [m_context stringParamForKey: key showError:NO] != nil;
}

-(NSString*) paramForKey:(NSString*) key
{
    return [m_context stringParamForKey: key showError:YES];
}

- (void)processResponse:(NSString*) response forCommand:(NSString*) command
{
    [m_context callBooleanFunction:@"processResponse" withParameters:command, response, nil];
}

- (void)uiChanged
{
    [m_delegate uiChanged];
    [m_currentDevice setCurrentParamsInJavaScriptContext:m_context performanceIndex:[m_performanceButton indexOfSelectedItem]];
    
    // Update the actions
    if (![self hasParamForKey:@"output_format_name"])
        return;
    
    
    BOOL enabled = [[self paramForKey:@"output_format_name"] isEqualToString:@"MPEG-4"];
    if (m_metadataActionsEnabled == enabled)
        return;
        
    m_metadataActionsEnabled = enabled;
    
    [m_actionButton selectItemAtIndex:m_metadataActionsEnabled ? ActionEncodeWrite : ActionEncodeOnly];
    [[m_actionButton itemAtIndex:ActionEncodeWrite] setEnabled:m_metadataActionsEnabled];
    [[m_actionButton itemAtIndex:ActionWriteOnly] setEnabled:m_metadataActionsEnabled];
    [[m_actionButton itemAtIndex:ActionRewriteOnly] setEnabled:m_metadataActionsEnabled];
}

- (BOOL)shouldEncode
{
    NSInteger sel = [m_actionButton indexOfSelectedItem];
    return sel == ActionEncodeWrite || sel == ActionEncodeOnly;
}

- (BOOL)shouldWriteMetadata
{
    NSInteger sel = [m_actionButton indexOfSelectedItem];
    return sel == ActionEncodeWrite || sel == ActionWriteOnly || sel == ActionRewriteOnly;
}

- (BOOL)shouldWriteMetadataToInputFile
{
    NSInteger sel = [m_actionButton indexOfSelectedItem];
    return sel == ActionWriteOnly;
}

- (BOOL)shouldWriteMetadataToOutputFile
{
    NSInteger sel = [m_actionButton indexOfSelectedItem];
    return sel == ActionEncodeWrite || sel == ActionRewriteOnly;
}

@end
