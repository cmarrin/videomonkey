//
//  MovieDBMetadataSearcher.m
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

#import "MovieDBMetadataSearcher.h"
#import "XMLDocument.h"

// Map from MovieDB tag name to Dictionary tag name
static NSDictionary* g_moviedbMap = nil;

@implementation MovieDBMetadataSearcher

+(MetadataSearcher*) metadataSearcher:(MetadataSearch*) metadataSearch
{
    MetadataSearcher* searcher = [[MovieDBMetadataSearcher alloc] init];
    [searcher initWithMetadataSearch:metadataSearch];
    return searcher;
}

-(NSString*) makeSearchURLString:(NSString*) searchString
{
    return [NSString stringWithFormat:@"http://api.themoviedb.org/2.0/Movie.search?title=%@&api_key=ae6c3dcf41e60014a3d0508e7f650884", searchString];
}

-(BOOL) loadShowData:(XMLDocument*) document
{
    if (![[[document rootElement] name] isEqualToString:@"results"])
        return NO;
        
    XMLElement* matches = [[document rootElement] lastElementForName:@"moviematches"];
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

-(void) loadDetailsCallback:(XMLDocument*) document
{
    BOOL success = NO;
    
    if (document && [[[document rootElement] name] isEqualToString:@"results"]) {
        assert(document == m_currentSearchDocument);
    
        XMLElement* matches = [[document rootElement] lastElementForName:@"moviematches"];
        if (matches) {
            XMLElement* movie = [matches lastElementForName:@"movie"];
            if (movie) {
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
                
                success = YES;
            }
        }
    }

    [m_currentSearchDocument release];
    m_currentSearchDocument = nil;
    
    [m_metadataSearch detailsLoaded:m_dictionary success:success];
}

-(void) detailsForShow:(int) showId season:(int) season episode:(int) episode
{
    if (showId != m_loadedShowId) {
        [m_dictionary release];
        m_dictionary = [[NSMutableDictionary alloc] init];
        m_loadedShowId = showId;
        
        NSString* urlString = [NSString stringWithFormat:@"http://api.themoviedb.org/2.0/Movie.getInfo?id=%d&api_key=ae6c3dcf41e60014a3d0508e7f650884", showId];
        NSURL* url = [NSURL URLWithString:urlString];
        assert(!m_currentSearchDocument);
        m_currentSearchDocument = [[XMLDocument xmlDocumentWithContentsOfURL:url
                        withInfo:[NSString stringWithFormat:@"searching for movie with ID %d", showId] 
                        target:self selector:@selector(loadDetailsCallback:)] retain];
    }
}

@end
