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
-(NSDictionary*) detailsForShow:(int) showId season:(int) season episode:(int) episode { return nil; }

@end

@implementation MetadataSearch

@synthesize foundShowNames = m_foundShowNames;
@synthesize foundShowIds = m_foundShowIds;
@synthesize foundSeasons = m_foundSeasons;
@synthesize foundEpisodes = m_foundEpisodes;
@synthesize parsedSeason = m_season;
@synthesize parsedEpisode = m_episode;

-(NSString*) currentShowName
{
    // For now just return the first show
    return (m_foundShowNames && [m_foundShowNames count] > 0) ? [m_foundShowNames objectAtIndex:0] : nil;
}

-(void) setCurrentShowName:(NSString*) value
{
    NSLog(@"********** setCurrentEpisode:'%@'\n", value);
}

-(NSNumber*) currentSeason
{
    // For now just return the one we parsed
    return (m_season >= 0) ? [NSNumber numberWithInt:m_season] : nil;
}

-(void) setCurrentSeason:(NSNumber*) value
{
    NSLog(@"********** setCurrentEpisode:'%@'\n", value);
}

-(NSNumber*) currentEpisode
{
    // For now just return the one we parsed
    return (m_episode >= 0) ? [NSNumber numberWithInt:m_episode] : nil;
}

-(void) setCurrentEpisode:(NSNumber*) value
{
    NSLog(@"********** setCurrentEpisode:'%@'\n", value);
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
    for (m_foundSearcher in m_searchers) {
        if ([m_foundSearcher searchForShow:searchString]) {
            m_foundShowNames = [m_foundSearcher.foundShowNames retain];
            m_foundShowIds = [m_foundSearcher.foundShowIds retain];
            [m_foundSearcher retain];
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
    [m_foundSearcher release];
    m_foundSearcher = nil;
    
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

-(NSDictionary*) detailsForShow:(int) showId season:(int) season episode:(int) episode
{
    return [m_foundSearcher detailsForShow:showId season:season episode:episode];
}

- (id)valueForUndefinedKey:(NSString *)key
{
    NSLog(@"*** MetadataSearch::valueForUndefinedKey:%@\n", key);
    return nil;
}

@end
