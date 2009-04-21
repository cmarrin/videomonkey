//
//  FileInfoPanelController.h
//  VideoMonkey
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright 2008 Chris Marrin. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class FileListController;

@interface FileInfoPanelController : NSObject {
@private
    IBOutlet NSTabView* m_fileInfoTabView;
    IBOutlet NSTableView* m_artworkTable;
    IBOutlet NSButton* m_artworkDrawerDisclosureButton;
    IBOutlet FileListController* m_fileListController;
    IBOutlet NSArrayController* m_artworkListController;
    IBOutlet NSScrollView* m_metadataScrollView;

    BOOL m_isVisible;
}

@property(readonly) NSArray* artworkList;
@property(assign) NSImage* primaryArtwork;

-(IBAction)artworkCheckedStateChanged:(id)sender;
-(IBAction)searchBoxSelected:(id)sender;

@end
