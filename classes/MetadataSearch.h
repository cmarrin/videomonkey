//
//  MetadataSearch.h
//  VideoMonkey
//
//  Created by Chris Marrin on 4/13/09.
//  Copyright 2009 Apple. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MetadataSearcher : NSObject {
    NSMutableArray* m_foundShowNames;
    NSMutableArray* m_foundShowIds;
    NSMutableArray* m_foundSeasons;
    NSMutableArray* m_foundEpisodes;
}

@property(readonly) NSArray* foundShowNames;
@property(readonly) NSArray* foundShowIds;
@property(readonly) NSArray* foundSeasons;
@property(readonly) NSArray* foundEpisodes;

-(BOOL) searchForShow:(NSString*) searchString;
-(NSDictionary*) detailsForShow:(int) showId season:(int) season episode:(int) episode;

@end

@interface MetadataSearch : NSObject {
    NSArray* m_foundShowNames;
    NSArray* m_foundShowIds;
    MetadataSearcher* m_foundSearcher;
    NSArray* m_foundSeasons;
    NSArray* m_foundEpisodes;
    int m_season;
    int m_episode;
    
    NSArray* m_searchers;
}

@property(readwrite,retain) NSString* currentShowName;
@property(readwrite,retain) NSNumber* currentSeason;
@property(readwrite,retain) NSNumber* currentEpisode;
@property(readonly) NSArray* foundShowNames;
@property(readonly) NSArray* foundShowIds;
@property(readonly) NSArray* foundSeasons;
@property(readonly) NSArray* foundEpisodes;
@property(readonly) int parsedSeason;
@property(readonly) int parsedEpisode;

+(MetadataSearch*) metadataSearch;

-(BOOL) search:(NSString*) filename;
-(NSDictionary*) detailsForShow:(int) showId season:(int) season episode:(int) episode;

@end
