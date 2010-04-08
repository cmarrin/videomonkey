//
//  FileListController.h
//  VideoMonkey
//
//  Created by Chris Marrin on 1/21/09.
//  Copyright 2009 Apple. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AppController;

@interface FileListController : NSArrayController {
    IBOutlet NSTableView* m_fileListView;

    int m_draggedRow;
}

- (void)reloadData;
- (void)searchSelectedFiles;
- (void)searchAllFiles;
- (void)searchSelectedFilesForString:(NSString*) searchString;

- (void)addFile:(NSString*) filename;

- (IBAction)addFiles:(id)sender;
- (IBAction)clearAll:(id)sender;
- (IBAction)selectAll:(id)sender;

@end
