//
//  FileInfoPanelController.m
//  VideoMonkey
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright 2008 Chris Marrin. All rights reserved.
//

#import "FileInfoPanelController.h"
#import "FileListController.h"
#import "Metadata.h"
#import "MetadataSearch.h"
#import "Transcoder.h"

@implementation FileInfoPanelController

@synthesize fileListController = m_fileListController;
@synthesize metadataPanel = m_metadataPanel;
@synthesize metadataStatus = m_metadataStatus;
@synthesize searcherStrings = m_searcherStrings;

-(BOOL) autoSearch
{
    return [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"autoSearch"] boolValue];    
}

-(void) setAutoSearch:(BOOL) value
{
    [[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:[NSNumber numberWithBool:value] forKey:@"autoSearch"];
}

-(NSString*) currentSearcher
{
    NSString* s = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"defaultMetadataSearch"];
    return ([s length] == 0) ? @"thetvdb.com" : s;
}

-(void) setCurrentSearcher:(NSString*) s
{
    [[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:s forKey:@"defaultMetadataSearch"];
}

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

- (void)awakeFromNib
{
    [m_fileInfoWindow setExcludedFromWindowsMenu:YES];
    
    [m_artworkTable setRowHeight:[[[m_artworkTable tableColumns] objectAtIndex:2] width]];
    
    // scroll to top of metadata
    NSPoint pt = NSMakePoint(0.0, [[m_metadataScrollView documentView] bounds].size.height);
    [[m_metadataScrollView documentView] scrollPoint:pt];
    
    // make the search box selected
    [m_searchField setDelegate:self];
    [m_searchField becomeFirstResponder];
    
    // Fill in the searchers
    self.searcherStrings = [NSArray arrayWithObjects:@"thetvdb.com", @"themoviedb.org", nil];
    self.currentSearcher = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"defaultMetadataSearch"];
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
    if (m_lastSearchString) {
        if ([m_lastSearchString isEqualToString:searchString])
            return;
    }
    
    [searchString retain];
    [m_lastSearchString release];
    m_lastSearchString = searchString;
    
    if ([searchString length] == 0)
        return;
        
    m_metadataSearchCount = 0;
    m_metadataSearchSucceeded = YES;
    [m_fileListController searchSelectedFilesForString:searchString];
}

-(IBAction)useSeasonValueForAllFiles:(id)sender
{
    if ([m_fileListController selection]) {
        Transcoder* selectedTranscoder = [m_fileListController selection];
        NSString* season = selectedTranscoder.metadata.search.currentSeason;
        NSArray* arrangedObjects = [m_fileListController arrangedObjects];
        
        for (Transcoder* transcoder in arrangedObjects)
            transcoder.metadata.search.currentSeason = season;
    }
}

-(IBAction)searchAllFiles:(id)sender
{
    m_metadataSearchCount = 0;
    m_metadataSearchSucceeded = YES;
    [m_fileListController searchAllFiles];
}

-(IBAction)searchSelectedFiles:(id)sender
{
    m_metadataSearchCount = 0;
    m_metadataSearchSucceeded = YES;
    [m_fileListController searchSelectedFiles];
}

-(void) startMetadataSearch
{
    if (++m_metadataSearchCount == 1) {
        [self.metadataPanel setMetadataSearchSpinner:YES];
        self.metadataStatus = @"Searching for metadata...";
    }
}

-(void) finishMetadataSearch:(BOOL) success
{
    if (!success)
        m_metadataSearchSucceeded = NO;

    if (--m_metadataSearchCount <= 0) {
        [self.metadataPanel setMetadataSearchSpinner:NO];
        self.metadataStatus = @"";
        
        if (!m_metadataSearchSucceeded) {
            // If we failed, show an alert
            NSRunAlertPanel(@"One or more metadata searches failed", @"See console for more information", nil, nil, nil);
        }
    }
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

// NSTextField delegate methods for searchField
- (void)controlTextDidBeginEditing:(NSNotification *)aNotification
{
    m_searchFieldIsEditing = YES;
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
    //NSLog(@"textDidChange\n");
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
    m_searchFieldIsEditing = NO;
}

@end
