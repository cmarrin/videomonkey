//
//  MetadataSearch.m
//  VideoMonkey
//
//  Created by Chris Marrin on 4/13/09.

/*
Copyright (c) 2009-2011 Chris Marrin (chris@marrin.com)
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

    - Redistributions of source code must retain the above copyright notice, this 
      list of conditions and the following disclaimer.

    - Redistributions in binary form must reproduce the above copyright notice, 
      this list of conditions and the following disclaimer in the documentation 
      and/or other materials provided with the distribution.

    - Neither the name of Video Monkey nor the names of its contributors may be 
      used to endorse or promote products derived from this software without 
      specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY 
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH 
DAMAGE.
*/

#import "MetadataSearch.h"
#import "AppController.h"
#import "FileInfoPanelController.h"
#import "Metadata.h"
#import "MovieDBMetadataSearcher.h"
#import "TVDBMetadataSearcher.h"
#import "XMLDocument.h"

@class XMLDocument;

@implementation MetadataSearcher

@synthesize foundShowNames = m_foundShowNames;
@synthesize foundShowIds = m_foundShowIds;
@synthesize foundSeasons = m_foundSeasons;
@synthesize foundEpisodes = m_foundEpisodes;

-(void) initWithMetadataSearch:(MetadataSearch*) metadataSearch
{
    [super init];
    m_metadataSearch = metadataSearch;
}

-(NSString*) makeSearchURLString:(NSString*) searchString { return nil; }
-(BOOL) loadShowData:(XMLDocument*) document { return NO; }

-(void) searchForShowCallback:(XMLDocument*) document
{
    BOOL success = document != nil;
    if (success) {
        assert(document == m_currentSearchDocument);
        success = [self loadShowData:document];
    }
    
    [m_currentSearchDocument release];
    m_currentSearchDocument = nil;
    [m_metadataSearch searchForShowsComplete:success];
}

-(void) searchForShow:(NSString*) searchString
{
    self.foundShowNames = nil;
    self.foundShowIds = nil;
    self.foundSeasons = nil;
    self.foundEpisodes = nil;

    NSString* urlString = [self makeSearchURLString:searchString];
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    NSURL* url = [NSURL URLWithString:urlString];
    
    assert(!m_currentSearchDocument);
    m_currentSearchDocument = [[XMLDocument xmlDocumentWithContentsOfURL:url 
                    withInfo:[NSString stringWithFormat:@"searching for \"%@\"", searchString] 
                    target:self selector:@selector(searchForShowCallback:)] retain];
}

-(void) detailsForShow:(int) showId season:(int) season episode:(int) episode { }

@end

@implementation MetadataSearch

@synthesize foundSearcher = m_foundSearcher;
@synthesize foundShowNames = m_foundShowNames;
@synthesize foundShowIds = m_foundShowIds;
@synthesize foundSeasons = m_foundSeasons;
@synthesize foundEpisodes = m_foundEpisodes;
@synthesize currentShowName = m_currentShowName;

- (BOOL)currentSeasonIsValid
{
    return m_season >= 0;
}

- (NSString*)currentSeason
{
    if (m_season >= 0)
        return [[NSNumber numberWithInt:m_season] stringValue];
        
    // If possible return season 1, otherwise, return the first on in the list
    for (NSString* s in m_foundSeasons)
        if ([s isEqualToString:@"1"])
            return s;
    
    return (([m_foundSeasons count] > 0) ? [m_foundSeasons objectAtIndex:0] : @"--");
}

- (void)setCurrentSeason:(NSString*) season
{
    m_season = [season isEqualToString:@"--"] ? -1 : [season intValue];
    [self details];
}

- (NSString*)currentEpisode
{
    if (m_episode >= 0)
        return [[NSNumber numberWithInt:m_episode] stringValue];
        
    // If possible return season 1, otherwise, return the first on in the list
    for (NSString* s in m_foundEpisodes)
        if ([s isEqualToString:@"1"])
            return s;
    
    return (([m_foundEpisodes count] > 0) ? [m_foundEpisodes objectAtIndex:0] : @"--");
}

