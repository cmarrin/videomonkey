//
//  Formatters.m
//  VideoMonkey
//
//  Created by Chris Marrin on 1/20/09.
//  Copyright 2009 Apple. All rights reserved.
//

#import "XMLDocument.h"
#import "AppController.h"

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

@synthesize rootElement = m_rootElement;
@synthesize target = m_target;

-(BOOL) loadDocument:(NSURL*) url withInfo:(NSString*) info
{
    NSError* error;
    NSXMLDocument* document = [[NSXMLDocument alloc] initWithContentsOfURL:url options:0 error:&error];

    NSString* desc = [error localizedDescription];
    
    if ([desc length] != 0) {
        [[AppController instance] log:@"ERROR parsing XML document: %@. %@\n", info, desc];
        return NO;
    }
    
    self.rootElement = [XMLElement elementWithNSXMLElement: [document rootElement]];
    return YES;
}

+(XMLDocument*) xmlDocumentWithContentsOfURL: (NSURL*) url withInfo:(NSString*) info
{
	XMLDocument* doc = [[XMLDocument alloc] init];
    return [doc loadDocument:url withInfo:info] ? doc : nil;
}

-(void) loadDocumentThread:(NSArray*) array
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSURL* url = [array objectAtIndex:0];
    NSString* info = [array objectAtIndex:1];
    [self.target performSelectorOnMainThread:m_selector withObject:[self loadDocument:url withInfo:info] ? self : nil waitUntilDone:NO];
    [pool release];
}

+(XMLDocument*) xmlDocumentWithContentsOfURL: (NSURL*) url  withInfo:(NSString*) info target:(id) target selector:(SEL) selector;
{
	XMLDocument* doc = [[[XMLDocument alloc] init] retain];
    doc.target = target;
    doc->m_selector = selector;
    
    NSArray* array = [NSArray arrayWithObjects:url, info, nil];
    [NSThread detachNewThreadSelector:@selector(loadDocumentThread:) toTarget:doc withObject:array];
    return doc;
}

-(XMLElement*) rootElement
{
    return m_rootElement;
}

@end

