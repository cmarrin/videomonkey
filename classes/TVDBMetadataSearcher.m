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

-(id) init
{
    // init the tag map, if needed
    if (!g_tvdbEpisodeMap) {
        g_tvdbEpisodeMap = [[NSDictionary dictionaryWithObjectsAndKeys:
            @"title",       	@"EpisodeName", 
            //@"TVShowName",  	@"TVShowName", 
            @"TVEpisode",   	@"ProductionCode", 
            //@"TVEpisodeNum",	@"EpisodeNumber", 
            //@"TVSeasonNum", 	@"SeasonNumber", 
            //@"tracknum",    	@"tracknum", 
            @"description", 	@"Overview", 
            @"year",        	@"FirstAired", 
            //@"year_year",      	@"year_year", 
            //@"year_month",     	@"year_month", 
            //@"year_day",       	@"year_day", 
            //@"stik",        	@"stik", 
            nil ] retain];

        g_tvdbSeriesMap = [[NSDictionary dictionaryWithObjectsAndKeys:
            //@"advisory",    	@"advisory",
            //@"rating_annotation",@"rating_annotation",
            //@"comment",     	@"©cmt", 
            //@"album",       	@"©alb", 
            //@"artist",      	@"©ART", 
            //@"albumArtist", 	@"aART", 
            //@"copyright",   	@"cprt", 
            @"TVNetwork",   	@"Network", 
            //@"encodingTool",	@"©too", 
            //@"genre",       	@"gnre", 
            @"contentRating",	@"ContentRating",
            nil ] retain];
    }
    
    return self;
}

-(BOOL) searchForShow:(NSString*) searchString
{
    [m_foundShowNames release];
    m_foundShowNames = nil;
    [m_foundShowIds release];
    m_foundShowIds = nil;
    [m_foundSeasons release];
    m_foundSeasons = nil;
    [m_foundEpisodes release];
    m_foundEpisodes = nil;

    NSString* urlString = [NSString stringWithFormat:@"http://www.thetvdb.com/api/GetSeries.php?seriesname=%@", searchString];
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    NSURL* url = [NSURL URLWithString:urlString];
    MyXMLDocument* doc = [MyXMLDocument xmlDocumentWithContentsOfURL:url];
    
    if (![[[doc rootElement] name] isEqualToString:@"Data"])
        return NO;
        
    NSArray* series = [[doc rootElement] elementsForName:@"Series"];
    if ([series count] == 0)
        return NO;
        
    m_foundShowNames = [[NSMutableArray alloc] init];
    m_foundShowIds = [[NSMutableArray alloc] init];

    for (MyXMLElement* element in series) {
        NSString* name = [[element lastElementForName:@"SeriesName"] content];
        NSString* seriesidString = [[element lastElementForName:@"seriesid"] content];
        int seriesid = (seriesidString && [seriesidString length] > 0) ? [seriesidString intValue] : -1;
        if (name && [name length] > 0 && seriesid >= 0) {
            [m_foundShowNames addObject:name];
            [m_foundShowIds addObject:[NSNumber numberWithInt:seriesid]];
        }
    }
    
    if ([m_foundShowNames count] == 0) {
        [m_foundShowNames release];
        m_foundShowNames = nil;
        [m_foundShowIds release];
        m_foundShowIds = nil;
        return NO;
    }
    
    return YES;
}

-(void) collectArtwork:(NSArray*) fromArray toArray:(NSMutableArray*) toArray
{
    for (MyXMLElement* element in fromArray) {
        NSString* s = [element content];
        if (s && [s length] > 0)
            [toArray addObject:[NSString stringWithFormat:@"http://www.thetvdb.com/banners/%@", s]];
    }
}

-(NSDictionary*) detailsForShow:(int) showId season:(int) season episode:(int) episode
{
    int i = 0;
    
    for (NSNumber* show in m_foundShowIds)
    {
        if ([show intValue] == showId) {
            NSString* urlString = [NSString stringWithFormat:@"http://www.thetvdb.com/data/series/%d/all/", showId];
            NSURL* url = [NSURL URLWithString:urlString];
            MyXMLDocument* doc = [MyXMLDocument xmlDocumentWithContentsOfURL:url];
            
            if (![[[doc rootElement] name] isEqualToString:@"Data"])
                return nil;
        
            // find the season and episode
            MyXMLElement* series = [[doc rootElement] lastElementForName:@"Series"];
            NSArray* episodes = [[doc rootElement] elementsForName:@"Episode"];
            if (!episodes)
                return nil;
                
            NSString* value;
                
            for (MyXMLElement* episodeElement in episodes) {
                int s = [[[episodeElement lastElementForName:@"SeasonNumber"] content] intValue];
                int e = [[[episodeElement lastElementForName:@"EpisodeNumber"] content] intValue];
                if (season == s && episode == e) {
                    // build dictionary with values
                    NSMutableDictionary* dictionary = [[NSMutableDictionary alloc] init];
                    
                    // this is a tv show
                    [dictionary setValue:@"TV Show" forKey:@"stik"];
                    
                    // set the track, episode and season
                    [dictionary setValue:[[NSNumber numberWithInt:season] stringValue] forKey:@"TVSeasonNum"];
                    [dictionary setValue:[[NSNumber numberWithInt:episode] stringValue] forKey:@"TVEpisodeNum"];
                    [dictionary setValue:[[NSNumber numberWithInt:episode] stringValue] forKey:@"tracknum"];
                    
                    // Set the show title
                    [dictionary setValue:[m_foundShowNames objectAtIndex:i] forKey:@"TVShowName"];
                    
                    // first get all the series info
                    for (NSString* key in g_tvdbSeriesMap) {
                        NSString* dictionaryKey = [g_tvdbSeriesMap valueForKey:key];
                        value = [[series lastElementForName:key] content];
                        if (value)
                            [dictionary setValue:value forKey:dictionaryKey];
                    }
                    
                    // then do all the episode info
                    for (NSString* key in g_tvdbEpisodeMap) {
                        NSString* dictionaryKey = [g_tvdbEpisodeMap valueForKey:key];
                        value = [[episodeElement lastElementForName:key] content];
                        if (value)
                            [dictionary setValue:value forKey:dictionaryKey];
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
                    
                    return dictionary;
                }
            }
            
            return nil;
        }
        
        i++;
    }
    
    return nil;
}

@end
