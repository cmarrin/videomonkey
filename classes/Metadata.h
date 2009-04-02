//
//  Metadata.h
//  VideoMonkey
//
//  Created by Chris Marrin on 4/2/2009.
//  Copyright 2008 Apple. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Transcoder;

@interface Metadata : NSObject {
@private
}

+(Metadata*) metadataWithTranscoder: (Transcoder*) transcoder;

@end
