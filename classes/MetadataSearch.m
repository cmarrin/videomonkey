//
//  MetadataSearch.m
//  VideoMonkey
//
//  Created by Chris Marrin on 4/13/09.
//  Copyright 2009 Apple. All rights reserved.
//

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
    if (success)
        [self loadShowData:document];
        
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
    
    [XMLDocument xmlDocumentWithContentsOfURL:url 
                    withInfo:[NSString stringWithFormat:@"searching for \"%@\"", searchString] 
                    target:self selector:@selector(searchForShowCallback:)];
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

-(NSString*) currentSeason
{
    return (m_season >= 0) ? [[NSNumber numberWithInt:m_season] stringValue] : @"--";
}

-(void) setCurrentSeason:(NSString*) value
{
    m_season = [value isEqualToString:@"--"] ? -1 : [value intValue];
    [self details];
}

-(NSString*) currentEpisode
{
    return (m_episode >= 0) ? [[NSNumber numberWithInt:m_episode] stringValue] : @"--";
}

-(void) setCurrentEpisode:(NSString*) value
{
    m_episode = [value isEqualToString:@"--"] ? -1 : [value intValue];
    [self details];
}

+(MetadataSearch*) metadataSearch:(Metadata*) metadata
{
    MetadataSearch* metadataSearch = [[MetadataSearch alloc] init];
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

-(void) searchWithStringComplete:(NSNumber*) success
{
    if ([success boolValue])
        [self details];
    else
        [m_metadata loadSearchMetadata:0];
}

-(void) searchWithString:(NSString*) string
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
            [self details];
            return;
        }
        
        i++;
    }
    
    // not found, we need to do a full search
    self.foundShowNames = nil;
    self.foundShowIds = nil;
    self.foundSearcher = nil;
    
    m_season = (season >= 0) ? season : -1;
    m_episode = (episode >= 0) ? episode : -1;
    
    [self _searchForShows: newString withSelector:@selector(searchWithStringComplete:)];
}

-(void) searchWithFilenameCallback:(NSNumber*) success
{
    [m_searchWithFilenameArray removeLastObject];
    
    if ([success boolValue] || ![m_searchWithFilenameArray count]) {
        if ([success boolValue])
            [self details];
        else
            [m_metadata loadSearchMetadata:0];
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

-(void) detailsLoaded:(NSDictionary*) dictionary
{
    self.foundSeasons = self.foundSearcher.foundSeasons;
    self.foundEpisodes = self.foundSearcher.foundEpisodes;
    [m_metadata loadSearchMetadata:dictionary];
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
