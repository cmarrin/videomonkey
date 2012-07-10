//
//  FileListController.m
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

#import "FileListController.h"

#import "AppController.h"
#import "DeviceController.h"
#import "FileInfoPanelController.h"
#import "Metadata.h"
#import "MetadataSearch.h"
#import "MoviePanelController.h"
#import "ProgressCell.h"
#import "Transcoder.h"

#define FileListItemType @"FileListItemType"

@implementation FileListController

@synthesize lastFoundShowNames = m_lastFoundShowNames;
@synthesize lastShowName = m_lastShowName;

- (void) awakeFromNib
{
    [m_fileListView setDelegate:self];
    
    m_fileList = [[NSMutableArray alloc] init];
    [self setContent:m_fileList];

	// Register to accept filename drag/drop
	[m_fileListView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, FileListItemType, nil]];

    // Setup ProgressCell
    [[m_fileListView tableColumnWithIdentifier: @"progress"] setDataCell:[[[ProgressCell alloc] init] autorelease]];
}

- (void)dealloc
{
    [m_fileList release];
    [super dealloc];
}

-(void) reloadData
{
    //NSIndexSet* indexes = [self selectionIndexes];
    //[self setSelectionIndexes:[NSIndexSet indexSet]];
    //[self setSelectionIndexes:indexes];
    [m_fileListView reloadData];
}

-(void)setSearchBox
{
    if ([[self selectionIndexes] count] == 0) {
        self.lastFoundShowNames = nil;
        self.lastShowName = nil;
        return;
    }
    
    Transcoder* transcoder = [[self arrangedObjects] objectAtIndex:[self selectionIndex]];
    self.lastFoundShowNames = [[[transcoder metadata] search] foundShowNames];
    self.lastShowName = [[[transcoder metadata] search] currentShowName];
}

-(void) searchSelectedFiles
{
    NSArray* selectedObjects = [self selectedObjects];
    for (Transcoder* transcoder in selectedObjects)
        [transcoder.metadata searchAgain];
}

-(void) searchAllFiles
{
    NSArray* arrangedObjects = [self arrangedObjects];
    for (Transcoder* transcoder in arrangedObjects)
        [transcoder.metadata searchAgain];
    [self setSearchBox];
}

-(void) searchSelectedFilesForString:(NSString*) searchString
{
    NSArray* selectedObjects = [self selectedObjects];
    for (Transcoder* transcoder in selectedObjects)
        [[transcoder metadata] searchWithString:searchString];
    [self setSearchBox];
}

- (void)rearrangeObjects
{
	// Remember the selection because rearrange loses it on SnowLeopard
    NSIndexSet* indexes = [self selectionIndexes];
	[super rearrangeObjects];
	[self setSelectionIndexes:indexes];
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
    [m_fileListView deselectAll:nil];
    m_draggedRow = [[rows objectAtIndex: 0] intValue];
    // the NSArray "rows" is actually an array of the indecies dragged
    
    // declare our dragged type in the paste board
    [pboard declareTypes: [NSArray arrayWithObjects: NSFilenamesPboardType, FileListItemType, nil] owner: self];
    
    // put the string value into the paste board
    [pboard setString: [[m_fileList objectAtIndex: m_draggedRow] inputFileInfo].filename forType: FileListItemType];
    
    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    // prevent row from highlighting during drag
    return (operation == NSTableViewDropAbove) ? NSDragOperationMove : NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id < NSDraggingInfo >)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
    // This method is called when the mouse is released over an outline view that previously decided to allow 
    // a drop via the validateDrop method.  The data source should incorporate the data from the dragging 
    // pasteboard at this time.
    NSPasteboard *pboard = [info draggingPasteboard];	// get the paste board
    NSString *aString;
    
    if ([pboard availableTypeFromArray:[NSArray arrayWithObjects: NSFilenamesPboardType, FileListItemType, nil]])
    {
        // test to see if the string for the type we defined in the paste board.
        // if doesn't, do nothing.
        aString = [pboard stringForType: FileListItemType];
        
        if (aString) {
            // handle move of an item in the table
            // remove the index that got dragged, now that we are accepting the dragging
            id obj = [m_fileList objectAtIndex: m_draggedRow];
            [obj retain];
            [self removeObjectAtArrangedObjectIndex: m_draggedRow];
            
            // insert the new string (same one that got dragger) into the array
            if (row > [m_fileList count])
                [self addObject: obj];
            else
                [self insertObject: obj atArrangedObjectIndex: (row > m_draggedRow) ? (row-1) : row];
        
            [obj release];
            [self reloadData];
        }
        else {
            // handle add of a new filename(s)
            NSArray *filenames = [[pboard propertyListForType:NSFilenamesPboardType] 
                                    sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
            
            for (NSString* filename in filenames) {
                Transcoder* transcoder = [[Transcoder alloc] initWithFilename: filename];
                [self addObject: transcoder];
                [transcoder release];
            }
            
            [self reloadData];
            [[AppController instance] uiChanged];    
            [[AppController instance] updateEncodingInfo];    
        }
    }
    
    return YES;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    // If we have only one item selected, set it otherwise set nothing
    int index = ([m_fileListView numberOfSelectedRows] != 1) ? -1 : [m_fileListView selectedRow];
    Transcoder* transcoder = (index < 0) ? nil : [m_fileList objectAtIndex:index];

    // Set the current movie
    MoviePanelController* movie = [AppController instance].moviePanelController;
    if (transcoder)
        [movie setMovie:transcoder.inputFileInfo.filename withAvOffset:transcoder.avOffset];
    else
        [movie setMovie:nil withAvOffset:nan(0)];

    // Update metadata panel
    [self updateState];
    [self reloadData];
}

