//
//  JavascriptContext.h
//  VideoMonkey
//
//  Created by Chris Marrin on 1/9/09.

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

#import <Cocoa/Cocoa.h>
#import <JavaScriptCore/JavaScriptCore.h>

@class JavaScriptContext;

@interface NSString (JavaScriptConversion)

	/* convert a JavaScriptCore string into a NSString */
+ (NSString *)stringWithJSString:(JSStringRef)jsStringValue;

	/* return a new JavaScriptCore string value for the string */
- (JSStringRef)jsStringValue;

	/* convert a JavaScriptCore value in a JavaScriptCore context into a NSString. */
+ (NSString *)stringWithJSValue:(JSValueRef)jsValue fromContext:(JSContextRef)ctx;

@end

@interface JavaScriptObject : NSObject {
    JavaScriptContext* m_context;
	JSObjectRef m_jsObject;
}

@property(retain) JavaScriptContext* context;

+(JavaScriptObject*) javaScriptObject: (JavaScriptContext*) ctx withJSObject:(JSObjectRef) obj;
- (void)dealloc;

-(JSObjectRef) jsObject;

@end

@interface JavaScriptContext : NSObject {
	JSGlobalContextRef m_jsContext;
    JavaScriptObject* m_globalObject;
}

@property(retain) JavaScriptObject* globalObject;

-(id)init;
-(void)dealloc;

-(BOOL)callBooleanFunction:(NSString *)name withParameters:(id)firstParameter,...;
-(NSNumber *)callNumberFunction:(NSString *)name withParameters:(id)firstParameter,...;
-(NSString *)callStringFunction:(NSString *)name withParameters:(id)firstParameter,...;

-(void)addGlobalFunctionProperty:(NSString *)name withCallback:(JSObjectCallAsFunctionCallback)theFunction;
-(void)addGlobalObject:(NSString *)objectName ofClass:(JSClassRef)theClass withPrivateData:(void *)theData;

-(void) setPropertyInObject: (JavaScriptObject*) obj forKey:(NSString*) key toString: (NSString*) string;
-(void) setPropertyInObject: (JavaScriptObject*) obj forKey:(NSString*) key toObject: (JavaScriptObject*) object;
-(JavaScriptObject*) objectPropertyInObject: (JavaScriptObject*) obj forKey:(NSString*) key showError:(BOOL) showError;
-(NSString*) stringPropertyInObject: (JavaScriptObject*) obj forKey:(NSString*) key showError:(BOOL) showError;

-(void)setStringParam:(NSString*) string forKey:(NSString*)key;
-(NSString*) stringParamForKey:(NSString*)key showError:(BOOL) showError;
-(void) addParams: (NSDictionary*) params;

-(NSString *)evaluateJavaScript:(NSString*)theJavaScript;

-(JavaScriptObject*) globalObject;
-(JSContextRef) jsContext;

@end
