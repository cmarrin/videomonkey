//
//  FileListController.m
//  VideoMonkey
//
//  Created by Chris Marrin on 1/21/09.
//  Copyright 2009 Apple. All rights reserved.
//

#import "FileListController.h"
#import "AppController.h"
#import "ProgressCell.h"
#import "Transcoder.h"

#define FileListItemType @"FileListItemType"

@implementation FileListController

- (void) awakeFromNib
{
    [m_fileListView setDelegate:self];
    
	// Register to accept filename drag/drop
	[m_fileListView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, FileListItemType, nil]];

    // Setup ProgressCell
    [[m_fileListView tableColumnWithIdentifier: @"progress"] setDataCell: [[ProgressCell alloc] init]];
}

-(void) reloadData
{
    [m_fileListView reloadData];
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
    [pboard setString: [[[m_appController fileList] objectAtIndex: m_draggedRow] inputFileInfo].filename forType: FileListItemType];
    
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
    NSPasteboard *pboard = [item draggingPasteboard];	// get the paste board
    NSString *aString;
    
    if ([pboard availableTypeFromArray:[NSArray arrayWithObjects: NSFilenamesPboardType, FileListItemType, nil]])
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
    
    return YES;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    // If we have only one item selected, set it otherwise set nothing
    [m_appController setSelectedFile: ([m_fileListView numberOfSelectedRows] != 1) ? -1 :
                                        [m_fileListView selectedRow]];
}

// End of delegation methods

-(void) addFile:(NSString*) filename
{
    Transcoder* transcoder = [m_appController transcoderForFileName: filename];
    [self addObject:transcoder];
    [transcoder release];
    [m_appController uiChanged];    
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
    if ([panel runModalForTypes: nil] == NSOKButton) {
        for (NSString* filename in [panel filenames])
            [self addFile:filename];
    }
}

-(IBAction)clearAll:(id)sender
{
    [self selectAll:sender];
    [self remove:sender];
}

-(IBAction)selectAll:(id)sender
{
    [self setSelectedObjects:[self arrangedObjects]];
}

/*
-(id) selection
{
    NSArray* arr = [self arrangedObjects];
    NSArray* sel = [self selectedObjects];
    
    // I don't know why, but the first time through the selectedObjects
    // array contains one object, which is the AppController. Return
    // nil if you see that.
    
    return ([sel count] == 1 && [[sel objectAtIndex:0] isKindOfClass:[Transcoder class]]) ? [sel objectAtIndex:0] : nil;
}
*/

- (void)selectNext:(id)sender
{
    if ([[self selectionIndexes] count] == 0)
        [self setSelectionIndex:0];
    else if ([[self selectionIndexes] count] > 1)
        [self setSelectionIndex:[self selectionIndex]];
    else
        [super selectNext:sender];
}

- (void)selectPrevious:(id)sender
{
    if ([[self selectionIndexes] count] == 0)
        [self setSelectionIndex:[[self arrangedObjects] count] - 1];
    else if ([[self selectionIndexes] count] > 1)
        [self setSelectionIndex:[[self selectionIndexes] lastIndex]];
    else
        [super selectPrevious:sender];
}

- (id)valueForUndefinedKey:(NSString *)key
{
    NSLog(@"*** FileListController::valueForUndefinedKey:%@\n", key);
    return nil;
}

@end
