//
//  Metadata.m
//  VideoMonkey
//
//  Created by Chris Marrin on 4/2/2009.
//  Copyright 2008 Apple. All rights reserved.
//

#import <Quartz/Quartz.h>

#import "Metadata.h"
#import "AppController.h"
#import "MetadataSearch.h"
#import "FileInfoPanelController.h"
#import "Transcoder.h"

// Artwork source icons
NSImage* g_sourceInputIcon;
NSImage* g_sourceSearchIcon;
NSImage* g_sourceUserIcon;

// Map from 4 char tag to AtomicParsley tag name
static NSDictionary* g_tagMap = nil;

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
+(ArtworkItem*) artworkItemWithURL:(NSURL*) url sourceIcon:(NSImage*) icon checked:(BOOL) checked;
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

    ArtworkItem* item = [ArtworkItem artworkItemWithImage:image sourceIcon:icon checked:checked];
    [image release];
    return item;
}

+(ArtworkItem*) artworkItemWithURL:(NSURL*) url sourceIcon:(NSImage*) icon checked:(BOOL) checked
{
    NSImage* image = [[NSImage alloc] initWithContentsOfURL:url];
    if (!image)
        return nil;
        
    ArtworkItem* item = [ArtworkItem artworkItemWithImage:image sourceIcon:icon checked:checked];
    [image release];
    return item;
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

// Tag Item
@interface TagItem : NSObject {
    NSString* m_inputValue;
    NSString* m_searchValue;
    NSString* m_userValue;
    NSString* m_outputValue;
    NSString* m_tag;
    TagType m_typeShowing;
}

@property (readonly) NSString* outputValue;
@property (retain) NSString* inputValue;
@property (retain) NSString* searchValue;
@property (copy) NSString* userValue;

+(TagItem*) tagItem;

-(void) setValue:(NSString*) value tag:(NSString*) tag type:(TagType) type;

@end

@implementation TagItem

@synthesize outputValue = m_outputValue;
@synthesize inputValue = m_inputValue;
@synthesize searchValue = m_searchValue;
@synthesize userValue = m_userValue;

+(TagItem*) tagItem;
{
    TagItem* item = [[TagItem alloc] init];
    item->m_typeShowing = OUTPUT_TAG;
    return item;
}

-(NSString*) valueForSource:(TagType) type
{
    switch (type) {
        case INPUT_TAG:
            return self.inputValue;
        case SEARCH_TAG:
            return self.searchValue;
        case USER_TAG:
            return self.userValue;
    }
    return nil;
}

-(void) setValue:(NSString*) value tag:(NSString*) tag type:(TagType) type;
{
    if (value && [value length] == 0)
        value = nil;
        
    switch (type) {
        case INPUT_TAG:
            self.inputValue = value;
            break;
        case SEARCH_TAG:
            self.searchValue = value;
            break;
        case USER_TAG:
            self.userValue = value;
            break;
    }
    
    if (tag) {
        [tag retain];
        [m_tag release];
        m_tag = tag;
    }
    
    // if we are displaying the value we are changing and
    // it is being cleared, we need to select another in this
    // order: USER, SEARCH, INPUT
    if (m_typeShowing == type && !value) {
        if (type != USER_TAG && m_userValue) {
            value = m_userValue;
            type = USER_TAG;
        }
        else if (type != SEARCH_TAG && m_searchValue) {
            value = m_searchValue;
            type = SEARCH_TAG;
        }
        else if (type != INPUT_TAG && m_inputValue) {
            value = m_inputValue;
            type = INPUT_TAG;
        }
    }
    
    [m_outputValue release];
    m_outputValue = [value retain];
    m_typeShowing = type;
}

-(TagType) currentSource { return m_typeShowing; }
-(void) setCurrentSource:(TagType) type
{
    m_typeShowing = type;
    NSString* oldValue = m_outputValue;
    
    switch (type) {
        case INPUT_TAG:     m_outputValue = [m_inputValue retain];  break;
        case SEARCH_TAG:    m_outputValue = [m_searchValue retain];  break;
        case USER_TAG:      m_outputValue = [m_userValue retain];  break;
    }
    
    [oldValue release];
}

-(void) setCurrentSourceIfExists:(TagType) type
{
    if ([self valueForSource:type])
        [self setCurrentSource:type];
}

-(NSString*) displayValue
{
    if ([m_tag isEqualToString:@"stik"] && (!m_outputValue || [m_outputValue length] == 0))
        return @"Movie";
    return m_outputValue;
}

-(void) setDisplayValue:(NSString*) value
{
    if ([value isKindOfClass:[NSAttributedString class]])
        value = [(NSAttributedString*) value string];
    self.userValue = value;
    [self setCurrentSource:USER_TAG];
}

@end

@implementation Metadata

@synthesize artworkList = m_artworkList;
@synthesize tags = m_tagDictionary;
@synthesize search = m_search;
@synthesize rootFilename = m_rootFilename;

-(BOOL) canWriteMetadataToInputFile
{
    return [[m_transcoder inputFileInfo].format isEqualToString:@"MPEG-4"] &&
        [[NSFileManager defaultManager] isWritableFileAtPath:[m_transcoder inputFileInfo].filename];
}

-(BOOL) canWriteMetadataToOutputFile
{
    return [[m_transcoder inputFileInfo].format isEqualToString:@"MPEG-4"] &&
        [[NSFileManager defaultManager] isWritableFileAtPath:[m_transcoder outputFileInfo].filename];
}

-(BOOL) canWriteMetadataForAllInputFiles
{
    for (Transcoder* transcoder in [m_transcoder.fileInfoPanelController.fileListController arrangedObjects])
        if (![[transcoder metadata] canWriteMetadataToInputFile])
            return NO;
    return YES;
}

-(BOOL) canWriteMetadataForAllOutputFiles
{
    for (Transcoder* transcoder in [m_transcoder.fileInfoPanelController.fileListController arrangedObjects])
        if (![[transcoder metadata] canWriteMetadataToOutputFile])
            return NO;
    return YES;
}

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
    // Make sure this image is not already in the list
    for (ArtworkItem* item in m_artworkList)
        if ([item image] == image)
            return;
    
    id item = [ArtworkItem artworkItemWithImage:image sourceIcon:g_sourceUserIcon checked:YES];
    [m_artworkList insertObject:item atIndex:0];
    [m_transcoder updateFileInfo];
}

