//
//  MovieDBMetadataSearcher.m
//  VideoMonkey
//
//  Created by Chris Marrin on 4/13/09.
//  Copyright 2009 Apple. All rights reserved.
//

#import "MovieDBMetadataSearcher.h"
#import "XMLDocument.h"

// Map from MovieDB tag name to Dictionary tag name
static NSDictionary* g_moviedbMap = nil;

@implementation MovieDBMetadataSearcher

-(id) init
{
    // init the tag map, if needed
    if (!g_moviedbMap) {
        g_moviedbMap = [[NSDictionary dictionaryWithObjectsAndKeys:
            @"title",       	@"title", 
            @"description", 	@"short_overview", 
            @"year",        	@"release",
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

    NSString* urlString = [NSString stringWithFormat:@"http://api.themoviedb.org/2.0/Movie.search?title=%@&api_key=ae6c3dcf41e60014a3d0508e7f650884", searchString];
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    NSURL* url = [NSURL URLWithString:urlString];
    XMLDocument* doc = [XMLDocument xmlDocumentWithContentsOfURL:url];
    
    if (![[[doc rootElement] name] isEqualToString:@"results"])
        return NO;
        
    XMLElement* matches = [[doc rootElement] lastElementForName:@"moviematches"];
    if (!matches)
        return NO;
        
    NSArray* movies = [matches elementsForName:@"movie"];
    if ([movies count] == 0)
        return NO;
        
    NSMutableArray* foundShowNames = [[NSMutableArray alloc] init];
    NSMutableArray* foundShowIds = [[NSMutableArray alloc] init];

    for (XMLElement* element in movies) {
        NSString* name = [[element lastElementForName:@"title"] content];
        NSString* idString = [[element lastElementForName:@"id"] content];
        int id = (idString && [idString length] > 0) ? [idString intValue] : -1;
        if (name && [name length] > 0 && id >= 0) {
            [foundShowNames addObject:name];
            [foundShowIds addObject:[NSNumber numberWithInt:id]];
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

-(void) collectArtwork:(NSArray*) fromArray toArray:(NSMutableArray*) toArray
{
    for (XMLElement* element in fromArray) {
        if ([[element stringAttribute:@"size"] isEqualToString:@"original"]) {
            NSString* s = [element content];
            if (s && [s length] > 0)
                [toArray addObject:s];
        }
    }
}

-(void) loadDetailsForShow:(int) showId
{
    [m_dictionary release];
    m_dictionary = [[NSMutableDictionary alloc] init];
    m_loadedShowId = -1;
    
    NSString* urlString = [NSString stringWithFormat:@"http://api.themoviedb.org/2.0/Movie.getInfo?id=%d&api_key=ae6c3dcf41e60014a3d0508e7f650884", showId];
    NSURL* url = [NSURL URLWithString:urlString];
    XMLDocument* doc = [XMLDocument xmlDocumentWithContentsOfURL:url];
            
    if (![[[doc rootElement] name] isEqualToString:@"results"])
        return;
        
    XMLElement* matches = [[doc rootElement] lastElementForName:@"moviematches"];
    if (!matches)
        return;
        
    XMLElement* movie = [matches lastElementForName:@"movie"];
    if (!movie)
        return;
        
    // we have our movie
    m_loadedShowId = showId;
        
    // this is a movie
    [m_dictionary setValue:@"Movie" forKey:@"stik"];
    
    NSString* value;
    
    // get the movie info
    for (NSString* key in g_moviedbMap) {
        NSString* dictionaryKey = [g_moviedbMap valueForKey:key];
        value = [[movie lastElementForName:key] content];
        if (value)
            [m_dictionary setValue:value forKey:dictionaryKey];
    }
    
    // collect the artwork
    NSMutableArray* artwork = [[NSMutableArray alloc] init];
    [self collectArtwork: [movie elementsForName:@"poster"] toArray:artwork];
    [m_dictionary setValue:artwork forKey:@"artwork"];
}

-(NSDictionary*) detailsForShow:(int) showId season:(int*) season episode:(int*) episode
{
    if (showId != m_loadedShowId)
        [self loadDetailsForShow:showId];

    return m_dictionary;
}

@end
