//
//  Formatters.h
//  VideoMonkey
//
//  Created by Chris Marrin on 1/20/09.
//  Copyright 2009 Apple. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface XMLElement : NSObject {
    NSArray* m_children;
    NSDictionary* m_attributes;
    NSString* m_name;
}

-(NSString*) stringAttribute:(NSString*) name;
-(double) doubleAttribute:(NSString*) name;
-(BOOL) boolAttribute:(NSString*) name withDefault:(BOOL) defaultValue;
-(NSString*) content;
-(NSString*) name;

-(NSArray*) elementsForName:(NSString*) name;
-(XMLElement*) lastElementForName:(NSString*) name;

@end

@interface XMLDocument : NSObject {
    XMLElement* m_rootElement;
}

+(XMLDocument*) xmlDocumentWithContentsOfURL: (NSURL*) url;

-(XMLElement*) rootElement;

@end
