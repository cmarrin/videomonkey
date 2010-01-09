//
//  MovieDBMetadataSearcher.h
//  VideoMonkey
//
//  Created by Chris Marrin on 4/13/09.
//  Copyright 2009 Apple. All rights reserved.
//

#import "MetadataSearch.h"

@interface MovieDBMetadataSearcher : MetadataSearcher {
    int m_loadedShowId;
    NSMutableDictionary* m_dictionary;
}

+(MetadataSearcher*) metadataSearcher:(MetadataSearch*) metadataSearch;

@end
