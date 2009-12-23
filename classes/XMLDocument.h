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

@class XMLDocument;

@interface AsyncXMLDelegate : NSObject {
}

-(void) xmlDocumentComplete:(XMLDocument*) document withStatus:(NSError*) status;
@end

@interface XMLDocument : NSObject {
    XMLElement* m_rootElement;
    NSURLConnection* m_connection;
    AsyncXMLDelegate* m_delegate;
    NSURL* m_url;
    NSMutableData* m_response;
}

+(XMLDocument*) xmlDocumentWithContentsOfURL: (NSURL*) url;

// When the request is complete, the delegate is sent the xmlDocumentComplete:withStatus:
// message. The first param is the XMLDocument and the second is an NSError status code (nil for ok).
+(XMLDocument*) xmlDocumentWithContentsOfURLAsync: (NSURL*) url delegate:(id) delegate;

-(XMLElement*) rootElement;

@end
