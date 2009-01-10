//
//  JavascriptContext.m
//  VideoMonkey
//
//  Created by Chris Marrin on 1/9/09.
//  Copyright 2009 Apple. All rights reserved.
//

#import "JavascriptContext.h"

@interface NSString (JavaScriptConversion)

	/* convert a JavaScriptCore string into a NSString */
+ (NSString *)stringWithJSString:(JSStringRef)jsStringValue;

	/* return a new JavaScriptCore string value for the string */
- (JSStringRef)jsStringValue;

	/* convert a JavaScriptCore value in a JavaScriptCore context into a NSString. */
+ (NSString *)stringWithJSValue:(JSValueRef)jsValue fromContext:(JSContextRef)ctx;

@end

@implementation NSString (JavaScriptConversion)

	/* convert a JavaScriptCore string into a NSString */
+ (NSString *)stringWithJSString:(JSStringRef)jsStringValue {

		/* as a class method we return an autoreleased NSString. */
	return [ ( (NSString *) JSStringCopyCFString( kCFAllocatorDefault, jsStringValue ) ) autorelease ];
}


	/* return a new JavaScriptCore string value for the string */
- (JSStringRef)jsStringValue {
	return JSStringCreateWithCFString( (CFStringRef) self );
}


	/* convert a JavaScriptCore value in a JavaScriptCore context into a NSString. */
+ (NSString *)stringWithJSValue:(JSValueRef)jsValue fromContext:(JSContextRef)ctx {
	NSString* theResult = nil;
	
		/* attempt to copy the value to a JavaScriptCore string. */
	JSStringRef stringValue = JSValueToStringCopy( ctx, jsValue, NULL );
	if ( stringValue != NULL ) {
	
			/* if the copy succeeds, convert the returned JavaScriptCore
			string into an NSString. */
		theResult = [NSString stringWithJSString: stringValue];
		
			/* done with the JavaScriptCore string. */
		JSStringRelease( stringValue );
	}
	return theResult;
}

@end

@implementation JavaScriptObject

+(JavaScriptObject*) javaScriptObject: (JavaScriptContext*) ctx withJSObject:(JSObjectRef) obj;
{
    JavaScriptObject* ret = [[JavaScriptObject alloc] init];
    ret->m_context = [ctx retain];
    
    if (!obj)
        obj = JSContextGetGlobalObject([ret->m_context jsContext]);
        
    ret->m_jsObject = obj;
    JSValueProtect([ret->m_context jsContext], ret->m_jsObject);
    
    return ret;
}

- (void)dealloc
{
    JSValueUnprotect([m_context jsContext], m_jsObject);
    [m_context release];
    [super dealloc];
}

-(JSObjectRef) jsObject
{
    return m_jsObject;
}

@end

@implementation JavaScriptContext

- (id)init
{
	if ((self = [super init]) != nil) {
		m_jsContext = JSGlobalContextCreate(NULL);
        
        m_globalObject = [JavaScriptObject javaScriptObject: self withJSObject:JSContextGetGlobalObject(m_jsContext)];
    
        // add param object
        [self evaluateJavaScript:@"param = { }"];
    }
	return self;
}

- (void)dealloc
{
    if (m_jsContext)
        JSGlobalContextRelease(m_jsContext);
    m_jsContext = NULL;
	[super dealloc];
}





	/* -vsCallJSFunction:withParameters: is much like the vsprintf function in that
	it receives a va_list rather than a variable length argument list.  This
	is a simple utility for calling JavaScript functions in a JavaScriptContext
	that is called by the other call*JSFunction methods in this file to do the
	actual work.  The caller provides a function name and the parameter va_list,
	and -vsCallJSFunction:withParameters: uses those to call the function in the
	JavaScriptCore context.  Only NSString and NSNumber values can be provided
	as parameters.  The result returned is the same as the value returned by
	the function,  or NULL if an error occured.  */
