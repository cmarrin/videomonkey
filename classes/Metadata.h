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
    BOOL m_isMetadataBusy;
    NSString* m_metadataStatus;
}

@property(retain) NSMutableArray* artworkList;
@property(retain) NSMutableDictionary* tags;
@property(assign) NSImage* primaryArtwork;
@property(retain) MetadataSearch* search;
@property(readonly) NSString* rootFilename;
@property(assign) BOOL isMetadataBusy;
@property(retain) NSString* metadataStatus;

+(Metadata*) metadataWithTranscoder: (Transcoder*) transcoder search:(BOOL) search;

-(id) createArtwork:(NSImage*) image;

-(NSString*) metadataCommand:(NSString*) filename;
-(BOOL) canWriteMetadataToInputFile;
-(BOOL) canWriteMetadataToOutputFile;
-(void) cleanupAfterMetadataWrite;
-(void) setMetadataSource:(TagType) type;

-(BOOL) searchWithString:(NSString*) string;
-(void) searchMetadataChanged;
-(void) searchAgain;

@end
