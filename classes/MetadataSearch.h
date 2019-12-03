//
//  MetadataSearch.h
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

#import <Cocoa/Cocoa.h>

@class MetadataSearch;

@interface MetadataSearcher : NSObject {
    NSArray* m_foundShowNames;
    NSArray* m_foundShowIds;
    NSArray* m_foundSeasons;
    NSArray* m_foundEpisodes;
    MetadataSearch* m_metadataSearch;
}

@property(readwrite,retain) NSArray* foundShowNames;
@property(readwrite,retain) NSArray* foundShowIds;
@property(readwrite,retain) NSArray* foundSeasons;
@property(readwrite,retain) NSArray* foundEpisodes;

-(void) initWithMetadataSearch:(MetadataSearch*) metadataSearch;

-(void) searchForShow:(NSString*) searchString;


// The episode/season is passed by reference because if that season/episode doesn't
// exist for the given show. In that case, they are reset to the first season and/or
// episode for that show. In the new callback API, pass the season/episode by value
// and in the callback indicate whether or not the season/episode exists. Rather
// than returning the first season and/or episode. It might be better to just return
// a null dictionary. The season and episode pulldowns will have the proper values
// so the user can just choose the desired one. The pulldowns will probably need '--'
// values to indicate that no season or episode are currently selected. Maybe
// just the season pulldown should have '--' and if it is selected the episode
// pulldown should be greyed out. 
//
// Something else to think about. If you search for a movie, it has neither a season
// nor an episode. What does the UI do in that case? Probably both the season
// and episode pulldowns should be greyed out in that case. Can simply have the
// pulldowns grey out if it contains no values (maybe it already does).



-(void) detailsForShow:(int) showId season:(int) season episode:(int) episode;

@end

@class Metadata;

@interface MetadataSearch : NSObject {
    NSArray* m_foundShowNames;
    NSArray* m_foundShowIds;
    MetadataSearcher* m_foundSearcher;
    NSArray* m_foundSeasons;
    NSArray* m_foundEpisodes;
    int m_season;
    int m_episode;
    int m_showId;
    Metadata* m_metadata;
    NSString* m_currentShowName;
    NSDictionary* m_searchers;
    
    NSMutableArray* m_searchWithFilenameArray;
    
    SEL m_searchForShowsSelector;
}

@property(retain) NSString* currentShowName;
@property(readonly) BOOL currentSeasonIsValid;
@property(retain) NSString* currentSeason;
@property(retain) NSString* currentEpisode;
@property(retain) MetadataSearcher* foundSearcher;
@property(retain) NSArray* foundShowNames;
@property(retain) NSArray* foundShowIds;
@property(retain) NSArray* foundSeasons;
@property(retain) NSArray* foundEpisodes;

+(MetadataSearch*) metadataSearch:(Metadata*) metadata;

-(void) searchForShowsComplete:(BOOL) success;
-(void) searchWithString:(NSString*) string filename:(NSString*) filename;
-(void) searchWithFilename:(NSString*) filename;

-(void) detailsLoaded:(NSDictionary*) dictionary success:(BOOL) success;
-(void) details;

@end
