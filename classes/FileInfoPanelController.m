//
//  FileInfoPanelController.m
//  VideoMonkey
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright 2008 Chris Marrin. All rights reserved.
//

#import "FileInfoPanelController.h"

@implementation FileInfoPanelController

- (void)awakeFromNib {
    [m_searchField setRecentSearches:[NSArray arrayWithObjects:@"Foo", @"Bar", @"Baz", nil]];
    [m_imageTable setRowHeight:[[[m_imageTable tableColumns] objectAtIndex:2] width]];
}

-(IBAction)droppedInImage:(id)sender
{
    // user dropped in a new image. Deal with it
    //ArtworkItem* item = [ArtworkItem artworkItemWithPath:[NSString stringWithFormat:@"%@_artwork_%d", tmpArtworkPath, i+1] sourceIcon:g_sourceInputIcon checked:YES];
    //if (item)
    //    [m_artworkList addObject:item];
    printf("***\n");
    
}

-(void) setVisible: (BOOL) b
{
    if (b != m_isVisible) {
        m_isVisible = b;
        if (m_isVisible)
            // Update info
            ;
    }
}

- (void)windowWillMiniaturize:(NSNotification *)notification
{
    [self setVisible:NO];
}

- (void)windowDidDeminiaturize:(NSNotification *)notification
{
    [self setVisible:YES];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self setVisible:NO];
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
    [self setVisible:YES];
}

// NSDrawer delegate methods
- (NSSize)drawerWillResizeContents:(NSDrawer *)sender toSize:(NSSize)contentSize
{
    [m_imageTable setRowHeight:[[[m_imageTable tableColumns] objectAtIndex:2] width]];
    return contentSize;
}

// keep the disclosure button updated correctly
- (void)drawerDidClose:(NSNotification *)notification
{
    [m_artworkDrawerDisclosureButton setState:NSOffState];
}

@end
