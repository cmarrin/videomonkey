//
//  Metadata.h
//  VideoMonkey
//
//  Created by Chris Marrin on 4/2/2009.

/*
Copyright (c) 2009-2011 Chris Marrin (chris@marrin.com)
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

    - Redistributions of source code must retain the above copyright notice, this 
      list of conditions and the following disclaimer.

    - Redistributions in binary form must reproduce the above copyright notice, 
      this list of conditions and the following disclaimer in the documentation 
      and/or other materials provided with the distribution.

    - Neither the name of Video Monkey nor the names of its contributors may be 
      used to endorse or promote products derived from this software without 
      specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY 
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH 
DAMAGE.
*/

#import <Cocoa/Cocoa.h>

#import "MetadataPanel.h"

@class MetadataSearch;
@class Transcoder;

@interface Metadata : NSObject {
@private
    Transcoder* m_transcoder;
    NSTask* m_task;
    NSPipe* m_messagePipe;
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
