//
//  ArtworkListController.h
//  VideoMonkey
//
//  Created by Chris Marrin on 1/21/09.
//  Copyright 2009 Apple. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ArtworkListController : NSArrayController {
    IBOutlet NSTableView* m_artworkListView;

    int m_draggedRow;
}

-(void) reloadData;

-(IBAction)addArtwork:(id)sender;

@end