- (void)setCurrentEpisode:(NSString*) episode
{
    m_episode = [episode isEqualToString:@"--"] ? -1 : [episode intValue];
    [self details];
}

+(MetadataSearch*) metadataSearch:(Metadata*) metadata
{
    MetadataSearch* metadataSearch = [[[MetadataSearch alloc] init] autorelease];
    metadataSearch->m_searchers = [[NSDictionary dictionaryWithObjectsAndKeys:
                                    [TVDBMetadataSearcher metadataSearcher:metadataSearch], @"thetvdb.com",
                                    [MovieDBMetadataSearcher metadataSearcher:metadataSearch], @"themoviedb.org",
                                    nil] retain];
    metadataSearch->m_metadata = metadata;
    metadataSearch->m_season = -1;
    metadataSearch->m_episode = -1;
    
    return metadataSearch;
}

static BOOL isValidInteger(NSString* s)
{
    if ([s length] == 0)
        return false;
    return [[s stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]] length] == 0;
}

-(void) searchForShowsComplete:(BOOL) success
{
    if (success) {
        self.foundShowNames = self.foundSearcher.foundShowNames;
        self.foundShowIds = self.foundSearcher.foundShowIds;

        // make the first thing found the current
        self.currentShowName = [m_foundShowNames objectAtIndex:0];
        m_showId = [[m_foundShowIds objectAtIndex:0] intValue];
    }
    else
        self.foundSearcher = nil;

    [self performSelector:m_searchForShowsSelector withObject:[NSNumber numberWithBool:success]];
}

-(void) _searchForShows:(NSString*) searchString withSelector:(SEL) selector
{
    self.foundSearcher = [m_searchers valueForKey:[[[AppController instance] fileInfoPanelController] currentSearcher]];
    if (!self.foundSearcher) {
        [self performSelector:selector withObject:[NSNumber numberWithBool:NO]];
        return;
    }
    
    m_searchForShowsSelector = selector;
    [self.foundSearcher searchForShow:searchString];
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
    NSMutableString* outputString = [[[NSMutableString alloc] init] autorelease];

    BOOL firstTime = YES;
    int maybeEpisode = -1;
    BOOL seeIfNextItemIsEpisode = NO;
    
    for (NSString* item in array) {
        item = [item lowercaseString];
        
        // If we have a speculative season and this next item is of the form e<number>, we have a winner
        if (seeIfNextItemIsEpisode && [item hasPrefix:@"e"]) {
            if (isValidInteger([item substringFromIndex: 1])) {
                *episode = [[item substringFromIndex: 1] intValue];
                continue;
            }
        }

        // see if this is of the form s<number>e<number>
        if ([item hasPrefix:@"s"]) {
            NSArray* seArray = [[item substringFromIndex: 1] componentsSeparatedByString:@"e"];
            if ([seArray count] == 2 && isValidInteger([seArray objectAtIndex:0]) && isValidInteger([seArray objectAtIndex:1])) {
                *season = [[seArray objectAtIndex:0] intValue];
                *episode = [[seArray objectAtIndex:1] intValue];
                
                // don't put it in the output string
                continue;
            }
        }
        
        // see if this is of the form <number>x<number>
        NSArray* seasonEpisode = [item componentsSeparatedByString:@"x"];
        if ([seasonEpisode count] == 2) {
            if (isValidInteger([seasonEpisode objectAtIndex:0]) && isValidInteger([seasonEpisode objectAtIndex:1])) {
                // we have a season/episode
                *season = [[seasonEpisode objectAtIndex:0] intValue];
                *episode = [[seasonEpisode objectAtIndex:1] intValue];
                continue;
            }
        }
        
        // see if this is of the form s<number>. If so, we will speculatively save it as the season
        // and look to see if the next item is of the form e<number>
        if ([item hasPrefix:@"s"]) {
            if (isValidInteger([item substringFromIndex: 1])) {
                *season = [[item substringFromIndex: 1] intValue];
                seeIfNextItemIsEpisode = YES;
                continue;
            }
        }
        
        // As a last ditch effort, if it's a bare number, set the episode to that.
        if (isValidInteger(item))
            maybeEpisode = [item intValue];
                
        if (!firstTime)
            [outputString appendString:@" "];
        else
            firstTime = NO;

        [outputString appendString:item];
    }
    
    if (maybeEpisode >= 1 && maybeEpisode <= 99 && *episode < 0)
        *episode = maybeEpisode;
    
    return outputString;
}

