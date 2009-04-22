//
//  FileInfoPanelController.m
//  VideoMonkey
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright 2008 Chris Marrin. All rights reserved.
//

#import "FileInfoPanelController.h"
#import "Metadata.h"
#import "Transcoder.h"

@implementation FileInfoPanelController

-(NSArray*) artworkList
{
    return [[(Transcoder*) [m_fileListController selection] metadata] artworkList];
}

-(NSImage*) primaryArtwork
{
    return [[(Transcoder*) [m_fileListController selection] metadata] primaryArtwork];
}

-(void) setPrimaryArtwork:(NSImage*) image
{
    id item = [[(Transcoder*) [m_fileListController selection] metadata] createArtwork: image];
    [m_artworkListController insertObject:item atArrangedObjectIndex:0];
}

- (void)awakeFromNib {
    [m_artworkTable setRowHeight:[[[m_artworkTable tableColumns] objectAtIndex:2] width]];
    
    // scroll to top of metadata
    NSPoint pt = NSMakePoint(0.0, [[m_metadataScrollView documentView] bounds].size.height);
    [[m_metadataScrollView documentView] scrollPoint:pt];
}

-(IBAction)droppedInImage:(id)sender
{
    [m_artworkTable reloadData];
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
    [m_artworkTable setRowHeight:[[[m_artworkTable tableColumns] objectAtIndex:2] width]];
    return contentSize;
}

// keep the disclosure button updated correctly
- (void)drawerDidClose:(NSNotification *)notification
{
    [m_artworkDrawerDisclosureButton setState:NSOffState];
}

-(IBAction)artworkCheckedStateChanged:(id)sender
{
    [m_fileListController rearrangeObjects];
}

-(IBAction)searchBoxSelected:(id)sender
{
    NSString* searchString = [sender stringValue];
    [[(Transcoder*)[m_fileListController selection] metadata] searchWithString:searchString];
}

-(id) selection
{
    // if we get here it means the artwork has no selection
    return nil;
}

- (id)valueForUndefinedKey:(NSString *)key
{
    NSLog(@"*** FileInfoPanelController::valueForUndefinedKey:%@\n", key);
    return nil;
}

@end
