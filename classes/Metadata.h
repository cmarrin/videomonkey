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
    Transcoder* m_transcoder;
    NSTask* m_task;
    NSPipe* m_messagePipe;
    NSMutableString* m_buffer;
}

+(Metadata*) metadataWithTranscoder: (Transcoder*) transcoder;

@end
