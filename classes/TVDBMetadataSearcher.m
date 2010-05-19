//
//  TVDBMetadataSearcher.m
//  VideoMonkey
//
//  Created by Chris Marrin on 4/13/09.
//  Copyright 2009 Apple. All rights reserved.
//

#import "TVDBMetadataSearcher.h"
#import "XMLDocument.h"

// Map from TVDB tag name to Dictionary tag name
static NSDictionary* g_tvdbEpisodeMap = nil;
static NSDictionary* g_tvdbSeriesMap = nil;

@implementation TVDBMetadataSearcher

@synthesize seasons = m_seasons;

+(MetadataSearcher*) metadataSearcher:(MetadataSearch*) metadataSearch
{
    MetadataSearcher* searcher = [[TVDBMetadataSearcher alloc] init];
    [searcher initWithMetadataSearch:metadataSearch];
    return searcher;
}

-(NSString*) makeSearchURLString:(NSString*) searchString
{
    return [NSString stringWithFormat:@"http://www.thetvdb.com/api/GetSeries.php?seriesname=%@", searchString];
}

-(BOOL) loadShowData:(XMLDocument*) document
{
    if (![[[document rootElement] name] isEqualToString:@"Data"])
        return NO;
        
    NSArray* series = [[document rootElement] elementsForName:@"Series"];
    if ([series count] == 0)
        return NO;
        
    NSMutableArray* foundShowNames = [[NSMutableArray alloc] init];
    NSMutableArray* foundShowIds = [[NSMutableArray alloc] init];

    for (XMLElement* element in series) {
        NSString* name = [[element lastElementForName:@"SeriesName"] content];
        NSString* seriesidString = [[element lastElementForName:@"seriesid"] content];
        int seriesid = (seriesidString && [seriesidString length] > 0) ? [seriesidString intValue] : -1;
        if (name && [name length] > 0 && seriesid >= 0) {
            [foundShowNames addObject:name];
            [foundShowIds addObject:[NSNumber numberWithInt:seriesid]];
        }
    }
    
    if ([foundShowNames count] == 0) {
        [foundShowNames release];
        [foundShowIds release];
        return NO;
    }
    
    m_foundShowNames = foundShowNames;
    m_foundShowIds = foundShowIds;
    
    return YES;
}

-(id) init
{
    m_loadedShowId = -1;
    
    // init the tag map, if needed
    if (!g_tvdbEpisodeMap) {
        g_tvdbEpisodeMap = [[NSDictionary dictionaryWithObjectsAndKeys:
            @"title",       	@"EpisodeName", 
            @"TVEpisode",   	@"ProductionCode", 
            @"description", 	@"Overview", 
            @"year",        	@"FirstAired",
            
            // Automatically generated:
            
            //@"TVEpisodeNum",	@"EpisodeNumber", 
            //@"TVSeasonNum", 	@"SeasonNumber", 
            //@"tracknum",    	@"tracknum", 
            //@"year_year",     @"year_year", 
            //@"year_month",    @"year_month", 
            //@"year_day",      @"year_day", 
            nil ] retain];

        g_tvdbSeriesMap = [[NSDictionary dictionaryWithObjectsAndKeys:
            @"TVShowName",  	@"SeriesName", 
            @"TVNetwork",   	@"Network", 
            @"contentRating",	@"ContentRating",
            
            // Automatically generated:
            
            //@"stik",        	@"stik", 
            
            // Not currently added:
            
            //@"advisory",    	@"advisory",
            //@"rating_annotation",@"rating_annotation",
            //@"comment",     	@"©cmt", 
            //@"album",       	@"©alb", 
            //@"artist",      	@"©ART", 
            //@"albumArtist", 	@"aART", 
            //@"copyright",   	@"cprt", 
            //@"encodingTool",	@"©too", 
            //@"genre",       	@"gnre", 
            nil ] retain];
    }
    
    return self;
}

