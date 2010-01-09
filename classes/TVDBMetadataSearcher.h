//
//  TVDBMetadataSearcher.h
//  VideoMonkey
//
//  Created by Chris Marrin on 4/13/09.
//  Copyright 2009 Apple. All rights reserved.
//

#import "MetadataSearch.h"

@interface TVDBMetadataSearcher : MetadataSearcher {
    int m_loadedShowId;
    int m_season, m_episode;
    
    // This is a dictionary of seasons. The key is the season number and the value is a
    // dictionary of episodes. In that dictionary the key is the episode number and
    // the value is the dictionary of the details for that episode.
    NSMutableDictionary* m_seasons;
}

@property(readwrite,retain) NSMutableDictionary* seasons;

+(MetadataSearcher*) metadataSearcher:(MetadataSearch*) metadataSearch;

@end