-(void) searchWithStringComplete:(NSNumber*) success
{
    if ([success boolValue])
        [self details];
    else
        [m_metadata loadSearchMetadata:0 success:NO];
}

-(void) searchWithString:(NSString*) string filename:(NSString*) filename
{
    if (m_season < 0 || m_episode < 0) {
        // Get the season and episode from the filename
        [self checkString:filename forSeason:&m_season episode:&m_episode];
    }
    
    /*
    // Get the season and episode out of the string and use it if needed
    int season;
    int episode;
    NSString* newString = [self checkString:string forSeason:&season episode:&episode];
    
    if (m_season < 0 && season >= 0)
        m_season = season;
        
    if (m_episode < 0 && episode >= 0)
        m_episode = episode;
    */
    
    // see if the search string in in our list already
    int i = 0;
    for (NSString* name in self.foundShowNames) {
        if ([string isEqualToString:name]) {
            self.currentShowName = [m_foundShowNames objectAtIndex:i];
            m_showId = [[m_foundShowIds objectAtIndex:i] intValue];
            [self details];
            return;
        }
        
        i++;
    }
    
    // not found, we need to do a full search
    self.foundShowNames = nil;
    self.foundShowIds = nil;
    self.foundSearcher = nil;
    
    [self _searchForShows: string withSelector:@selector(searchWithStringComplete:)];
}

-(void) searchWithFilenameCallback:(NSNumber*) success
{
    [m_searchWithFilenameArray removeLastObject];
    
    if ([success boolValue] || ![m_searchWithFilenameArray count]) {
        if ([success boolValue])
            [self details];
        else
            [m_metadata loadSearchMetadata:0 success:NO];
        [m_searchWithFilenameArray release];
        return;
    }
        
    [self _searchForShows: [m_searchWithFilenameArray componentsJoinedByString:@" "] withSelector:@selector(searchWithFilenameCallback:)];
}

-(void) searchWithFilename:(NSString*) filename
{
    self.foundShowNames = nil;
    self.foundShowIds = nil;
    self.foundSearcher = nil;
    
    // Format the filename into something that we can search with.
    // Toss the prefix and suffix
    NSString* searchString = [[filename lastPathComponent] stringByDeletingPathExtension];
    
     // See if anything looks like SxxEyy
    searchString = [self checkString:searchString forSeason:&m_season episode:&m_episode];
        
    m_searchWithFilenameArray = [[NSMutableArray arrayWithArray: [searchString componentsSeparatedByString:@" "]] retain];
    
    [self _searchForShows: [m_searchWithFilenameArray componentsJoinedByString:@" "] withSelector:@selector(searchWithFilenameCallback:)];
}

-(void) detailsLoaded:(NSDictionary*) dictionary success:(BOOL) success
{
    self.foundSeasons = self.foundSearcher.foundSeasons;
    self.foundEpisodes = self.foundSearcher.foundEpisodes;
    [m_metadata loadSearchMetadata:dictionary success:success];
}

-(void) details
{
    [self.foundSearcher detailsForShow:m_showId season:m_season episode:m_episode];
}

- (id)valueForUndefinedKey:(NSString *)key
{
    NSLog(@"*** MetadataSearch::valueForUndefinedKey:%@\n", key);
    return nil;
}

@end
