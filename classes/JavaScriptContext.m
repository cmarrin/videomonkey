//
//  JavascriptContext.m
//  VideoMonkey
//
//  Created by Chris Marrin on 1/9/09.
//  Copyright 2009 Apple. All rights reserved.
//

#import "JavascriptContext.h"

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

@synthesize context = m_context;

+(JavaScriptObject*) javaScriptObject: (JavaScriptContext*) ctx withJSObject:(JSObjectRef) obj;
{
    JavaScriptObject* ret = [[[JavaScriptObject alloc] init] autorelease];
    ret.context = ctx;
    
    if (!obj)
        obj = JSContextGetGlobalObject([ret.context jsContext]);
        
    ret->m_jsObject = obj;
    JSValueProtect([ret.context jsContext], ret->m_jsObject);
    
    return ret;
}

+(JavaScriptObject*) javaScriptObject: (JavaScriptContext*) ctx withJSValue:(JSValueRef) value;
{
    return [JavaScriptObject javaScriptObject: ctx withJSObject: JSValueToObject([ctx jsContext], value, NULL)];
}

- (void)dealloc
{
    JSValueUnprotect([m_context jsContext], m_jsObject);
    [super dealloc];
}

-(JSObjectRef) jsObject
{
    return m_jsObject;
}

@end

@implementation JavaScriptContext

@synthesize globalObject = m_globalObject;

