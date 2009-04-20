//
//  Metadata.h
//  VideoMonkey
//
//  Created by Chris Marrin on 4/2/2009.
//  Copyright 2008 Apple. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MetadataSearch;
@class Transcoder;

@interface Metadata : NSObject {
@private
    Transcoder* m_transcoder;
    NSTask* m_task;
    NSPipe* m_messagePipe;
    NSMutableString* m_buffer;
    NSMutableDictionary* m_tagDictionary;
    NSMutableArray* m_artworkList;
    int m_numArtwork;
    MetadataSearch* m_search;
    NSString* m_rootFilename;
}

@property(readonly) NSMutableArray* artworkList;
@property(retain) NSMutableDictionary* tags;
@property(assign) NSImage* primaryArtwork;
@property(readonly) MetadataSearch* search;
@property(readonly) NSString* rootFilename;

+(Metadata*) metadataWithTranscoder: (Transcoder*) transcoder;

-(id) createArtwork:(NSImage*) image;

-(NSString*) atomicParsleyParams;
-(void) cleanupAfterAtomicParsley;

-(void) searchMetadataChanged;

@end