-(void) uncheckAllArtwork
{
    for (ArtworkItem* item in m_artworkList)
        item.checked = NO;
    [m_transcoder updateFileInfo];
}

-(id) createArtwork:(NSImage*) image
{
    return [ArtworkItem artworkItemWithImage:image sourceIcon:g_sourceUserIcon checked:YES];
}

-(void) setTagValue:(NSString*) value forKey:(NSString*) key type:(TagType) type
{
    TagItem* item = (TagItem*) [m_tagDictionary valueForKey:key];
    if (!item) {
        item = [TagItem tagItem];
        [m_tagDictionary setValue:item forKey:key];
    }
    
    [item setValue:value tag:key type:type];
}

-(void) processFinishReadMetadata: (NSNotification*) note
{
    m_searchSucceeded = [m_task terminationStatus] == 0;
}

-(NSString*) handleTrackOrDisk:(NSString*) value totalKey:(NSString*) totalKey
{
    NSArray* array = [value componentsSeparatedByString:@" of "];
    if ([array count] < 2)
        array = [value componentsSeparatedByString:@"/"];
    if ([array count] > 1) {
        [self setTagValue:[[NSNumber numberWithInt:[[array objectAtIndex:1] intValue]] stringValue] forKey:totalKey type:INPUT_TAG];
        value = [[NSNumber numberWithInt:[[array objectAtIndex:0] intValue]] stringValue];
    }
    return value;
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
        
    // extract the content rating and annotation if this is iTunEXTC (and simplify atom name)
    if ([atom isEqualToString:@"com.apple.iTunes;iTunEXTC"] || [atom isEqualToString:@"iTunEXTC"]) {
        NSArray* valueArray = [value componentsSeparatedByString:@"|"];
        
        // set the annotation
        value = [valueArray objectAtIndex:3];
        [self setTagValue:value forKey:@"rating_annotation" type:INPUT_TAG];
    
        // prep the rating
        value = [valueArray objectAtIndex:1];
        atom = @"iTunEXTC";
    }
    
    // map the atom to the tag name
    NSString* replacementAtom = [g_tagMap valueForKey:atom];
    
    // ignore atoms we don't understand
    if (!replacementAtom)
        return;
    
    // handle artwork
    if ([replacementAtom isEqualToString:@"artwork"])
        m_numArtwork = [[[value componentsSeparatedByString:@" "] objectAtIndex:0] intValue];
    else {
        // handle ldes and desc, with a preference for ldes
        if ([replacementAtom isEqualToString:@"description"]) {
            NSString* currentValue = [[m_tagDictionary valueForKey:@"description"] inputValue];
            
            // If we already have a current value, we will replace it only if
            // we have a non-empty new value and this is the 'ldes' atom
            if (currentValue && [currentValue length] > 0 && ![atom isEqualToString:@"ldes"])
                return;
        }
        
        [self setTagValue:value forKey:replacementAtom type:INPUT_TAG];
    }
}

