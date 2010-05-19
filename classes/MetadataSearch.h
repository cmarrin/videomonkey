//
//  MetadataSearch.h
//  VideoMonkey
//
//  Created by Chris Marrin on 4/13/09.
//  Copyright 2009 Apple. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MetadataSearch;
@class XMLDocument;

@interface MetadataSearcher : NSObject {
    NSArray* m_foundShowNames;
    NSArray* m_foundShowIds;
    NSArray* m_foundSeasons;
    NSArray* m_foundEpisodes;
    MetadataSearch* m_metadataSearch;
    XMLDocument* m_currentSearchDocument;
}

@property(readwrite,retain) NSArray* foundShowNames;
@property(readwrite,retain) NSArray* foundShowIds;
@property(readwrite,retain) NSArray* foundSeasons;
@property(readwrite,retain) NSArray* foundEpisodes;

-(void) initWithMetadataSearch:(MetadataSearch*) metadataSearch;
-(NSString*) makeSearchURLString:(NSString*) searchString;
-(BOOL) loadShowData:(XMLDocument*) document;

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
    NSArray* m_searchers;
    
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
