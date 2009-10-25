//
//  MetadataSearch.m
//  VideoMonkey
//
//  Created by Chris Marrin on 4/13/09.
//  Copyright 2009 Apple. All rights reserved.
//

#import "MetadataSearch.h"
#import "Metadata.h"
#import "MovieDBMetadataSearcher.h"
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
@synthesize currentSearcher = m_currentSearcher;

-(NSString*) currentSearcher
{
    return m_currentSearcher;
}

-(void) setCurrentSearcher:(NSString*) string
{
    if (m_currentSearcher == string)
        return;
        
    m_currentSearcher = string;
    [m_metadata searchAgain];
}

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
    metadataSearch->m_searchers = [[NSDictionary dictionaryWithObjectsAndKeys:
                                    [[TVDBMetadataSearcher alloc] init], @"thetvdb.com",
                                    [[MovieDBMetadataSearcher alloc] init], @"themoviedb.org",
                                    nil] retain];
    metadataSearch->m_metadata = metadata;
    metadataSearch->m_season = -1;
    metadataSearch->m_episode = -1;
    [metadataSearch setCurrentSearcher: @"thetvdb.com"];
    return metadataSearch;
}

static BOOL isValidInteger(NSString* s)
{
    if ([s length] == 0)
        return false;
    return [[s stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]] length] == 0;
}

-(BOOL) _searchForShows:(NSString*) searchString
{
    m_foundSearcher = [m_searchers valueForKey:[self currentSearcher]];
    if (!m_foundSearcher)
        return NO;
        
    if ([m_foundSearcher searchForShow:searchString]) {
        self.foundShowNames = m_foundSearcher.foundShowNames;
        self.foundShowIds = m_foundSearcher.foundShowIds;
        [m_foundSearcher retain];
        return YES;
    }
    m_foundSearcher = nil;
    return NO;
}

// This function not only returns the found season/episode, but also returns a new string with
// everything up to but not including the season/episode and all the non alpha-numeric characters 
// converted to spaces
-(NSString*) checkString:(NSString*) string forSeason:(int*) season episode:(int*) episode
{
    // See if anything looks like SxxEyy
    *season = -1;
    *episode = -1;
    
    NSArray* array = [string componentsSeparatedByCharactersInSet:
                                    [[NSCharacterSet alphanumericCharacterSet] invertedSet]];
    NSMutableString* outputString = [[NSMutableString alloc] init];

    BOOL firstTime = YES;
    
    for (NSString* item in array) {
        item = [item lowercaseString];
        if ([item hasPrefix:@"s"]) {
            NSArray* seArray = [[item substringFromIndex: 1] componentsSeparatedByString:@"e"];
            if ([seArray count] == 2 && isValidInteger([seArray objectAtIndex:0]) && isValidInteger([seArray objectAtIndex:1])) {
                *season = [[seArray objectAtIndex:0] intValue];
                *episode = [[seArray objectAtIndex:1] intValue];
                
                // don't put it in the output string
                continue;
            }
        }
        
        NSArray* seasonEpisode = [item componentsSeparatedByString:@"x"];
        if ([seasonEpisode count] == 2) {
            // see if this is of the form <number>x<number>
            if (isValidInteger([seasonEpisode objectAtIndex:0]) && isValidInteger([seasonEpisode objectAtIndex:1])) {
                // we have a season/episode
                *season = [[seasonEpisode objectAtIndex:0] intValue];
                *episode = [[seasonEpisode objectAtIndex:1] intValue];
                continue;
            }
        }
                
        if (!firstTime)
            [outputString appendString:@" "];
        else
            firstTime = NO;

        [outputString appendString:item];
    }
    
    return outputString;
}

-(BOOL) searchWithString:(NSString*) string
{
    // sometimes a show name has the season/episode encoded into it. See if it does and remove it if so
    int season;
    int episode;
    NSString* newString = [self checkString:string forSeason:&season episode:&episode];
    
    if (season >= 0 && m_season < 0)
        m_season = season;
        
    if (episode >= 0 && m_episode < 0)
        m_episode = episode;
        
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
    
    m_season = (season >= 0) ? season : -1;
    m_episode = (episode >= 0) ? episode : -1;
    
    if ([self _searchForShows: newString]) {
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
    
     // See if anything looks like SxxEyy
    searchString = [self checkString:searchString forSeason:&m_season episode:&m_episode];
        
    NSMutableArray* array = [[NSMutableArray arrayWithArray: [searchString componentsSeparatedByString:@" "]] retain];
    
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
    
    [array release];
    
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
