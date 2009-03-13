//
//  Formatters.m
//  VideoMonkey
//
//  Created by Chris Marrin on 1/20/09.
//  Copyright 2009 Apple. All rights reserved.
//

#import "XMLDocument.h"

@implementation XMLElement

+(XMLElement*) elementWithNSXMLElement:(NSXMLElement*) e
{
    XMLElement* element = [[XMLElement alloc] init];
    
    // Set name
    element->m_name = [NSString stringWithString:[e name]];
    
    // Add the elements and content, in order
    NSArray* kids = [e children];
    NSMutableArray* children = [[NSMutableArray alloc] init];
    
    for (NSXMLNode* node in kids) {
        if ([node kind] == NSXMLTextKind)
            [children addObject:[node stringValue]];
        else if ([node kind] == NSXMLElementKind)
            [children addObject:[XMLElement elementWithNSXMLElement:(NSXMLElement*) node]];
    }
    
    element->m_children = children;
    
    // Add the attributes
    NSArray* a = [e attributes];
    NSMutableDictionary* attributes = [[NSMutableDictionary alloc] init];
    
    for (NSXMLNode* node in a)
        [attributes setValue:[node stringValue] forKey:[node name]];
        
    element->m_attributes = attributes;
    
    return element;
}

-(NSString*) stringAttribute:(NSString*) name;
{
    return (NSString*) [m_attributes valueForKey:name];
}

-(double) doubleAttribute:(NSString*) name
{
    return [[self stringAttribute:name] doubleValue];
}

-(BOOL) boolAttribute:(NSString*) name withDefault:(BOOL) defaultValue;
{
    NSString* s = [self stringAttribute:name];
    return ([s length] > 0) ? [s boolValue] : defaultValue;
}

// For now we assume that the content is in the first child. This is the case
// for simple elements with only text content. For interleaved text and
// elements, it will not work
-(NSString*) content
{
    if ([m_children count] == 0)
        return @"";
    NSString* string = [[m_children objectAtIndex:0] stringValue];
    return [[string stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]] retain];
}

-(NSString*) name
{
    return m_name;
}

-(NSArray*) elementsForName:(NSString*) name
{
    NSMutableArray* array = [[NSMutableArray alloc] init];
    
    for (id child in m_children) {
        if ([child isKindOfClass:[XMLElement class]] && [[child name] isEqualToString:name])
            [array addObject:child];
    }
    
    return array;
}

-(XMLElement*) lastElementForName:(NSString*) name;
{
    XMLElement* foundChild = nil;
    
    for (id child in m_children) {
        if ([child isKindOfClass:[XMLElement class]] && [[child name] isEqualToString:name])
            foundChild = (XMLElement*) child;
    }
    
    return foundChild;
}

@end

@implementation XMLDocument

+(XMLDocument*) xmlDocumentWithContentsOfURL: (NSURL*) url
{
    XMLDocument* doc = [[XMLDocument alloc] init];
    NSError* error;
    NSXMLDocument* document = [[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentValidate error:&error];

    NSString* desc = [error localizedDescription];
    
    if ([desc length] != 0) {
        NSRunAlertPanel(@"Error parsing commands.xml", desc, nil, nil, nil);
        return nil;
    }
    
    doc->m_rootElement = [XMLElement elementWithNSXMLElement: [document rootElement]];
    return doc;
}

-(XMLElement*) rootElement
{
    return m_rootElement;
}

@end

