//
//  FileInfoPanelController.h
//  VideoMonkey
//
//  Created by Chris Marrin on 11/12/08.

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

@class AppController;
@class FileListController;
@class MetadataPanel;

@interface FileInfoPanelController : NSObject /* <NSComboBoxDelegate> */ {
@private
    IBOutlet NSWindow* m_fileInfoWindow;
    IBOutlet NSTabView* m_fileInfoTabView;
    IBOutlet NSTableView* m_artworkTable;
    IBOutlet NSButton* m_artworkDrawerDisclosureButton;
    IBOutlet FileListController* m_fileListController;
    IBOutlet NSArrayController* m_artworkListController;
    IBOutlet NSScrollView* m_metadataScrollView;
    IBOutlet NSComboBox* m_searchField;
    IBOutlet MetadataPanel* m_metadataPanel;
    IBOutlet NSBox* m_metadataContainer;
    IBOutlet NSTextField* m_metadataDisabledMessage;
    
    BOOL m_isVisible;
    NSString* m_metadataStatus;
    int m_metadataSearchCount;
    NSArray* m_searcherStrings;
    NSString* m_currentSearcher;
    BOOL m_metadataSearchSucceeded;
    BOOL m_searchFieldIsEditing;
    
    BOOL m_metadataEnabled;
}

@property(readonly) NSArray* artworkList;
@property(readonly) FileListController* fileListController;
@property(readonly) MetadataPanel* metadataPanel;
@property(assign) NSImage* primaryArtwork;
@property(assign) BOOL autoSearch;
@property(retain) NSString* metadataStatus;
@property(readwrite,retain) NSArray* searcherStrings;
@property(readwrite,retain) NSString* currentSearcher;

@property(assign) BOOL metadataEnabled;

- (IBAction)artworkCheckedStateChanged:(id)sender;
- (IBAction)searchBoxSelected:(id)sender;
- (IBAction)useSeasonValueForAllFiles:(id)sender;
- (IBAction)searchAllFiles:(id)sender;
- (IBAction)searchSelectedFiles:(id)sender;

- (void)initializeMetadataSearch;
- (void)startMetadataSearch;
- (void)finishMetadataSearch:(BOOL) success;
- (void)setMetadataStateForFileType:(NSString*) fileType;

@end
