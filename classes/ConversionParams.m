//
//  ConversionParams.m
//  ConversionParams
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright Chris Marrin 2008. All rights reserved.
//

#import "ConversionParams.h"
#import "JavaScriptContext.h"
#import "Transcoder.h"

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
    if ([element childCount] == 0)
        return @"";
    NSString* string = [[element childAtIndex:0] stringValue];
    return [[string stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]] retain];
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

static void addCommand(NSXMLElement* paramElement, NSMutableDictionary* dictionary)
{
    NSString* key = stringAttribute(paramElement, @"id");
    NSString* value = content(paramElement);
    if ([key length])
        [dictionary setValue:value forKey:key];
}

static void parseParams(NSXMLElement* element, NSMutableDictionary* dictionary)
{
    // handle <param>
    NSArray* array = [element elementsForName: @"param"];
    for (int i = 0; i < [array count]; ++i)
        addParam((NSXMLElement*) [array objectAtIndex:i], dictionary);

    // handle <command>
    array = [element elementsForName: @"command"];
    for (int i = 0; i < [array count]; ++i)
        addCommand((NSXMLElement*) [array objectAtIndex:i], dictionary);
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
    // We can draw a slider with 2, 3, or 5 tick marks. There is one more entry in the array than tick
    // marks. The entry at index 0 just sets the minumum bitrate to use.
    // If we see any other number in the array we will turn off the quality slider
    [m_slider setHidden:NO];
    [m_sliderLabel1 setHidden:NO];
    [m_sliderLabel2 setHidden:NO];
    [m_sliderLabel3 setHidden:NO];
    [m_sliderLabel4 setHidden:NO];
    [m_sliderLabel5 setHidden:NO];
    
    if ([qualityStops count] == 3) {
        [m_slider setNumberOfTickMarks:2];
        [m_sliderLabel1 setStringValue:[(QualityStop*) [qualityStops objectAtIndex:1] title]];
        [m_sliderLabel2 setHidden:YES];
        [m_sliderLabel3 setHidden:YES];
        [m_sliderLabel4 setHidden:YES];
        [m_sliderLabel5 setStringValue:[(QualityStop*) [qualityStops objectAtIndex:2] title]];
    }
    else if ([qualityStops count] == 4) {
        [m_slider setNumberOfTickMarks:3];
        [m_sliderLabel1 setStringValue:[(QualityStop*) [qualityStops objectAtIndex:1] title]];
        [m_sliderLabel2 setHidden:YES];
        [m_sliderLabel3 setStringValue:[(QualityStop*) [qualityStops objectAtIndex:2] title]];
        [m_sliderLabel4 setHidden:YES];
        [m_sliderLabel5 setStringValue:[(QualityStop*) [qualityStops objectAtIndex:3] title]];
    }
    else if ([qualityStops count] == 6) {
        [m_slider setNumberOfTickMarks:5];
        [m_sliderLabel1 setStringValue:[(QualityStop*) [qualityStops objectAtIndex:1] title]];
        [m_sliderLabel2 setStringValue:[(QualityStop*) [qualityStops objectAtIndex:2] title]];
        [m_sliderLabel3 setStringValue:[(QualityStop*) [qualityStops objectAtIndex:3] title]];
        [m_sliderLabel4 setStringValue:[(QualityStop*) [qualityStops objectAtIndex:4] title]];
        [m_sliderLabel5 setStringValue:[(QualityStop*) [qualityStops objectAtIndex:5] title]];
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
    return (int) (value * ticks) + 1;
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

-(NSDictionary*) params
{
    return m_params;
}

-(NSString*) script
{
    return m_script;
}

@end

@implementation Recipe

+(Recipe*) recipeWithElement: (NSXMLElement*) element
{
    Recipe* obj = [[Recipe alloc] init];
    obj->m_recipe = [NSString stringWithString:content(element)];
    obj->m_condition = [NSString stringWithString:stringAttribute(element, @"condition")];
    return obj;
}

-(NSString*) recipe
{
    return m_recipe;
}

-(NSString*) condition
{
    return m_condition;
}

@end

@implementation Checkbox

+(Checkbox*) checkboxWithElement: (NSXMLElement*) element
{
    Checkbox* obj = [[Checkbox alloc] init];

    obj->m_title = [NSString stringWithString:stringAttribute(element, @"title")];
    obj->m_checkedParams = [[NSMutableDictionary alloc] init];
    obj->m_uncheckedParams = [[NSMutableDictionary alloc] init];
    
    NSXMLElement* e = findChildElement(element, @"checked_params");
    parseParams(e, obj->m_checkedParams);
    obj->m_checkedScript = parseScripts(e);

    e = findChildElement(element, @"unchecked_params");
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

@implementation Menu

+(Menu*) menuWithElement: (NSXMLElement*) element
{
    Menu* obj = [[Menu alloc] init];

    obj->m_title = [NSString stringWithString:stringAttribute(element, @"title")];
    
    // parse all the items
    obj->m_itemTitles = [[NSMutableArray alloc] init];
    obj->m_itemParams = [[NSMutableArray alloc] init];
    obj->m_itemScripts = [[NSMutableArray alloc] init];

    NSArray* menuItems = [element elementsForName:@"menu_item"];
    for (int i = 0; i < [menuItems count]; ++i) {
        NSXMLElement* itemElement = (NSXMLElement*) [menuItems objectAtIndex:i];
        [obj->m_itemTitles addObject: stringAttribute(itemElement, @"title")];
        
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
    m_defaultDevice = [defaults retain];
    m_id = [NSString stringWithString:stringAttribute(element, @"id")];
    m_title = [NSString stringWithString:stringAttribute(element, @"title")];
    m_groupTitle = [NSString stringWithString:group ? group : @""];
    
    m_qualityStops = [[NSMutableArray alloc] init];
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
    
    // handle scripts
    m_script = parseScripts(element);
    
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

static JSValueRef _jsLog(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, 
                         const JSValueRef arguments[], JSValueRef* exception)
{
    JSObjectRef global = JSContextGetGlobalObject(ctx);
    JSStringRef propString = JSStringCreateWithUTF8CString("$transcoder");
    JSValueRef jsValue = JSObjectGetProperty(ctx, global, propString, NULL);
    JSObjectRef obj = JSValueToObject(ctx, jsValue, NULL);
    Transcoder* transcoder = (Transcoder*) JSObjectGetPrivate(obj);

    // make a string out of the args
    NSMutableString* string = [[NSMutableString alloc] init];
    for (int i = 0; i < argumentCount; ++i) {
        JSStringRef jsString = JSValueToStringCopy(ctx, arguments[i], NULL);
        [string appendString:[NSString stringWithJSString:jsString]];
    }
    
    [string appendString:@"\n"];
    
    [transcoder log:string];
    
    return JSValueMakeUndefined(ctx);
}

-(NSString*) recipeWithTabView:(NSTabView*) tabview performanceIndex:(int) perfIndex environment:(NSDictionary*) env transcoder:(Transcoder*) transcoder
{
    ConversionTab* tab = (ConversionTab*) [tabview selectedTabViewItem];

    // Create JS context
    JavaScriptContext* context = [[JavaScriptContext alloc] init];
    
    // Add log method
    [context addGlobalObject:@"$transcoder" ofClass:NULL withPrivateData:transcoder];
    [context addGlobalFunctionProperty:@"log" withCallback:_jsLog];
    
    // Add environment
    [context addParams:env];
    
    // Add params and commands from default device
    [m_defaultDevice addParamsToJavaScriptContext: context withTab: tab performanceIndex:perfIndex];
    
    // Add params and commands from this device
    [self addParamsToJavaScriptContext: context withTab: tab performanceIndex:perfIndex];
    
    // Execute script from default device
    [m_defaultDevice evaluateScript: context withTab: tab performanceIndex:perfIndex];
    
    // Execute script from this device
    [self evaluateScript: context withTab: tab performanceIndex:perfIndex];
    
    // For each recipe item, execute its condition and if it returns true, that is the recipe to use
    NSString* recipeString;
    
    for (Recipe* recipe in [self recipes]) {
        NSString* returnString = [context evaluateJavaScript:[recipe condition]];
        if ([returnString boolValue]) {
            recipeString = [recipe recipe];
            break;
        }
    }
    
    // Recursively replace all $xxx or $(xxx) entries in recipe with values from params in JS context
    if (recipeString)
        return [self replaceParams:recipeString withContext: context];
    
    return nil;
}

-(void) populateTabView:(NSTabView*) tabview
{
    [tabview selectTabViewItemWithIdentifier:m_deviceTab];
    ConversionTab* tab = (ConversionTab*) [tabview selectedTabViewItem];
    
    [tab setCheckboxes: m_checkboxes];
    [tab setMenus: m_menus];
    [tab setQuality: [self qualityStops]];
}

-(void) populatePerformanceButton: (NSPopUpButton*) button
{
    [button removeAllItems];
    NSArray* performanceItems = [self performanceItems];
    
    for (int i = 0; i < [performanceItems count]; ++i) {
        PerformanceItem* item = (PerformanceItem*) [performanceItems objectAtIndex:i];
        if (!item)
            continue;
        
        addMenuItem(button, [item title], i);
    }
}

-(void) addParamsToJavaScriptContext: (JavaScriptContext*) context withTab: (ConversionTab*) tab performanceIndex:(int) perfIndex
{
    // Add global params and commands
    [context addParams: m_params];

    // Add params and commands from currently selected checkboxes
    int i = 0;
    for (Checkbox* checkbox in m_checkboxes) {
        int state = [tab checkboxState:i];
        if (state == 0)
            [context addParams: [checkbox uncheckedParams]];
        else if (state == 1)
            [context addParams: [checkbox checkedParams]];
        i++;
    }
    
    // Add params and commands from currently selected menu items
    i = 0;
    for (Menu* menu in m_menus) {
        int state = [tab menuState:i];
        if (state >= 0)
            [context addParams: (NSDictionary*) [[menu itemParams] objectAtIndex:state]];
        i++;
    }
    
    // Add params and commands from currently selected quality stop
    int state = [tab qualityState];
    if (state >= 0 && [m_qualityStops count] > state)
        [context addParams: [(QualityStop*) [m_qualityStops objectAtIndex:state] params]];
    
    // Add params and commands from currently selected performance item
    if (perfIndex >= 0 && [m_performanceItems count] > perfIndex)
        [context addParams: [(PerformanceItem*) [m_performanceItems objectAtIndex:perfIndex] params]];
}

-(void) evaluateScript: (JavaScriptContext*) context withTab: (ConversionTab*) tab performanceIndex:(int) perfIndex
{
    // Evaluate global script
    [context evaluateJavaScript:m_script];

    // Evaluate scripts from currently selected checkboxes
    int i = 0;
    for (Checkbox* checkbox in m_checkboxes) {
        int state = [tab checkboxState:i];
        if (state == 0)
            [context evaluateJavaScript: [checkbox uncheckedScript]];
        else if (state == 1)
            [context evaluateJavaScript: [checkbox checkedScript]];
        i++;
    }
    
    // Evaluate scripts from currently selected menu items
    i = 0;
    for (Menu* menu in m_menus) {
        int state = [tab menuState:i];
        if (state >= 0)
            [context evaluateJavaScript: (NSString*)[[menu itemScripts] objectAtIndex:state]];
        i++;
    }
    
    // Evaluate scripts from currently selected quality stop
    int state = [tab qualityState];
    if (state >= 0 && [m_qualityStops count] > state)
        [context evaluateJavaScript: [(QualityStop*) [m_qualityStops objectAtIndex:state] script]];
    
    // Evaluate scripts from currently selected performance item
    if (perfIndex >= 0 && [m_performanceItems count] > perfIndex)
        [context evaluateJavaScript: [(PerformanceItem*) [m_performanceItems objectAtIndex:perfIndex] script]];
}

-(NSString*) replaceParams:(NSString*) recipeString withContext: (JavaScriptContext*) context
{
    NSString* inputString = recipeString;
    NSMutableString* outputString = [[NSMutableString alloc] init];
    BOOL didSubstitute = YES;
    
    while (didSubstitute) {
       didSubstitute = NO;
       
        NSArray* array = [inputString componentsSeparatedByString:@"$"];
        [outputString setString:[array objectAtIndex:0]];
        
        BOOL firstTime = YES;
        BOOL skipNext = NO;
         
        for (NSString* s in array) {
            if (firstTime) {
                firstTime = NO;
                continue;
            }
                
            if (skipNext) {
                [outputString appendString:s];
                skipNext = NO;
                continue;
            }
                
            // if s is of 0 length, it means there is a $$ sequence, in which case we output it as a literal $
            // But we can't do that yet, because we would catch it as a substitution on the next pass. So we leave
            // it doubled for now
            if ([s length] == 0) {
                skipNext = YES;
                [outputString appendString:@"$$"];
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
                // pick out param to next space
                NSRange range = [s rangeOfString: @" "];
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
            NSString* substitution = [context stringParamForKey: param];
            if (substitution)
                [outputString appendString:substitution];
            [outputString appendString:other];
        }
        
        inputString = outputString;
    }
    
    // All done substituting, now replace $$ with $
    NSArray* array = [inputString componentsSeparatedByString:@"$$"];
    [outputString setString:@""];
    BOOL firstTime = YES;
    
    for (NSString* s in array) {
        if (!firstTime)
            [outputString appendString:@"$"];
        else
            firstTime = NO;
        [outputString appendString: s];
    }
    
    return outputString;
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
    [m_defaultDevice retain];
    
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
    [m_currentDevice populateTabView: m_conversionParamsTabView];
    [m_currentDevice populatePerformanceButton: m_performanceButton];
    
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
    [m_currentDevice populateTabView: m_conversionParamsTabView];
    [m_currentDevice populatePerformanceButton: m_performanceButton];
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

-(NSString*) recipeWithEnvironment:(NSDictionary*) env transcoder:(Transcoder*) transcoder
{
    return [m_currentDevice recipeWithTabView:m_conversionParamsTabView performanceIndex:[m_performanceButton indexOfSelectedItem] environment:env transcoder:transcoder];
}

@end
