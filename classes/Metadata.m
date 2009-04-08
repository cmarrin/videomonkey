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

// Artwork source icons
NSImage* g_sourceInputIcon;
NSImage* g_sourceSearchIcon;
NSImage* g_sourceUserIcon;

// Artwork Item
@interface ArtworkItem : NSObject {
    NSImage* m_image;
    NSImage* m_sourceIcon;
    BOOL m_checked;
}

@property(readwrite) BOOL checked;
@property(readonly) NSImage* sourceIcon;
@property(readonly) NSImage* image;

+(ArtworkItem*) artworkItemWithPath:(NSString*) path sourceIcon:(NSImage*) icon checked:(BOOL) checked;
+(ArtworkItem*) artworkItemWithImage:(NSImage*) image sourceIcon:(NSImage*) icon checked:(BOOL) checked;

@end

@implementation ArtworkItem

@synthesize checked = m_checked;
@synthesize sourceIcon = m_sourceIcon;
@synthesize image = m_image;

+(ArtworkItem*) artworkItemWithPath:(NSString*) path sourceIcon:(NSImage*) icon checked:(BOOL) checked;
{
    NSString* realPath;
    
    // path is passed in without a suffix, try different ones
    realPath = [NSString stringWithFormat:@"%@.png", path];
    NSImage* image = [[NSImage alloc] initWithContentsOfFile:realPath];
    if (!image) {
        realPath = [NSString stringWithFormat:@"%@.jpg", path];
        image = [[NSImage alloc] initWithContentsOfFile:realPath];
    }
    if (!image) {
        realPath = [NSString stringWithFormat:@"%@.tiff", path];
        image = [[NSImage alloc] initWithContentsOfFile:realPath];
    }
    if (!image)
        return nil;
        
    // toss image file
    [[NSFileManager defaultManager] removeFileAtPath:realPath handler:nil];

    return [ArtworkItem artworkItemWithImage:image sourceIcon:icon checked:checked];
}

+(ArtworkItem*) artworkItemWithImage:(NSImage*) image sourceIcon:(NSImage*) icon checked:(BOOL) checked
{
    ArtworkItem* item = [[ArtworkItem alloc] init];
    
    item->m_image = [image retain];
    item->m_sourceIcon = [icon retain];
    item->m_checked = checked;
    return item;
}

@end

typedef enum { INPUT_TAG, SEARCH_TAG, USER_TAG, OUTPUT_TAG } TagType;

// Tag Item
@interface TagItem : NSObject {
    NSString* m_inputValue;
    NSString* m_searchValue;
    NSString* m_userValue;
    NSString* m_outputValue;
    NSString* m_tag;
    TagType m_tagToShow;
}

+(TagItem*) tagItem;

-(void) setValue:(NSString*) value tag:(NSString*) tag type:(TagType) type;

@end

@implementation TagItem

+(TagItem*) tagItem;
{
    TagItem* item = [[TagItem alloc] init];
    item->m_tagToShow = OUTPUT_TAG;
    return item;
}

-(void) setValue:(NSString*) value tag:(NSString*) tag type:(TagType) type;
{
    switch (type) {
        case INPUT_TAG:
            [m_inputValue release];
            m_inputValue = [value retain];
            break;
        case SEARCH_TAG:
            [m_searchValue release];
            m_searchValue = [value retain];
            break;
        case USER_TAG:
            [m_userValue release];
            m_userValue = [value retain];
            break;
    }
    
    [m_tag release];
    m_tag = [tag retain];
    
    if (!m_outputValue)
        m_outputValue = [value retain];
}

-(NSString*) displayValue
{
    switch(m_tagToShow) {
        case INPUT_TAG: return m_inputValue;
        case SEARCH_TAG: return m_searchValue;
        case USER_TAG: return m_userValue;
        default: return m_outputValue;
    }
}

-(BOOL) hasMultipleValues
{
    int count = m_inputValue ? 1 : 0;
    count += m_searchValue ? 1 : 0;
    count += m_userValue ? 1 : 0;
    return count > 1;
}

@end

@implementation Metadata

@synthesize artworkList = m_artworkList;
@synthesize tags = m_tagDictionary;

-(NSImage*) primaryArtwork
{
    // primary is the first checked image
    for (ArtworkItem* item in m_artworkList)
        if ([item checked])
            return [item image];
    return nil;
}

-(void) setPrimaryArtwork:(NSImage*) image
{
    id item = [ArtworkItem artworkItemWithImage:image sourceIcon:g_sourceUserIcon checked:YES];
    [m_artworkList insertObject:item atIndex:0];
    [m_transcoder updateFileInfo];
}

-(id) createArtwork:(NSImage*) image
{
    return [ArtworkItem artworkItemWithImage:image sourceIcon:g_sourceUserIcon checked:YES];
}

-(void) setTagValue:(NSString*) value forKey:(NSString*) key tag:(NSString*) tag type:(TagType) type
{
    TagItem* item = (TagItem*) [m_tagDictionary valueForKey:key];
    if (!item) {
        item = [TagItem tagItem];
        [m_tagDictionary setValue:item forKey:key];
    }
    
    [item setValue:value tag:tag type:type];
}

