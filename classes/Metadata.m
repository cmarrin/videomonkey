//
//  Metadata.m
//  VideoMonkey
//
//  Created by Chris Marrin on 4/2/2009.
//  Copyright 2008 Apple. All rights reserved.
//

#import "Metadata.h"
#import "Transcoder.h"

@implementation Metadata

+(Metadata*) metadataWithTranscoder: (Transcoder*) transcoder
{
    Metadata* metadata = [[Metadata alloc] init];
    return metadata;
}

@end