// End of delegation methods

-(void) addFile:(NSString*) filename
{
    Transcoder* transcoder = [[Transcoder alloc] initWithFilename: filename];
    [self addObject:transcoder];
    [transcoder release];
    [[AppController instance] uiChanged];    
    [[AppController instance] updateEncodingInfo];    
}

-(IBAction)addFiles:(id)sender
{
    // Ask for file names
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:NO];
    [panel setCanCreateDirectories:NO];
    [panel setAllowsMultipleSelection:YES];
    [panel setTitle:@"Choose a File"];
    [panel setPrompt:@"Add"];
    if ([panel runModal] == NSOKButton) {
        for (NSString* filename in [panel URLs])
            [self addFile:filename];
    }
}

- (IBAction)remove:(id)sender
{
    NSArray* selectedObjects = [self selectedObjects];
    for (Transcoder* transcoder in selectedObjects) {
        if ([transcoder fileStatus] == FS_ENCODING || [transcoder fileStatus] == FS_PAUSED) {
            NSString* filename = [[[transcoder inputFileInfo] filename] lastPathComponent];
            NSBeginAlertSheet([NSString stringWithFormat:@"Unable to remove %@", filename], nil, nil, nil, [[NSApplication sharedApplication] mainWindow], 
                            nil, nil, nil, nil, 
                            @"File is being encoded. Stop encoding then try again.");
        }
        else {
            [self removeObject:transcoder];
            [[AppController instance] updateEncodingInfo];
        }
    }
}

-(IBAction)clearAll:(id)sender
{
    [self selectAll:sender];
    [self remove:sender];
    [self setSearchBox];
}

-(IBAction)selectAll:(id)sender
{
    [self setSelectedObjects:[self arrangedObjects]];
    [self setSearchBox];
}

-(id) selection
{
    if ([[self selectionIndexes] count] != 1) 
        return nil;
        
    [self setSearchBox];
    return [[self arrangedObjects] objectAtIndex:[self selectionIndex]];
}

- (IBAction)selectNext:(id)sender
{
    if ([[self selectionIndexes] count] == 0)
        [self setSelectionIndex:0];
    else if ([[self selectionIndexes] count] > 1)
        [self setSelectionIndex:[self selectionIndex]];
    else
        [super selectNext:sender];
    [self setSearchBox];
}

- (IBAction)selectPrevious:(id)sender
{
    if ([[self selectionIndexes] count] == 0)
        [self setSelectionIndex:[[self arrangedObjects] count] - 1];
    else if ([[self selectionIndexes] count] > 1)
        [self setSelectionIndex:[[self selectionIndexes] lastIndex]];
    else
        [super selectPrevious:sender];
    [self setSearchBox];
}

-(void) updateState
{
    // Enable or disable metadata panel based on file type
    
    // If more than one file is selected, pass a MPEG-4 as the file type if 
    // any files are MPEG-4. This allows us to write metadata for multiply
    // selected files
    NSString* fileType = nil;
    BOOL inputFile = [[[AppController instance] deviceController] shouldWriteMetadataToInputFile];
    NSArray* selectedObjects = [self selectedObjects];
    
    for (Transcoder* transcoder in selectedObjects) {
        NSString* candidateFileType = inputFile ? [transcoder inputFileInfo].format : [transcoder outputFileInfo].format;
        if ([candidateFileType isEqualToString:@"MPEG-4"]) {
            fileType = @"MPEG-4";
            break;
        }
    }
        
    [[AppController instance].fileInfoPanelController setMetadataStateForFileType:fileType];
}

- (id)valueForUndefinedKey:(NSString *)key
{
    NSLog(@"*** FileListController::valueForUndefinedKey:%@\n", key);
    return nil;
}

@end