- (id)init
{
	if ((self = [super init]) != nil) {
		m_jsContext = JSGlobalContextCreate(NULL);
        
        self.globalObject = [JavaScriptObject javaScriptObject: self withJSObject:JSContextGetGlobalObject(m_jsContext)];
    
        // add param object
        [self evaluateJavaScript:@"params = { }"];
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

-(void) showSyntaxError:(JSValueRef) error forScript:(NSString*) script
{
    if (!JSValueIsNull(m_jsContext, error)) {
        JavaScriptObject* obj = [JavaScriptObject javaScriptObject:self withJSValue:error];
		JSValueRef line = JSObjectGetProperty(m_jsContext, [obj jsObject], [@"line" jsStringValue], NULL);
        double lineNumber = JSValueToNumber(m_jsContext, line, NULL);
        NSString* errorString = [NSString stringWithJSValue: error fromContext: m_jsContext];
        
        NSString* snippet = script;
        int length = 80;
        if ([script length] > length)
            snippet = [script substringToIndex:length];
        
        NSString* alertString = [NSString stringWithFormat: @"%@ at line %d\n\nWhile parsing script starting with:\n\n%@", errorString, (int) lineNumber, snippet];
        NSRunAlertPanel(@"JavaScript error in evaluation", alertString, nil, nil, nil);
    }
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
- (void)addGlobalObject:(NSString *)objectName ofClass:(JSClassRef)theClass withPrivateData:(void *)theData
{
    if (theClass == NULL) {
        JSClassDefinition definition = kJSClassDefinitionEmpty;
        theClass = JSClassCreate(&definition);
    }

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
- (NSString *) evaluateJavaScript:(NSString *)theJavaScript {

	NSString *resultString = nil;
	
    // coerce the contents of the script edit text field in the window into a string inside of the JavaScript context.
	JSStringRef scriptJS = [theJavaScript jsStringValue];
	if (scriptJS != NULL) {
        /* evaluate the string as a JavaScript inside of the JavaScript context. */
        JSValueRef error = JSValueMakeNull(m_jsContext);

		JSValueRef result = JSEvaluateScript( m_jsContext, scriptJS, NULL, [@"MyScript" jsStringValue], 0, &error );
        
        if (!JSValueIsNull(m_jsContext, error)) {
            [self showSyntaxError: error forScript:(NSString*) theJavaScript];
        }
        else if ( result != NULL)
			resultString = [NSString stringWithJSValue:result fromContext: m_jsContext];

		JSStringRelease(scriptJS);
	}
	return resultString;
}

-(JSValueRef) jsValuePropertyInObject: (JavaScriptObject*) obj forKey:(NSString*) key
{
    if (!obj)
        obj = m_globalObject;
	JSStringRef jskey = [key jsStringValue];
    JSValueRef error = JSValueMakeNull(m_jsContext);
    
    JSValueRef jsValue = JSObjectGetProperty(m_jsContext, [obj jsObject], jskey, &error);

    if (!JSValueIsNull(m_jsContext, error)) {
        NSString* errorString = [NSString stringWithJSValue: error fromContext: m_jsContext];
        NSRunAlertPanel(@"JavaScript error in property get", errorString, nil, nil, nil);
        jsValue = JSValueMakeUndefined(m_jsContext);
    }
    else if (JSValueIsUndefined(m_jsContext, jsValue))
        NSRunAlertPanel(@"JavaScript error in property get", [NSString stringWithFormat:@"Property '%@' does not exist", key], nil, nil, nil);

    JSStringRelease(jskey);
    return jsValue;
}

-(JavaScriptObject*) objectPropertyInObject: (JavaScriptObject*) obj forKey:(NSString*) key
{
    JSValueRef jsValue = [self jsValuePropertyInObject: obj forKey: key];
    if (JSValueIsUndefined(m_jsContext, jsValue))
        return nil;
    return [JavaScriptObject javaScriptObject:self withJSObject:JSValueToObject(m_jsContext, jsValue, NULL)];
}

-(NSString*) stringPropertyInObject: (JavaScriptObject*) obj forKey:(NSString*) key
{
    JSValueRef jsValue = [self jsValuePropertyInObject: obj forKey: key];
    if (JSValueIsUndefined(m_jsContext, jsValue))
        return nil;
    JSStringRef jsstring = JSValueToStringCopy(m_jsContext, jsValue, NULL);
    NSString* string = [[NSString stringWithJSString:jsstring] retain];
    JSStringRelease(jsstring);
    return string;
}

-(void) setPropertyInObject: (JavaScriptObject*) obj forKey:(NSString*) key toJSValue: (JSValueRef) jsValue
{
    if (!obj)
        obj = m_globalObject;
        
	JSStringRef propertyName = [key jsStringValue];
	if (propertyName != NULL) {
        JSObjectSetProperty(m_jsContext, [obj jsObject], propertyName, jsValue, kJSPropertyAttributeNone, NULL);        
		JSStringRelease(propertyName);
	}
}

-(void) setPropertyInObject: (JavaScriptObject*) obj forKey:(NSString*) key toString: (NSString*) string
{
    JSStringRef propertyValue = [string jsStringValue];
    if (propertyValue != NULL) {
        JSValueRef valueInContext = JSValueMakeString( m_jsContext, propertyValue);
        if (valueInContext != NULL)
            [self setPropertyInObject: obj forKey: key toJSValue: valueInContext];
        JSStringRelease(propertyValue);
	}
}

-(void) setPropertyInObject: (JavaScriptObject*) obj forKey:(NSString*) key toObject: (JavaScriptObject*) object
{
    [self setPropertyInObject: obj forKey: key toJSValue: [object jsObject]];
}

-(void)setStringParam:(NSString*) string forKey:(NSString*)key
{
    JavaScriptObject* params = [self objectPropertyInObject: nil forKey: @"params"];
    [self setPropertyInObject: params forKey: key toString:string];
}

-(NSString*) stringParamForKey:(NSString*)key
{
    JavaScriptObject* params = [self objectPropertyInObject: nil forKey: @"params"];
    return [self stringPropertyInObject:params forKey:key];
}

-(void) addParams: (NSDictionary*) params
{
    for (NSString* key in params) {
        NSString* value = (NSString*) [params objectForKey:key];
        if (value)
            [self setStringParam:value forKey:key];
    }
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