- (JSValueRef)vsCallJSFunction:(NSString *)name withArg:(id)firstParameter andArgList:(va_list)args {

		/* default result */
	JSValueRef theResult = NULL;
	
			/* try to find the named function defined as a property on the global object */
	JSStringRef functionNameString = [name jsStringValue];
	if ( functionNameString != NULL ) {

			/* retrieve the function object from the global object. */
		JSValueRef jsFunctionObject =
				JSObjectGetProperty( m_jsContext,
						JSContextGetGlobalObject( m_jsContext ), functionNameString, NULL );
				
			/* if we found a property, verify that it's a function */
		if ( ( jsFunctionObject != NULL ) && JSValueIsObject( m_jsContext, jsFunctionObject ) ) {
			const size_t kMaxArgCount = 20;
			id nthID;
			BOOL argsOK = YES;
			size_t argumentCount = 0;
			JSValueRef arguments[kMaxArgCount];
			
				/* convert the function reference to a function object */
			JSObjectRef jsFunction = JSValueToObject( m_jsContext, jsFunctionObject, NULL );
				
				/* index through the parameters until we find a nil one,
				or exceed our maximu argument count */
			for ( nthID = firstParameter; 
				argsOK && ( nthID != nil ) && ( argumentCount < kMaxArgCount );
				nthID = va_arg( args, id ) ) {
			
				if ( [nthID isKindOfClass: [NSNumber class]] ) {
				
					arguments[argumentCount++] = JSValueMakeNumber( m_jsContext, [nthID doubleValue] );
							
				} else if ( [nthID isKindOfClass: [NSString class]] ) {
				
					JSStringRef argString = [nthID jsStringValue];
					if ( argString != NULL ) {
						arguments[argumentCount++] = 
								JSValueMakeString( m_jsContext, argString );
						JSStringRelease( argString );
					} else {
						argsOK = NO;
					}
				} else {
				
					NSLog(@"bad parameter type for item %d (%@) in vsCallJSFunction:withArg:andArgList:",
						argumentCount, nthID);
					argsOK = NO; /* unknown parameter type */
				}
			}
				/* call through to the function */
			if ( argsOK ) {
				theResult = JSObjectCallAsFunction(m_jsContext, jsFunction,
										NULL, argumentCount, arguments, NULL);
			}
		}
				
		JSStringRelease( functionNameString );
	}
	return theResult;
}

		
		
	/* -callJSFunction:withParameters: is a simple utility for calling JavaScript
	functions in a JavaScriptContext.  The caller provides a function
	name and a nil terminated list of parameters, and callJSFunction
	uses those to call the function in the JavaScriptCore context.  Only
	NSString and NSNumber values can be provided as parameters.  The
	result returned is the same as the value returned by the function,
	or NULL if an error occured.  */
- (JSValueRef)callJSFunction:(NSString *)name withParameters:(id)firstParameter,... {
	JSValueRef theResult = NULL;
	va_list args;

	va_start( args, firstParameter );
	theResult = [self vsCallJSFunction: name withArg: firstParameter andArgList: args];
	va_end( args );

	return theResult;
}



	/* -callBooleanJSFunction:withParameters: is similar to -callJSFunction:withParameters:
	except it returns a BOOL result.  It will return NO if the function is not
	defined in the context or if an error occurs. */
- (BOOL)callBooleanFunction:(NSString *)name withParameters:(id)firstParameter,... {
	BOOL theResult;
	va_list args;

		/* call the function */
	va_start( args, firstParameter );
	JSValueRef functionResult = [self vsCallJSFunction: name withArg: firstParameter andArgList: args];
	va_end( args );

		/* convert the result, if there is one, into the objective-c type */
	if ( ( functionResult != NULL ) && JSValueIsBoolean( m_jsContext, functionResult ) ) {
		 theResult = ( JSValueToBoolean(m_jsContext, functionResult ) ? YES : NO );
	} else {
		theResult = NO;
	}
	return theResult;
}



	/* -callNumericJSFunction:withParameters: is similar to -callJSFunction:withParameters:
	except it returns a NSNumber * result.  It will return nil if the function is not
	defined in the context, if the result returned by the function cannot be converted
	into a number, or if an error occurs. */
- (NSNumber *)callNumberFunction:(NSString*)name withParameters:(id)firstParameter,... {
	NSNumber *theResult;
	va_list args;

		/* call the function */
	va_start( args, firstParameter );
	JSValueRef functionResult = [self vsCallJSFunction: name withArg: firstParameter andArgList: args];
	va_end( args );

		/* convert the result, if there is one, into the objective-c type */
	if ( ( functionResult != NULL ) && JSValueIsNumber( m_jsContext, functionResult ) ) {
		 theResult = [NSNumber numberWithDouble: JSValueToNumber( m_jsContext, functionResult, NULL )];
	} else {
		theResult = nil;
	}
	return theResult;
}



	/* -callStringJSFunction:withParameters: is similar to -callJSFunction:withParameters:
	except it returns a NSNumber * result.  It will return nil if the function is not
	defined in the context, if the result returned by the function cannot be converted
	into a string,  or if an error occurs. */
- (NSString *)callStringFunction:(NSString *)name withParameters:(id)firstParameter,... {
	NSString *theResult = nil;
	va_list args;

		/* call the function */
	va_start( args, firstParameter );
	JSValueRef functionResult = [self vsCallJSFunction: name withArg: firstParameter andArgList: args];
	va_end( args );

		/* convert the result, if there is one, into the objective-c type */
	if ( functionResult != NULL ) {
	
			/* attempt to convert the result into a NSString */
		theResult = [NSString stringWithJSValue:functionResult fromContext: m_jsContext];
	}
	
	return theResult;
}




	/* -addGlobalObject:ofClass:withPrivateData: adds an object of the given class 
	and name to the global object of the JavaScriptContext.  After this call, scripts
	running in the context will be able to access the object using the name. */
