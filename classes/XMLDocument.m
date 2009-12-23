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
    element->m_name = [[e name] retain];
    
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

// This gets all the content for this element, stripping out any interleaved
// elements
-(NSString*) content
{
    NSMutableString* string = [[NSMutableString alloc] init];
    
    for (id obj in m_children) {
        if ([obj isKindOfClass:[NSString class]])
            [string appendString:obj];
    }
    
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
    NSError* error;
    NSXMLDocument* document = [[NSXMLDocument alloc] initWithContentsOfURL:url options:0 error:&error];

    NSString* desc = [error localizedDescription];
    
    if ([desc length] != 0) {
        NSRunAlertPanel([NSString stringWithFormat:@"Error parsing %@", url], desc, nil, nil, nil);
        return nil;
    }
    
	XMLDocument* doc = [[XMLDocument alloc] init];
    doc->m_rootElement = [XMLElement elementWithNSXMLElement: [document rootElement]];
    return doc;
}

+(XMLDocument*) xmlDocumentWithContentsOfURLAsync: (NSURL*) url delegate:(id) delegate
{
	XMLDocument* doc = [[XMLDocument alloc] init];
    doc->m_connection = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:url] delegate:self];
    doc->m_delegate = [delegate retain];
    doc->m_url = [url retain];
    doc->m_response = [[NSMutableData alloc] init];
    return doc;
}

-(XMLElement*) rootElement
{
    return m_rootElement;
}

-(void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [m_response appendData:data];
}

-(void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    assert(connection == m_connection);

    NSRunAlertPanel([NSString stringWithFormat:@"Error loading %@", m_url], [error localizedDescription], nil, nil, nil);
    [m_delegate xmlDocumentComplete:self withStatus: error];
    [m_delegate release];
    m_delegate = 0;
    [m_url release];
    m_url = 0;
    [m_response release];
    m_response = 0;
}

-(void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    assert(connection == m_connection);
    
    // Parse
    NSError* error;
    NSXMLDocument* document = [[NSXMLDocument alloc] initWithData:m_response options:0 error:&error];
    NSString* desc = [error localizedDescription];
    
    if ([desc length] != 0) {
        NSRunAlertPanel([NSString stringWithFormat:@"Error parsing %@", m_url], desc, nil, nil, nil);
        [m_delegate xmlDocumentComplete:self withStatus: error];
    }
    else {
        XMLDocument* doc = [[XMLDocument alloc] init];
        doc->m_rootElement = [XMLElement elementWithNSXMLElement: [document rootElement]];
        [m_delegate xmlDocumentComplete:self withStatus: 0];
    }
    
    [m_delegate release];
    m_delegate = 0;
    [m_url release];
    m_url = 0;
    [m_response release];
    m_response = 0;
}

@end

