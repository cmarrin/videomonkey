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

-(IBAction) zoomSliderDidChange:(id)sender
{
    [m_imageBrowser setZoomValue:[sender floatValue]];
    [m_imageBrowser setNeedsDisplay:YES];
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

// IKImageBrowserDelegate methods
- (void) imageBrowserSelectionDidChange:(IKImageBrowserView *) browser
{
    NSLog(@"***************** imageBrowserSelectionDidChange: selection=%@\n", [browser selectionIndexes]);
}

/*
// NSTableView delegate methods
- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    NSSize spacing = [tableView intercellSpacing];
    return [[[tableView tableColumns] objectAtIndex:2] width];
}
*/

// NSDrawer delegate methods
- (NSSize)drawerWillResizeContents:(NSDrawer *)sender toSize:(NSSize)contentSize
{
    [m_imageTable setRowHeight:[[[m_imageTable tableColumns] objectAtIndex:2] width]];
    return contentSize;
}

@end