- (void)addGlobalObject:(NSString *)objectName ofClass:(JSClassRef)theClass
			withPrivateData:(void *)theData {
			
		/* create a new object of the given class */
	JSObjectRef theObject = JSObjectMake( m_jsContext, theClass, theData );
	if ( theObject != NULL ) {
			
			/* protect the value so it isn't eligible for garbage collection */
		JSValueProtect( m_jsContext, theObject );
		
			/* convert the name to a JavaScript string */
		JSStringRef objectJSName = [objectName jsStringValue];
		if ( objectJSName != NULL ) {
		
				/* add the object as a property of the context's global object */
			JSObjectSetProperty( m_jsContext, JSContextGetGlobalObject( m_jsContext ),
					objectJSName, theObject, kJSPropertyAttributeReadOnly, NULL );
			
				/* done with our reference to the name */
			JSStringRelease( objectJSName );
		}
	}
}



	/* -addGlobalStringProperty:withValue: adds a string with the given name to the
	global object of the JavaScriptContext.  After this call, scripts running in
	the context will be able to access the string using the name. */
- (void)addGlobalStringProperty:(NSString *)name withValue:(NSString *)theValue {

		/* convert the name to a JavaScript string */
	JSStringRef propertyName = [name jsStringValue];
	if ( propertyName != NULL ) {
	
			/* convert the property value into a JavaScript string */
		JSStringRef propertyValue = [theValue jsStringValue];
		if ( propertyValue != NULL ) {
		
				/* copy the property value into the JavaScript context */
			JSValueRef valueInContext = JSValueMakeString( m_jsContext, propertyValue );
			if ( valueInContext != NULL ) {
			
					/* add the property into the context's global object */
				JSObjectSetProperty( m_jsContext, JSContextGetGlobalObject( m_jsContext ),
						propertyName, valueInContext, kJSPropertyAttributeReadOnly, NULL );
			}
				/* done with our reference to the property value */
			JSStringRelease( propertyValue );
		}
			/* done with our reference to the property name */
		JSStringRelease( propertyName );
	}
}



	/* -addGlobalFunctionProperty:withCallback: adds a function with the given name to the
	global object of the JavaScriptContext.  After this call, scripts running in
	the context will be able to call the function using the name. */
- (void)addGlobalFunctionProperty:(NSString *)name
		withCallback:(JSObjectCallAsFunctionCallback)theFunction {
		
		/* convert the name to a JavaScript string */
	JSStringRef functionName = [name jsStringValue];
	if ( functionName != NULL ) {
			
			/* create a function object in the context with the function pointer. */
		JSObjectRef functionObject =
			JSObjectMakeFunctionWithCallback( m_jsContext, functionName, theFunction );
		if ( functionObject != NULL ) {
		
				/* add the function object as a property of the global object */
			JSObjectSetProperty( m_jsContext, JSContextGetGlobalObject( m_jsContext ),
				functionName, functionObject, kJSPropertyAttributeReadOnly, NULL );
		}
			/* done with our reference to the function name */
		JSStringRelease( functionName );
	}
}



	/* -evaluateJavaScript: evaluates a string containing a JavaScript in the
	JavaScriptCore context and returns the result as a string.  If an error
	occurs or the result returned by the script cannot be converted into a 
	string, then nil is returned. */
- (NSString *)evaluateJavaScript:(NSString *)theJavaScript {

	NSString *resultString = nil;
	
		/* coerce the contents of the script edit text field in the window into
		a string inside of the JavaScript context. */
	JSStringRef scriptJS = [theJavaScript jsStringValue];
	if ( scriptJS != NULL ) {
		
			/* evaluate the string as a JavaScript inside of the JavaScript context. */
		JSValueRef result = JSEvaluateScript( m_jsContext, scriptJS, NULL, NULL, 0, NULL );
		if ( result != NULL) {
		
				/* attempt to convert the result into a NSString */
			resultString = [NSString stringWithJSValue:result fromContext: m_jsContext];
					
		}
			/* done with our reference to the script string */
		JSStringRelease( scriptJS );
	}
	return resultString;
}

-(JavaScriptObject*) objectPropertyInObject: (JavaScriptObject*) obj forKey:(NSString*) key
{
    if (!obj)
        obj = m_globalObject;
	JSStringRef jskey = [key jsStringValue];
    JSValueRef jsValue = JSObjectGetProperty(m_jsContext, [obj jsObject], jskey, NULL);
    return [JavaScriptObject javaScriptObject:self withJSObject:JSValueToObject(m_jsContext, jsValue, NULL)];
}

-(void) setPropertyInObject: (JavaScriptObject*) obj forKey:(NSString*) key toString: (NSString*) string
{
    if (!obj)
        obj = m_globalObject;
	JSStringRef jskey = [key jsStringValue];
    JSObjectSetProperty(m_jsContext, [obj jsObject], jskey, [string jsStringValue], kJSPropertyAttributeNone, NULL);
}

-(void)setStringParam:(NSString*) string forKey:(NSString*)key
{
    JavaScriptObject* params = [self objectPropertyInObject: nil forKey: @"params"];
    [self setPropertyInObject: params forKey: key toString:string];
}

-(NSString*) stringParamForKey:(NSString*)key
{
    // FIXME: need to implement
    return nil;
}

-(JavaScriptObject*) globalObject
{
    return m_globalObject;
}

-(JSContextRef) jsContext
{
    return m_jsContext;
}

@end
