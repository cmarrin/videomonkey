//
//  MetadataSearch.m
//  VideoMonkey
//
//  Created by Chris Marrin on 4/13/09.
//  Copyright 2009 Apple. All rights reserved.
//

#import "MetadataSearch.h"
#import "TVDBMetadataSearcher.h"

@implementation MetadataSearcher

@synthesize foundShowNames = m_foundShowNames;
@synthesize foundShowIds = m_foundShowIds;
@synthesize foundSeasons = m_foundSeasons;
@synthesize foundEpisodes = m_foundEpisodes;

-(BOOL) searchForShow:(NSString*) searchString { return NO; }

@end

@implementation MetadataSearch

@synthesize foundShowNames = m_foundShowNames;
@synthesize foundShowIds = m_foundShowIds;
@synthesize foundSeasons = m_foundSeasons;
@synthesize foundEpisodes = m_foundEpisodes;

-(NSString*) currentShowName
{
    // For now just return the first show
    return (m_foundShowNames && [m_foundShowNames count] > 0) ? [m_foundShowNames objectAtIndex:0] : nil;
}

-(NSNumber*) currentSeason
{
    // For now just return the one we parsed
    return (m_season >= 0) ? [NSNumber numberWithInt:m_season] : nil;
}

-(NSNumber*) currentEpisode
{
    // For now just return the one we parsed
    return (m_episode >= 0) ? [NSNumber numberWithInt:m_episode] : nil;
}

+(MetadataSearch*) metadataSearch
{
    MetadataSearch* metadataSearch = [[MetadataSearch alloc] init];
    metadataSearch->m_searchers = [NSArray arrayWithObjects:
                                    [[TVDBMetadataSearcher alloc] init], 
                                    nil];
    return metadataSearch;
}

static BOOL isValidInteger(NSString* s)
{
    return [[s stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]] length] == 0;
}

-(BOOL) _searchForShows:(NSString*) searchString
{
    for (MetadataSearcher* searcher in m_searchers) {
        if ([searcher searchForShow:searchString]) {
            m_foundShowNames = [searcher.foundShowNames retain];
            m_foundShowIds = [searcher.foundShowIds retain];
            return YES;
        }
    }
    return NO;
}

-(BOOL) search:(NSString*) filename
{
    [m_foundShowNames release];
    m_foundShowNames = nil;
    [m_foundShowIds release];
    m_foundShowIds = nil;
    
    // Format the filename into something that we can search with.
    // Toss the prefix and suffix
    NSString* searchString = [[filename lastPathComponent] stringByDeletingPathExtension];
    
    // Replace anything other than letters and numbers with spaces
    NSMutableArray* array = [NSMutableArray arrayWithArray: [searchString componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]]];
    
    // See if anything looks like SxxEyy
    m_season = -1;
    m_episode = -1;
    
    for (NSString* item in array) {
        item = [item lowercaseString];
        if ([item hasPrefix:@"s"]) {
            item = [item substringFromIndex: 1];
            NSArray* seArray = [item componentsSeparatedByString:@"e"];
            if ([seArray count] == 2 && isValidInteger([seArray objectAtIndex:0]) && isValidInteger([seArray objectAtIndex:1])) {
                m_season = [[seArray objectAtIndex:0] intValue];
                m_episode = [[seArray objectAtIndex:1] intValue];
                break;
            }
        }
    }
    
    // search until we find something
    while ([array count]) {
        if ([self _searchForShows: [array componentsJoinedByString:@" "]])
            return YES;
        
        // remove the last component
        [array removeLastObject];
    }
    
    return NO;
}

- (id)valueForUndefinedKey:(NSString *)key
{
    NSLog(@"*** Metadata::valueForUndefinedKey:%@\n", key);
    return nil;
}

@end
