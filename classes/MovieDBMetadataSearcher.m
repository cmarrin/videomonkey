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
#import <Foundation/NSJSONSerialization.h>

// Map from MovieDB tag name to Dictionary tag name
static NSDictionary* g_moviedbMap = nil;

@implementation MovieDBMetadataSearcher

+(MetadataSearcher*) metadataSearcher:(MetadataSearch*) metadataSearch
{
    MetadataSearcher* searcher = [[[MovieDBMetadataSearcher alloc] init] autorelease];
    [searcher initWithMetadataSearch:metadataSearch];
    return searcher;
}

- (void) startLoadWithString:(NSString*) string completionHandler:(void (^)(NSDictionary*)) handler
{
    NSURL* url = [NSURL URLWithString:string];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
    {
        if ([data length] > 0 && error == nil) {
            NSError* error = nil;
            NSDictionary* document = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            if (!document || error) {
                // FIXME: implement error handling
            } else {
                assert([document isKindOfClass:[NSDictionary class]]);
                handler(document);
            }
        } else {
            // FIXME: implement error handling
        }
    }];
    [queue release];
}

-(BOOL) loadShowData:(NSDictionary*) document
{
    NSArray* results = [document valueForKey:@"results"];
    if (!results) {
        return NO;
    }
    NSMutableArray* foundShowNames = [[NSMutableArray alloc] init];
    NSMutableArray* foundShowIds = [[NSMutableArray alloc] init];

    for (NSDictionary* result in results) {
        NSString* name = [result valueForKey:@"original_title"];
        NSNumber* idObject = [result valueForKey:@"id"];
        int idValue = [idObject intValue];
        if (name && [name length] > 0 && idValue >= 0) {
            [foundShowNames addObject:name];
            [foundShowIds addObject:[NSNumber numberWithInt:idValue]];
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

-(void) searchForShow:(NSString*) searchString
{
    self.foundShowNames = nil;
    self.foundShowIds = nil;
    self.foundSeasons = nil;
    self.foundEpisodes = nil;

    NSString* urlString = [NSString stringWithFormat:@"http://api.themoviedb.org/3/search/movie?api_key=ae6c3dcf41e60014a3d0508e7f650884&query=%@", searchString];
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    [self startLoadWithString:urlString completionHandler:^(NSDictionary* document)
    {
        BOOL success = [self loadShowData:document];
        [m_metadataSearch searchForShowsComplete:success];
    }];
}

-(id) init
{
    [super init];
    
    // init the tag map, if needed
    if (!g_moviedbMap) {
        g_moviedbMap = [[NSDictionary dictionaryWithObjectsAndKeys:
            @"title",       	@"title", 
            @"description", 	@"overview", 
            @"year",        	@"release_date",
            nil ] retain];
    }
    
    return self;
}

-(void) collectArtwork:(NSDictionary*) document
{
    // Collect the images (5 max)
    NSMutableArray* imageArray = [[NSMutableArray alloc]init];
    NSDictionary* images = [document valueForKey:@"images"];
    if (!images) {
        [m_metadataSearch detailsLoaded:m_dictionary success:YES];
        return;
    }
    
    NSArray* posters = [images valueForKey:@"posters"];
    if (!posters) {
        [m_metadataSearch detailsLoaded:m_dictionary success:YES];
        return;
    }
    
    int i = 0;
    for (NSDictionary*poster in posters) {
        if (++i > 5) {
            break;
        }
        [imageArray addObject:[poster valueForKey:@"file_path"]];
    }

    // Get the baseURL
    NSString* urlString = [NSString stringWithFormat:@"http://api.themoviedb.org/3/configuration?api_key=ae6c3dcf41e60014a3d0508e7f650884"];
    [self startLoadWithString:urlString completionHandler:^(NSDictionary* configDocument)
    {
        NSDictionary* images = [configDocument valueForKey:@"images"];
        if (!images) {
            [m_metadataSearch detailsLoaded:m_dictionary success:YES];
            return;
        }
        NSString* baseURL = [images valueForKey:@"base_url"];
        if (!baseURL) {
            [m_metadataSearch detailsLoaded:m_dictionary success:YES];
            return;
        }
        NSMutableArray* artwork = [[NSMutableArray alloc]init];
        for (NSString* filePath in imageArray) {
            [artwork addObject:[NSString stringWithFormat:@"%@original%@", baseURL, filePath]];
        }
        [m_dictionary setValue:artwork forKey:@"artwork"];
        [artwork release];
        [m_metadataSearch detailsLoaded:m_dictionary success:YES];
    }];
}

-(void) loadDetailsCallback:(NSDictionary*) document
{
    // this is a movie
    [m_dictionary setValue:@"Short Film" forKey:@"stik"];
    
    NSString* value;
    
    // get the movie info
    for (NSString* key in g_moviedbMap) {
        NSString* dictionaryKey = [g_moviedbMap valueForKey:key];
        value = [document valueForKey:key];
        if (value)
            [m_dictionary setValue:value forKey:dictionaryKey];
    }
                
    // Get content rating (for US)
    NSDictionary* releases = [document valueForKey:@"releases"];
    if (releases) {
        NSArray* countries = [releases valueForKey:@"countries"];
        if (countries) {
            for (NSDictionary* country in countries) {
                NSString* code = [country valueForKey:@"iso_3166_1"];
                if ([code isEqualToString:@"US"] || [code isEqualToString:@"us"]) {
                    [m_dictionary setValue:[country valueForKey:@"certification"] forKey:@"contentRating"];
                    break;
                }
            }
        }
    }

    // collect the artwork
    [self collectArtwork:document];
}

-(void) detailsForShow:(int) showId season:(int) season episode:(int) episode
{
    if (showId == m_loadedShowId)
        [m_metadataSearch detailsLoaded:m_dictionary success:YES];
        
    [m_dictionary release];
    m_dictionary = [[NSMutableDictionary alloc] init];
    m_loadedShowId = showId;

    NSString* urlString = [NSString stringWithFormat:@"http://api.themoviedb.org/3/movie/%d?api_key=ae6c3dcf41e60014a3d0508e7f650884&append_to_response=releases,images", showId];
    [self startLoadWithString:urlString completionHandler:^(NSDictionary* document)
    {
        [self loadDetailsCallback:document];
    }];
}

@end
