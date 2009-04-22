//
//  MetadataSearch.m
//  VideoMonkey
//
//  Created by Chris Marrin on 4/13/09.
//  Copyright 2009 Apple. All rights reserved.
//

#import "MetadataSearch.h"
#import "Metadata.h"
#import "TVDBMetadataSearcher.h"

@implementation MetadataSearcher

@synthesize foundShowNames = m_foundShowNames;
@synthesize foundShowIds = m_foundShowIds;
@synthesize foundSeasons = m_foundSeasons;
@synthesize foundEpisodes = m_foundEpisodes;

-(BOOL) searchForShow:(NSString*) searchString { return NO; }
-(NSDictionary*) detailsForShow:(int) showId season:(int*) season episode:(int*) episode { return nil; }

@end

@implementation MetadataSearch

@synthesize foundShowNames = m_foundShowNames;
@synthesize foundShowIds = m_foundShowIds;
@synthesize foundSeasons = m_foundSeasons;
@synthesize foundEpisodes = m_foundEpisodes;
@synthesize currentShowName = m_currentShowName;

-(NSString*) currentSeason
{
    return (m_season >= 0) ? [[NSNumber numberWithInt:m_season] stringValue] : @"--";
}

-(void) setCurrentSeason:(NSString*) value
{
    m_season = [value isEqualToString:@"--"] ? -1 : [value intValue];
    [m_metadata searchMetadataChanged];
}

-(NSString*) currentEpisode
{
    return (m_episode >= 0) ? [[NSNumber numberWithInt:m_episode] stringValue] : @"--";
}

-(void) setCurrentEpisode:(NSString*) value
{
    m_episode = [value isEqualToString:@"--"] ? -1 : [value intValue];
    [m_metadata searchMetadataChanged];
}

+(MetadataSearch*) metadataSearch:(Metadata*) metadata
{
    MetadataSearch* metadataSearch = [[MetadataSearch alloc] init];
    metadataSearch->m_searchers = [[NSArray arrayWithObjects:[[TVDBMetadataSearcher alloc] init], nil] retain];
    metadataSearch->m_metadata = metadata;
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
            self.foundShowNames = m_foundSearcher.foundShowNames;
            self.foundShowIds = m_foundSearcher.foundShowIds;
            [m_foundSearcher retain];
            return YES;
        }
    }
    return NO;
}

-(BOOL) searchWithString:(NSString*) string
{
    // see if the search string in in our list already
    int i = 0;
    for (NSString* name in self.foundShowNames) {
        if ([string isEqualToString:name]) {
            self.currentShowName = [m_foundShowNames objectAtIndex:i];
            m_showId = [[m_foundShowIds objectAtIndex:i] intValue];
            return YES;
        }
        
        i++;
    }
    
    // not found, we need to do a full search
    self.foundShowNames = nil;
    self.foundShowIds = nil;
    [m_foundSearcher release];
    m_foundSearcher = nil;
    
    m_season = -1;
    m_episode = -1;
    if ([self _searchForShows: string]) {
        // make the first thing found the current
        self.currentShowName = [m_foundShowNames objectAtIndex:0];
        m_showId = [[m_foundShowIds objectAtIndex:0] intValue];
        return YES;
    }
    
    return NO;
}

-(BOOL) searchWithFilename:(NSString*) filename
{
    self.foundShowNames = nil;
    self.foundShowIds = nil;
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
        if ([self _searchForShows: [array componentsJoinedByString:@" "]]) {
            // make the first thing found the current
            [m_currentShowName release];
            m_currentShowName = nil;
            [self setCurrentShowName:[m_foundShowNames objectAtIndex:0]];
            m_showId = [[m_foundShowIds objectAtIndex:0] intValue];
            return YES;
        }
        
        // remove the last component
        [array removeLastObject];
    }
    
    return NO;
}

-(NSDictionary*) details
{
    NSDictionary* details = [m_foundSearcher detailsForShow:m_showId season:&m_season episode:&m_episode];
    self.foundSeasons = m_foundSearcher.foundSeasons;
    self.foundEpisodes = m_foundSearcher.foundEpisodes;
    return details;
}

- (id)valueForUndefinedKey:(NSString *)key
{
    NSLog(@"*** MetadataSearch::valueForUndefinedKey:%@\n", key);
    return nil;
}

@end
