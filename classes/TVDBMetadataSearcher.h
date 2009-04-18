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
    
    // This is an array of season objects - season 0 (usually show extras) is array entry 0
    // Each entry is an array of episodes - episode 0 (usually show extras) is array entry 0
    // each episode entry is an NSDictionary with keys matching the metadata entries found in Metadata.
    NSMutableArray* m_seasons;
}

@end
