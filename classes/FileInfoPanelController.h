//
//  FileInfoPanelController.h
//  VideoMonkey
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright 2008 Chris Marrin. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AppController;
@class FileListController;
@class MetadataPanel;

@interface FileInfoPanelController : NSObject {
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