-(void) processData: (NSData*) data
{
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
    m_searchSucceeded = YES;
    
    // execute the command
    [m_task setArguments: args];
    [m_task setLaunchPath: command];
    [m_task setStandardOutput: [m_messagePipe fileHandleForWriting]];
        
    // add notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processFinishReadMetadata:) name:NSTaskDidTerminateNotification object:m_task];
    
    [m_task launch];
    [m_task waitUntilExit];
    if (m_searchSucceeded) {
        NSData* data = [[m_messagePipe fileHandleForReading] availableData];
        [self processData:data];
        
        // get artwork
        for (int i = 0; i < m_numArtwork; ++i) {
            ArtworkItem* item = [ArtworkItem artworkItemWithPath:[NSString stringWithFormat:@"%@_artwork_%d", tmpArtworkPath, i+1] sourceIcon:g_sourceInputIcon checked:YES];
            if (item)
                [m_artworkList addObject:item];
        }
    }

    // All the keys in g_tagMap need to be filled in so the user can modify them.
    // When writing out, we will not write keys that have never been set
    for (NSString* key in g_tagMap) {
        id atom = [g_tagMap valueForKey:key];
        if (![m_tagDictionary valueForKey:atom])
            [self setTagValue:@"" forKey:atom type:USER_TAG];
    }
}