-(void) processFinishEncode: (NSNotification*) note
{
    int status = [m_task terminationStatus];
    if (status)
        [m_transcoder log: @"ERROR reading metadata for %@:%d", m_transcoder.inputFileInfo.filename, status];
        
    // we always need a 'stik' value - defaults to Movie
    if (![m_tagDictionary valueForKey:@"stik"])
        [self setTagValue:@"Movie" forKey:@"stik" tag:@"stik" type:USER_TAG];
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
    NSString* key = atom;
    [array removeObjectAtIndex:0];
    NSString* value = [[array componentsJoinedByString:@":"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    // if this is an iTunes reverseDNS tag, parse that out
    if ([atom isEqualToString:@"----"])
        atom = [[atomArray objectAtIndex:2] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[]"]];
        
    // extract the content rating and annotation if this is iTunEXTC (and simplify atom name)
    if ([atom isEqualToString:@"com.apple.iTunes;iTunEXTC"] || [atom isEqualToString:@"iTunEXTC"]) {
        NSArray* valueArray = [value componentsSeparatedByString:@"|"];
        value = [valueArray objectAtIndex:3];
        key = @"rating_annotation";
        [self setTagValue:value forKey:key tag:@"rating_annotation" type:INPUT_TAG];
        
        value = [valueArray objectAtIndex:1];
        key = @"rating";
        
    }
    
    // keypaths can't have special characters, so change things like '©' to '__'
    NSArray* legalArray = [key componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]];
    key = [legalArray componentsJoinedByString:@"__"];
    
    // Handle special values
    if ([key isEqualToString:@"__day"]) {
        // split out year, month, day
        NSArray* dayArray = [value componentsSeparatedByString:@"-"];
        if ([dayArray count] > 0)
            [self setTagValue:[[NSNumber numberWithInt:[[dayArray objectAtIndex:0] intValue]] stringValue] forKey:@"__day_year" tag:@"©day" type:INPUT_TAG];
        if ([dayArray count] > 1)
            [self setTagValue:[[NSNumber numberWithInt:[[dayArray objectAtIndex:1] intValue]] stringValue] forKey:@"__day_month" tag:@"©day" type:INPUT_TAG];
        if ([dayArray count] > 2)
            [self setTagValue:[[NSNumber numberWithInt:[[dayArray objectAtIndex:2] intValue]] stringValue] forKey:@"__day_day" tag:@"©day" type:INPUT_TAG];
    }
    
    // handle artwork
    if ([key isEqualToString:@"covr"])
        m_numArtwork = [[[value componentsSeparatedByString:@" "] objectAtIndex:0] intValue];
    else
        [self setTagValue:value forKey:key tag:atom type:INPUT_TAG];
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
    
    // generate tmp file name for Artwork
    NSString* tmpArtworkPath = [NSString stringWithFormat:@"/tmp/%p-VideoMonkey", self];

    // setup args
    NSArray* args = [NSArray arrayWithObjects: filename, @"-t", @"-e", tmpArtworkPath, nil];
    
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
    
    // get artwork
    for (int i = 0; i < m_numArtwork; ++i) {
        ArtworkItem* item = [ArtworkItem artworkItemWithPath:[NSString stringWithFormat:@"%@_artwork_%d", tmpArtworkPath, i+1] sourceIcon:g_sourceInputIcon checked:YES];
        if (item)
            [m_artworkList addObject:item];
    }
}

+(Metadata*) metadataWithTranscoder: (Transcoder*) transcoder
{
    // read in the icons, if needed
    if (!g_sourceInputIcon) {
        NSString* path = [[NSBundle mainBundle] pathForResource:@"tinyitunesfile" ofType:@"png"];
        g_sourceInputIcon = [[NSImage alloc] initWithContentsOfFile:path];
        path = [[NSBundle mainBundle] pathForResource:@"tinyitunesfile" ofType:@"png"];
        g_sourceSearchIcon = [[NSImage alloc] initWithContentsOfFile:path];
        path = [[NSBundle mainBundle] pathForResource:@"tinyitunesfile" ofType:@"png"];
        g_sourceUserIcon = [[NSImage alloc] initWithContentsOfFile:path];
    }
    
    Metadata* metadata = [[Metadata alloc] init];
    metadata->m_transcoder = transcoder;
    metadata->m_buffer = [[NSMutableString alloc] init];
    metadata->m_task = [[NSTask alloc] init];
    metadata->m_messagePipe = [NSPipe pipe];
    metadata->m_tagDictionary = [[NSMutableDictionary alloc] init];
    metadata->m_artworkList = [[NSMutableArray alloc] init];
    
    [metadata readMetadata: transcoder.inputFileInfo.filename];
    
    return metadata;
}

- (id)valueForUndefinedKey:(NSString *)key
{
    NSLog(@"*** Metadata::valueForUndefinedKey:%@\n", key);
    return nil;
}

@end
