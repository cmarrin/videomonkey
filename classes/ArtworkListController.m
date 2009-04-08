//
//  ArtworkListController.m
//  VideoMonkey
//
//  Created by Chris Marrin on 1/21/09.
//  Copyright 2009 Apple. All rights reserved.
//

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
    //[pboard setString: [[[m_appController fileList] objectAtIndex: m_draggedRow] inputFileInfo].filename forType: FileListItemType];
    
    return YES;
}

- (NSDragOperation)tableView: (NSTableView *)aTableView
    validateDrop: (id <NSDraggingInfo>)item
    proposedRow: (int)row
    proposedDropOperation: (NSTableViewDropOperation)op
{
    // prevent row from highlighting during drag
    return (op == NSTableViewDropAbove) ? NSDragOperationMove : NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView*)aTableView
    acceptDrop: (id <NSDraggingInfo>)item
    row: (int)row
    dropOperation:(NSTableViewDropOperation)op
{
    // This method is called when the mouse is released over an outline view that previously decided to allow 
    // a drop via the validateDrop method.  The data source should incorporate the data from the dragging 
    // pasteboard at this time.
    //NSPasteboard *pboard = [item draggingPasteboard];	// get the paste board
    //NSString *aString;
    
    /*
    if ([pboard availableTypeFromArray:[NSArray arrayWithObjects: NSFilenamesPboardType, ArtworkListItemType, nil]])
    {
        // test to see if the string for the type we defined in the paste board.
        // if doesn't, do nothing.
        aString = [pboard stringForType: FileListItemType];
        
        if (aString) {
            // handle move of an item in the table
            // remove the index that got dragged, now that we are accepting the dragging
            id obj = [[m_appController fileList] objectAtIndex: m_draggedRow];
            [obj retain];
            [self removeObjectAtArrangedObjectIndex: m_draggedRow];
            
            // insert the new string (same one that got dragger) into the array
            if (row > [[m_appController fileList] count])
                [self addObject: obj];
            else
                [self insertObject: obj atArrangedObjectIndex: (row > m_draggedRow) ? (row-1) : row];
        
            [obj release];
            [self reloadData];
        }
        else {
            // handle add of a new filename(s)
            NSArray *filenames = [pboard propertyListForType:NSFilenamesPboardType];
            
            // We create all the transcoders and then add them all at once. If we add a
            // transcoder too soon, the next transcoders validateInputFile will create 
            // and wait for a task, which will execute the runloop, which will try to 
            // render the incomplete transcoder and get an assertion.
            NSMutableArray* transcoders = [[NSMutableArray alloc] init];
            
            if (filenames) {
                for (NSString* filename in filenames) {
                    Transcoder* transcoder = [m_appController transcoderForFileName: filename];
                    [transcoders addObject: transcoder];
                    [transcoder release];
                    [self addObject:transcoder];
                    [self reloadData];
                }
                
                //for (Transcoder* transcoder in transcoders)
                //    [self addObject:transcoder];
                        
                [m_appController uiChanged];    
            }
            
            [transcoders release];
        }
    }
    */
    
    return YES;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    // If we have only one item selected, set it otherwise set nothing
    //[m_appController setSelectedFile: ([m_fileListView numberOfSelectedRows] != 1) ? -1 :
    //                                    [m_fileListView selectedRow]];
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