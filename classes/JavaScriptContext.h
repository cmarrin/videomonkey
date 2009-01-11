//
//  JavascriptContext.h
//  VideoMonkey
//
//  Created by Chris Marrin on 1/9/09.
//  Copyright 2009 Apple. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <JavaScriptCore/JavaScriptCore.h>

@class JavaScriptContext;

@interface JavaScriptObject : NSObject {
    JavaScriptContext* m_context;
	JSObjectRef m_jsObject;
}

+(JavaScriptObject*) javaScriptObject: (JavaScriptContext*) ctx withJSObject:(JSObjectRef) obj;
- (void)dealloc;

-(JSObjectRef) jsObject;

@end

@interface JavaScriptContext : NSObject {
	JSGlobalContextRef m_jsContext;
    JavaScriptObject* m_globalObject;
}

-(id)init;
-(void)dealloc;

-(BOOL)callBooleanFunction:(NSString *)name withParameters:(id)firstParameter,...;
-(NSNumber *)callNumberFunction:(NSString *)name withParameters:(id)firstParameter,...;
-(NSString *)callStringFunction:(NSString *)name withParameters:(id)firstParameter,...;

-(void)addGlobalFunctionProperty:(NSString *)name withCallback:(JSObjectCallAsFunctionCallback)theFunction;

-(void) setPropertyInObject: (JavaScriptObject*) obj forKey:(NSString*) key toString: (NSString*) string;
-(void) setPropertyInObject: (JavaScriptObject*) obj forKey:(NSString*) key toObject: (JavaScriptObject*) object;
-(JavaScriptObject*) objectPropertyInObject: (JavaScriptObject*) obj forKey:(NSString*) key;
-(NSString*) stringPropertyInObject: (JavaScriptObject*) obj forKey:(NSString*) key;

-(void)setStringParam:(NSString*) string forKey:(NSString*)key;
-(NSString*) stringParamForKey:(NSString*)key;
-(void) addParams: (NSDictionary*) params;

-(NSString *)evaluateJavaScript:(NSString*)theJavaScript;

-(JavaScriptObject*) globalObject;
-(JSContextRef) jsContext;

@end