-(void) collectArtwork:(NSArray*) fromArray toArray:(NSMutableArray*) toArray
{
    for (XMLElement* element in fromArray) {
        NSString* s = [element content];
        if (s && [s length] > 0)
            [toArray addObject:[NSString stringWithFormat:@"http://www.thetvdb.com/banners/%@", s]];
    }
}

-(NSMutableDictionary*) addSeason:(NSString*) season episode:(NSString*) episode
{
    if (![m_seasons valueForKey:season]) {
        // add season
        [m_seasons setValue:[[NSMutableDictionary alloc] init] forKey: season];
    }
    
    if (![[m_seasons valueForKey:season] valueForKey:episode]) {
        // add episode
        [[m_seasons valueForKey:season] setValue:[[NSMutableDictionary alloc] init] forKey:episode];
    }

    return [[m_seasons valueForKey:season] valueForKey:episode];
}

NSInteger intSort(id num1, id num2, void* context)
{
    int v1 = [num1 intValue];
    int v2 = [num2 intValue];
    if (v1 < v2)
        return NSOrderedAscending;
    else if (v1 > v2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

static NSArray* numericallySortedArray(NSArray* array)
{
    return [array sortedArrayUsingFunction:intSort context:nil];
}

-(void) _addEpisode:(XMLElement*) episodeElement forSeries:(XMLElement*) series
{
    NSString* s = episodeElement ? [[episodeElement lastElementForName:@"SeasonNumber"] content] : nil;
    NSString* e = episodeElement ? [[episodeElement lastElementForName:@"EpisodeNumber"] content] : nil;
    
    if (!s)
        s = @"--";
        
    if (!e)
        e = @"--";
        
    // build dictionary with values
    NSMutableDictionary* dictionary = [self addSeason:s episode: e];

    // this is a tv show
    [dictionary setValue:@"TV Show" forKey:@"stik"];
    
    // set the track, episode and season
    [dictionary setValue:s forKey:@"TVSeasonNum"];
    [dictionary setValue:e forKey:@"TVEpisodeNum"];
    [dictionary setValue:e forKey:@"tracknum"];
    
    NSString* value;
    
    // first get all the series info
    for (NSString* key in g_tvdbSeriesMap) {
        NSString* dictionaryKey = [g_tvdbSeriesMap valueForKey:key];
        value = [[series lastElementForName:key] content];
        if (value)
            [dictionary setValue:value forKey:dictionaryKey];
    }
    
    // then do all the episode info
    if (episodeElement) {
        for (NSString* key in g_tvdbEpisodeMap) {
            NSString* dictionaryKey = [g_tvdbEpisodeMap valueForKey:key];
            value = [[episodeElement lastElementForName:key] content];
            if (value)
                [dictionary setValue:value forKey:dictionaryKey];
        }
    }
    
    // If we have a year, set the y/m/d
    NSString* year = [dictionary valueForKey:@"year"];
    if (year && [year length] > 0) {
        NSArray* yearArray = [year componentsSeparatedByString:@"-"];
        if ([yearArray count] > 0)
            [dictionary setValue:[[NSNumber numberWithInt:[[yearArray objectAtIndex:0] intValue]] stringValue] forKey:@"year_year"];
        if ([yearArray count] > 1)
            [dictionary setValue:[[NSNumber numberWithInt:[[yearArray objectAtIndex:1] intValue]] stringValue] forKey:@"year_month"];
        if ([yearArray count] > 2)
            [dictionary setValue:[[NSNumber numberWithInt:[[yearArray objectAtIndex:2] intValue]] stringValue] forKey:@"year_day"];
    }
    
    // collect the artwork, in order of preference
    NSMutableArray* artwork = [[NSMutableArray alloc] init];
    [self collectArtwork: [series elementsForName:@"poster"] toArray:artwork];
    [self collectArtwork: [series elementsForName:@"fanart"] toArray:artwork];
    [self collectArtwork: [series elementsForName:@"banner"] toArray:artwork];
    [dictionary setValue:artwork forKey:@"artwork"];
}

-(int) seasonOrEpisodeAsInt:(NSString*) value
{
    return [value isEqualToString:@"--"] ? -1 : [value intValue];
}

-(NSString*) seasonOrEpisodeAsString:(int) value
{
    return (value < 0) ? @"--" : [[NSNumber numberWithInt:value] stringValue];
}

-(void) completeLoadDetails:(BOOL) success
{
    NSDictionary* dictionary = nil;
    
    if (success) {
        // load up the m_foundSeasons array
        [m_foundSeasons release];
        NSMutableArray* foundSeasons = [[NSMutableArray alloc] init];
        for (NSString* key in m_seasons)
            [foundSeasons addObject: key];
        m_foundSeasons = [numericallySortedArray(foundSeasons) retain];

        if (m_season < 0 && [m_foundSeasons count] > 0) {
            // If possible return season 1, otherwise, return the first one in the list
            for (NSString* s in m_foundSeasons)
                if ([s isEqualToString:@"1"])
                    m_season = 1;

            if (m_season < 0)
                m_season = [self seasonOrEpisodeAsInt:[m_foundSeasons objectAtIndex:0]];
        }
            
        NSDictionary* episodes = [m_seasons valueForKey:[self seasonOrEpisodeAsString:m_season]];
        
        if (episodes) {
            // load up the m_foundEpisodes array
            [m_foundEpisodes release];
            NSMutableArray* foundEpisodes = [[NSMutableArray alloc] init];
            for (NSString* key in episodes)
                [foundEpisodes addObject: key];
            m_foundEpisodes = [numericallySortedArray(foundEpisodes) retain];

            if (m_episode < 0 && [m_foundEpisodes count] > 0) {
                // If possible return episode 1, otherwise, return the first one in the list
                for (NSString* s in m_foundEpisodes)
                    if ([s isEqualToString:@"1"])
                        m_episode = 1;

                if (m_episode < 0)
                    m_episode = [self seasonOrEpisodeAsInt:[m_foundEpisodes objectAtIndex:0]];
            }
            dictionary = [episodes valueForKey:[self seasonOrEpisodeAsString:m_episode]];
        }
    }
    
    [m_metadataSearch detailsLoaded:dictionary success:success];
}

-(void) loadDetailsCallback:(XMLDocument*) document
{
    BOOL success = document && [[[document rootElement] name] isEqualToString:@"Data"];
    
    if (success) {
        assert(document == m_currentSearchDocument);
        
        // find the season and episode
        XMLElement* series = [[document rootElement] lastElementForName:@"Series"];
        NSArray* episodes = [[document rootElement] elementsForName:@"Episode"];

        // We found our show. Fill in the details
        // This show may have no episodes, in which case we will fake an array with
        // season 0, episode 0 (we can still fill in the series info)
        self.seasons = [[NSMutableDictionary alloc] init];
            
        if (episodes && [episodes count] > 0)
            for (XMLElement* episodeElement in episodes)
                [self _addEpisode:episodeElement forSeries:series];
        else
            [self _addEpisode:nil forSeries:series];
    }
    
    [m_currentSearchDocument release];
    m_currentSearchDocument = nil;
    
    [self completeLoadDetails:success];
}

-(void) detailsForShow:(int) showId season:(int) season episode:(int) episode
{
    m_episode = episode;
    m_season = season;
    
    if (showId == m_loadedShowId) {
        [self completeLoadDetails:YES];
        return;
    }
    
    self.seasons = nil;
    m_loadedShowId = showId;
        
    NSString* urlString = [NSString stringWithFormat:@"http://www.thetvdb.com/data/series/%d/all/en.xml", showId];
    NSURL* url = [NSURL URLWithString:urlString];
    assert(!m_currentSearchDocument);
    m_currentSearchDocument = [[XMLDocument xmlDocumentWithContentsOfURL:url
                    withInfo:[NSString stringWithFormat:@"searching for TV show ID %d", showId] 
                    target:self selector:@selector(loadDetailsCallback:)] retain];
}

@end
