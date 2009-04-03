//
//  Metadata.m
//  VideoMonkey
//
//  Created by Chris Marrin on 4/2/2009.
//  Copyright 2008 Apple. All rights reserved.
//

#import "Metadata.h"
#import "Transcoder.h"

@implementation Metadata

-(void) processFinishEncode: (NSNotification*) note
{
    int status = [m_task terminationStatus];
    if (status)
        [m_transcoder log: @"ERROR reading metadata for %@:%d", [m_transcoder inputFileName], status];
}

-(void) processResponse: (NSString*) response
{
    // parse out the frame
    //NSRange range = [response rangeOfString: @"frame="];
    //NSString* s = [response substringFromIndex:(range.location + range.length)];
    //double frame = [s doubleValue];
    //double totalFrames = [m_transcoder outputDuration] * [m_transcoder outputVideoFramerate];
    //double percentage = frame / totalFrames;
    
    //[m_transcoder setProgressForCommand: self to: percentage];
    NSLog(@"*** metadata: %@\n", response);
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
    [m_task setStandardError: [m_messagePipe fileHandleForWriting]];
        
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
    
    [metadata readMetadata: [transcoder inputFileName]];
    
    return metadata;
}

@end
