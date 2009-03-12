//
//  Formatters.h
//  VideoMonkey
//
//  Created by Chris Marrin on 1/20/09.
//  Copyright 2009 Apple. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface XMLElement : NSObject {
    NSXMLElement* m_element;
}

-(NSString*) stringAttribute:(NSString*) name;
-(XMLElement*) findChildElement:(NSString*) name;

@end

@interface XMLDocument : NSObject {
    NSXMLDocument* m_document;
}

+(XMLDocument*) xmlDocumentWithContentsOfURL: (NSURL*) url;

-(XMLElement*) rootElement;

@end
