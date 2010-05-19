//
//  Metadata.h
//  VideoMonkey
//
//  Created by Chris Marrin on 4/2/2009.
//  Copyright 2008 Apple. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MetadataPanel.h"

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
    BOOL m_searchSucceeded;
}

@property(retain) NSMutableArray* artworkList;
@property(retain) NSMutableDictionary* tags;
@property(assign) NSImage* primaryArtwork;
@property(retain) MetadataSearch* search;
@property(readonly) NSString* rootFilename;

+(Metadata*) metadataWithTranscoder: (Transcoder*) transcoder;

-(id) createArtwork:(NSImage*) image;

-(NSString*) metadataCommand:(NSString*) filename;
-(BOOL) canWriteMetadataToInputFile;
-(BOOL) canWriteMetadataToOutputFile;
-(void) cleanupAfterMetadataWrite;
-(void) setMetadataSource:(TagType) type;

-(void) loadSearchMetadata:(NSDictionary*) dictionary success:(BOOL) success;

-(void) searchWithString:(NSString*) string;
-(void) searchAgain;

-(void) uncheckAllArtwork;

@end
