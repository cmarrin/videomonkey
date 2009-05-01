//
//  FileInfoPanelController.h
//  VideoMonkey
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright 2008 Chris Marrin. All rights reserved.
//

#import <Cocoa/Cocoa.h>

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
    
    BOOL m_isVisible;
}

@property(readonly) NSArray* artworkList;
@property(readonly) FileListController* fileListController;
@property(readonly) MetadataPanel* metadataPanel;
@property(assign) NSImage* primaryArtwork;

-(IBAction)artworkCheckedStateChanged:(id)sender;
-(IBAction)searchBoxSelected:(id)sender;
-(IBAction)writeMetadata:(id)sender;
-(IBAction)useThisValueForAllFiles:(id)sender;

@end
