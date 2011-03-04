//
//  ArtworkListController.m
//  VideoMonkey
//
//  Created by Chris Marrin on 1/21/09.

/*
Copyright (c) 2009-2011 Chris Marrin (chris@marrin.com)
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

    - Redistributions of source code must retain the above copyright notice, this 
      list of conditions and the following disclaimer.

    - Redistributions in binary form must reproduce the above copyright notice, 
      this list of conditions and the following disclaimer in the documentation 
      and/or other materials provided with the distribution.

    - Neither the name of Video Monkey nor the names of its contributors may be 
      used to endorse or promote products derived from this software without 
      specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY 
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH 
DAMAGE.
*/

#import "ArtworkListController.h"

#define ArtworkListItemType @"ArtworkListItemType"

@implementation ArtworkListController

- (void) awakeFromNib
{
	// Register to accept filename drag/drop
	[m_artworkListView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, ArtworkListItemType, nil]];
}

-(void) reloadData
{
    [m_artworkListView reloadData];
}

// dragging methods
- (BOOL)tableView: (NSTableView *)aTableView
    writeRows: (NSArray *)rows
    toPasteboard: (NSPasteboard *)pboard
{
    // This method is called after it has been determined that a drag should begin, but before the drag has been started.  
    // To refuse the drag, return NO.  To start a drag, return YES and place the drag data onto the pasteboard (data, owner, etc...).  
    // The drag image and other drag related information will be set up and provided by the table view once this call returns with YES.  
    // The rows array is the list of row numbers that will be participating in the drag.
    if ([rows count] > 1)	// don't allow dragging with more than one row
        return NO;
    
    // get rid of any selections
    [m_artworkListView deselectAll:nil];
    m_draggedRow = [[rows objectAtIndex: 0] intValue];
    // the NSArray "rows" is actually an array of the indecies dragged
    
    // declare our dragged type in the paste board
    [pboard declareTypes: [NSArray arrayWithObjects: NSFilenamesPboardType, ArtworkListItemType, nil] owner: self];
    
    // put the string value into the paste board
    //[pboard setString: [[[[AppController instance] fileList] objectAtIndex: m_draggedRow] inputFileInfo].filename forType: FileListItemType];
    
    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    // prevent row from highlighting during drag
    return (operation == NSTableViewDropAbove) ? NSDragOperationMove : NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id < NSDraggingInfo >)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
    return YES;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
}

// End of delegation methods

-(IBAction)addArtwork:(id)sender
{
    // Ask for file names
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:NO];
    [panel setCanCreateDirectories:NO];
    [panel setAllowsMultipleSelection:YES];
    [panel setTitle:@"Choose a File"];
    [panel setPrompt:@"Add"];
    if ([panel runModalForTypes: nil] == NSOKButton) {
        //for (NSString* filename in [panel filenames])
        //    [self addFile:filename];
    }
}

- (id)valueForUndefinedKey:(NSString *)key
{
    NSLog(@"*** ArtworkListController::valueForUndefinedKey:%@\n", key);
    return nil;
}

@end
