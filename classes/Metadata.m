//
//  Metadata.m
//  VideoMonkey
//
//  Created by Chris Marrin on 4/2/2009.
//  Copyright 2008 Apple. All rights reserved.
//

#import <Quartz/Quartz.h>

#import "Metadata.h"
#import "Transcoder.h"

// Implementation of the IKImageBrowserItem protocol
@interface ImageBrowserItem : NSObject {
    NSString* m_path;
    NSImage* m_image;
    NSSize m_originalSize;
}

+(ImageBrowserItem*) imageBrowserItemWithPath:(NSString*) path;

@end

@implementation ImageBrowserItem

+(ImageBrowserItem*) imageBrowserItemWithPath:(NSString*) path
{
    ImageBrowserItem* item = [[ImageBrowserItem alloc] init];
    item->m_path = [path retain];
    item->m_image = [[NSImage alloc] initWithContentsOfFile:item->m_path];
    item->m_originalSize = [item->m_image size];
    [item->m_image setSize: NSMakeSize(100,100)];
    return item;
}

-(NSString *) imageRepresentationType
{
    return IKImageBrowserPathRepresentationType;
}
 
-(id) imageRepresentation
{
    return m_path;
}
 
-(NSString *) imageUID
{
    return m_path;
}

-(NSNumber*) checked
{
    return [NSNumber numberWithBool:YES];
}

-(NSImage*) sourceIcon
{
    NSString* path = [[NSBundle mainBundle] pathForResource:@"itunesfile" ofType:@"png"];
    return [[NSImage alloc] initWithContentsOfFile:path];
}

-(NSImage*) image
{
    return [[NSImage alloc] initWithContentsOfFile:m_path];
}

@end

@implementation Metadata

-(void) processFinishEncode: (NSNotification*) note
{
    int status = [m_task terminationStatus];
    if (status)
        [m_transcoder log: @"ERROR reading metadata for %@:%d", m_transcoder.inputFileInfo.filename, status];
        
    // we always need a 'stik' value - defaults to Movie
    if (![m_inputDictionary valueForKey:@"stik"])
        [m_inputDictionary setValue:@"Movie" forKey:@"stik"];
}