- (NSString*) utf8ToASCII:(NSString*) utf8
{
    NSData* asciiData = [utf8 dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    return [[[NSString alloc] initWithData:asciiData encoding:NSASCIIStringEncoding] autorelease];
}

-(NSString*) atomicParsleyParams
{
    NSMutableString* params = [[NSMutableString alloc] init];
    
    for (NSString* key in g_tagMap) {
        NSString* param = [g_tagMap valueForKey: key];
        NSString* value = [[m_tagDictionary valueForKey: param] outputValue];
        
        // handle special cases
        if ([param isEqualToString:@"artwork"])
            continue;
            
        // escape all the quotes
        value = value ? [value stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""] : @"";
        
        // Get rid of all non-ascii
        value = [self utf8ToASCII:value];
        [params appendString:[NSString stringWithFormat:@" --%@ \"%@\"", param, value]];
    }
    
    // write out temp artwork
    NSString* tmpArtworkPath = [NSString stringWithFormat:@"/tmp/AtomicParlsleyArtwork_%p", self];
    int i = 0;
    
    // remove old artwork
    [params appendFormat:@" --artwork REMOVE_ALL"];
    
    for (ArtworkItem* artwork in m_artworkList) {
        if ([artwork checked]) {
            NSString* filename = [NSString stringWithFormat:@"%@_%d.jpg", tmpArtworkPath, i];
            NSBitmapImageRep* rep = [NSBitmapImageRep imageRepWithData:[[artwork image] TIFFRepresentation]];
            [[rep representationUsingType:NSJPEGFileType properties:nil] writeToFile: filename atomically: YES];
        
            // write the param
            [params appendFormat:@" --artwork %@", filename];
        }
        ++i;
    }
    return params;
}

-(void) cleanupAfterMetadataWrite
{
    NSString* tmpArtworkPath = [NSString stringWithFormat:@"/tmp/AtomicParlsleyArtwork_%p", self];
    int i = 0;

    for (ArtworkItem* artwork in m_artworkList) {
        if ([artwork checked]) {
            NSString* filename = [NSString stringWithFormat:@"%@_%d.jpg", tmpArtworkPath, i++];
            [[NSFileManager defaultManager] removeFileAtPath:filename handler:nil];
        }
    }
}

-(NSString*) metadataCommand:(NSString*) filename
{
    // Only write if we have params
    NSString* atomicParsleyParams = [self atomicParsleyParams];
    if (!atomicParsleyParams || [atomicParsleyParams length] == 0)
        return @"";
        
    // setup command
    NSString* cmdPath = [NSString stringWithString: [[NSBundle mainBundle] resourcePath]];
    NSString* command = [NSString stringWithFormat:@"%@ \"%@\" -W %@", 
                            [cmdPath stringByAppendingPathComponent: @"bin/AtomicParsley"],
                            filename,
                            atomicParsleyParams];
    return command;
}

-(void) setMetadataSource:(TagType) type
{
    for (NSString* key in m_tagDictionary)
        [[m_tagDictionary valueForKey:key] setCurrentSourceIfExists:type];
}

-(void) loadSearchMetadata:(NSDictionary*) dictionary success:(BOOL) success
{
    // Tell the FileInfoPanelController we've finished a search
    [[m_transcoder fileInfoPanelController] finishMetadataSearch:success];

    // If the dictionary is nil, the loaded metadata probably didn't have the requested season or episode
    if (!dictionary && !success) {
        [[AppController instance] log: [NSString stringWithFormat:@"WARNING:No appropriate metadata found for '%@'\n", m_rootFilename]];
        return;
    }

    // clear all existing search metadata
    for (NSString* key in m_tagDictionary) 
        [[m_tagDictionary valueForKey:key] setValue:nil tag:nil type:SEARCH_TAG];
        
    for (int i = 0; i < [m_artworkList count]; ) {
        if ([[m_artworkList objectAtIndex:i] sourceIcon] == g_sourceSearchIcon)
            [m_artworkList removeObjectAtIndex:i];
        else
            ++i;
    }
        
    for (NSString* key in g_tagMap) {
        NSString* param = [g_tagMap valueForKey: key];
        if ([param isEqualToString:@"artwork"]) {
            NSArray* artwork = [dictionary valueForKey: param];

            for (NSString* path in artwork) {
                NSURL* url = [NSURL URLWithString:path];
                ArtworkItem* item = [ArtworkItem artworkItemWithURL:url sourceIcon:g_sourceSearchIcon checked:NO];
                if (item)
                    [m_artworkList addObject:item];
            }
            
            // select one if none are selected
            if ([m_artworkList count] > 0 && ![self primaryArtwork])
                [[m_artworkList objectAtIndex:0] setChecked:YES];
        }
        else {
            NSString* value = [dictionary valueForKey: param];
            [self setTagValue:value forKey:param type:SEARCH_TAG];
        }
    }
    
    // Get the data to be reevaluated
    [m_transcoder updateFileInfo];
}

+(Metadata*) metadataWithTranscoder: (Transcoder*) transcoder
{
    // init the tag map, if needed
    if (!g_tagMap)
        g_tagMap = [[NSDictionary dictionaryWithObjectsAndKeys:
            @"title",       	@"©nam", 
            @"TVShowName",  	@"tvsh", 
            @"TVEpisode",   	@"tven", 
            @"TVEpisodeNum",	@"tves", 
            @"TVSeasonNum", 	@"tvsn", 
            @"tracknum",    	@"trkn", 
            @"disk",        	@"disk", 
            @"description", 	@"desc",    // Use desc or ldes, whichever exists, prefer ldes
            @"description", 	@"ldes", 
            @"year",        	@"©day", 
            @"stik",        	@"stik", 
            @"advisory",    	@"rtng",
            @"comment",     	@"©cmt", 
            @"album",       	@"©alb", 
            @"artist",      	@"©ART", 
            @"albumArtist", 	@"aART", 
            @"copyright",   	@"cprt", 
            @"TVNetwork",   	@"tvnn", 
            @"encodingTool",	@"©too", 
            @"genre",       	@"gnre", 
            @"contentRating",	@"iTunEXTC",	// you actually need to go: --rDNSatom "<org>|<rating>|<rating num>|<annotation>" name=iTunEXTC domain=com.apple.iTunes
            @"artwork", 	  	@"covr", 		// with a full path, use multiples for more than one image
            nil ] retain];
                    
    // read in the icons, if needed
    if (!g_sourceInputIcon) {
        NSString* path = [[NSBundle mainBundle] pathForResource:@"tinyitunesfile" ofType:@"png"];
        g_sourceInputIcon = [[NSImage alloc] initWithContentsOfFile:path];
        path = [[NSBundle mainBundle] pathForResource:@"tinyspotlight" ofType:@"png"];
        g_sourceSearchIcon = [[NSImage alloc] initWithContentsOfFile:path];
        path = [[NSBundle mainBundle] pathForResource:@"tinypencil" ofType:@"png"];
        g_sourceUserIcon = [[NSImage alloc] initWithContentsOfFile:path];
    }
    
    Metadata* metadata = [[Metadata alloc] init];
    metadata->m_transcoder = transcoder;
    metadata->m_buffer = [[NSMutableString alloc] init];
    metadata->m_task = [[NSTask alloc] init];
    metadata->m_messagePipe = [NSPipe pipe];
    metadata->m_tagDictionary = [[NSMutableDictionary alloc] init];
    metadata->m_artworkList = [[NSMutableArray alloc] init];
    metadata->m_rootFilename = [[[transcoder.inputFileInfo.filename lastPathComponent] stringByDeletingPathExtension] retain];
    
    // read the input metadata (this also creates the tagDictionary)
    [metadata readMetadata: transcoder.inputFileInfo.filename];
    
    // setup the bindings to the metadata panel
    [metadata->m_transcoder.fileInfoPanelController.metadataPanel setupMetadataPanelBindings];
    metadata->m_search = [MetadataSearch metadataSearch:metadata];
    
    return metadata;
}

-(void) searchWithString:(NSString*) string
{
    // Tell the FileInfoPanelController we've started a search
    [[m_transcoder fileInfoPanelController] startMetadataSearch];
    
    [m_search searchWithString:string filename:m_rootFilename];
}

-(void) searchAgain
{
    // Tell the FileInfoPanelController we've started a search
    [[m_transcoder fileInfoPanelController] startMetadataSearch];
    
    // If we have a TVShowName or title, use that for the search, otherwise use the filename
    NSString* value = [[m_tagDictionary valueForKey:@"TVShowName"] valueForSource:INPUT_TAG];
    
    if (value && [value length] > 0)
        [m_search searchWithString:value filename:m_rootFilename];
    else {
        value = [[m_tagDictionary valueForKey:@"title"] valueForSource:INPUT_TAG];
        if (value && [value length] > 0)
            [m_search searchWithString:value filename:m_rootFilename];
        else {
            [m_search searchWithFilename:m_transcoder.inputFileInfo.filename];
        }
    }
}

- (id)valueForUndefinedKey:(NSString *)key
{
    NSLog(@"*** Metadata::valueForUndefinedKey:%@\n", key);
    return nil;
}

@end
