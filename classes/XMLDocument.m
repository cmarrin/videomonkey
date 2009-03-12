//
//  Formatters.m
//  VideoMonkey
//
//  Created by Chris Marrin on 1/20/09.
//  Copyright 2009 Apple. All rights reserved.
//

#import "XMLDocument.h"






static NSString* stringAttribute(NSXMLElement* element, NSString* name)
{
    NSXMLNode* node = [element attributeForName:name];
    return node ? [node stringValue] : @"";
}

static double doubleAttribute(NSXMLElement* element, NSString* name)
{
    return [stringAttribute(element, name) doubleValue];
}

static BOOL boolAttribute(NSXMLElement* element, NSString* name, BOOL defaultValue)
{
    NSString* s = stringAttribute(element, name);
    return ([s length] > 0) ? [s boolValue] : defaultValue;
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







@implementation XMLElement

+(XMLElement*) elementWithNSXMLElement:(NSXMLElement*) e
{
    XMLElement* element = [[XMLElement alloc] init];
    element->m_element = e;
    return element;
}

-(NSString*) stringAttribute:(NSString*) name;
{
    NSXMLNode* node = [m_element attributeForName:name];
    return node ? [node stringValue] : @"";
}

-(XMLElement*) findChildElement:(NSString*) name;
{
    // return the LAST element with the passed name (later versions override earlier ones)
    return [XMLElement elementWithNSXMLElement: [[m_element elementsForName:name] lastObject]];
}

@end

@implementation XMLDocument

+(XMLDocument*) xmlDocumentWithContentsOfURL: (NSURL*) url
{
    XMLDocument* doc = [[XMLDocument alloc] init];
    NSError* error;
    doc->m_document = [[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentValidate error:&error];

    NSString* desc = [error localizedDescription];
    
    if ([desc length] != 0) {
        NSRunAlertPanel(@"Error parsing commands.xml", desc, nil, nil, nil);
        return nil;
    }
    
    return doc;
}

-(XMLElement*) rootElement
{
    return [XMLElement elementWithNSXMLElement: [m_document rootElement]];
}

@end

