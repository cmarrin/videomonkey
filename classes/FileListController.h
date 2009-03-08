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
    IBOutlet AppController* m_appController;

    int m_draggedRow;
}

-(void) reloadData;

-(void) addFile:(NSString*) filename;

-(IBAction)addFiles:(id)sender;
-(IBAction)clearAll:(id)sender;
-(IBAction)selectAll:(id)sender;

@end