-(void) processResponse: (NSString*) response
{
    // Ignore lines not starting with 'Atom'
    if (![response hasPrefix:@"Atom "])
        return;
        
    // parse out the atom and value
    NSMutableArray* array = [NSMutableArray arrayWithArray:[response componentsSeparatedByString:@":"]];
    NSArray* atomArray = [[array objectAtIndex:0] componentsSeparatedByString:@" "];
    NSString* atom = [[atomArray objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
    [array removeObjectAtIndex:0];
    NSString* value = [[array componentsJoinedByString:@":"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    // if this is an iTunes reverseDNS tag, parse that out
    if ([atom isEqualToString:@"----"])
        atom = [[atomArray objectAtIndex:2] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[]"]];
        
    // extract the content rating if this is iTunEXTC (and simplify atom name)
    if ([atom isEqualToString:@"com.apple.iTunes;iTunEXTC"]) {
        NSArray* valueArray = [value componentsSeparatedByString:@"|"];
        value = [valueArray objectAtIndex:1];
        atom = @"iTunEXTC";
    }
    
    // keypaths can't have special characters, so change things like '©' to '__'
    NSArray* legalArray = [atom componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]];
    atom = [legalArray componentsJoinedByString:@"__"];
    
    // Handle special values
    if ([atom isEqualToString:@"__day"]) {
        // split out year, month, day
        NSArray* dayArray = [value componentsSeparatedByString:@"-"];
        if ([dayArray count] > 0)
            [m_inputDictionary setValue:[[NSNumber numberWithInt:[[dayArray objectAtIndex:0] intValue]] stringValue] forKey:@"__day_year"];
        if ([dayArray count] > 1)
            [m_inputDictionary setValue:[[NSNumber numberWithInt:[[dayArray objectAtIndex:1] intValue]] stringValue] forKey:@"__day_month"];
        if ([dayArray count] > 2)
            [m_inputDictionary setValue:[[NSNumber numberWithInt:[[dayArray objectAtIndex:2] intValue]] stringValue] forKey:@"__day_day"];
    }
    
    // handle artwork
    if ([atom isEqualToString:@"covr"])
        m_numArtwork = [[[value componentsSeparatedByString:@" "] objectAtIndex:0] intValue];
    else
        [m_inputDictionary setValue:value forKey:atom];
}

-(void) processRead: (NSNotification*) note
{
    if (![[note name] isEqualToString:NSFileHandleReadCompletionNotification])
        return;

	NSData	*data = [[note userInfo] objectForKey:NSFileHandleNotificationDataItem];
	
	if([data length]) {
		NSString* string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
        
        NSArray* components = [string componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\r\n"]];
        int i;
        assert([components count] > 0);
        for (i = 0; i < [components count]-1; ++i) {
            [m_buffer appendString:[components objectAtIndex:i]];
            
            // process string
            [self processResponse: m_buffer];
            
            // clear string
            [m_buffer setString: @""];
        }
        
        // if string ends in \n, it is complete, so send it too.
        if ([string hasSuffix:@"\n"] || [string hasSuffix:@"\r"]) {
            [m_buffer appendString:[components objectAtIndex:[components count]-1]];
            [self processResponse: m_buffer];
            [m_buffer setString: @""];
        }
        else {
            // put remaining component in m_buffer for next time
            [m_buffer setString: [components objectAtIndex:[components count]-1]];
        }
        
        // read another buffer
		[[note object] readInBackgroundAndNotify];
    }
}

-(void) readMetadata:(NSString*) filename
{
    m_inputDictionary = [[NSMutableDictionary alloc] init];
    
    // setup command
    NSString* cmdPath = [NSString stringWithString: [[NSBundle mainBundle] resourcePath]];
    NSString* command = [cmdPath stringByAppendingPathComponent: @"bin/AtomicParsley"];

    // setup args
    NSArray* args = [NSArray arrayWithObjects: filename, @"-t", nil];
    
    m_task = [[NSTask alloc] init];
    m_messagePipe = [NSPipe pipe];
    
    // execute the command
    [m_task setArguments: args];
    [m_task setLaunchPath: command];
    [m_task setStandardOutput: [m_messagePipe fileHandleForWriting]];
        
    // add notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processFinishEncode:) name:NSTaskDidTerminateNotification object:m_task];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processRead:) name:NSFileHandleReadCompletionNotification object:[m_messagePipe fileHandleForReading]];

    [[m_messagePipe fileHandleForReading] readInBackgroundAndNotify];
    
    [m_task launch];
    [m_task waitUntilExit];
}

+(Metadata*) metadataWithTranscoder: (Transcoder*) transcoder
{
    Metadata* metadata = [[Metadata alloc] init];
    metadata->m_transcoder = transcoder;
    metadata->m_buffer = [[NSMutableString alloc] init];
    metadata->m_task = [[NSTask alloc] init];
    metadata->m_messagePipe = [NSPipe pipe];
    
    [metadata readMetadata: transcoder.inputFileInfo.filename];
    
    return metadata;
}

-(NSString*) valueForKey:(NSString*) key;
{
    if ([key isEqualToString:@"artworkList"]) {
        // for now return a dummy list
        NSString* path1 = [[NSBundle mainBundle] pathForResource:@"itunesfile" ofType:@"png"];
        ImageBrowserItem* item1 = [ImageBrowserItem imageBrowserItemWithPath:path1];
        NSString* path2 = [[NSBundle mainBundle] pathForResource:@"dvd" ofType:@"png"];
        ImageBrowserItem* item2 = [ImageBrowserItem imageBrowserItemWithPath:path2];
        return [NSArray arrayWithObjects:item1, item2, nil];
    }
        
    return [m_inputDictionary valueForKey:key];
}

@end
