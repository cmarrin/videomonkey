//
//  AppController.m
//  VideoMonkey
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright 2008 Chris Marrin. All rights reserved.
//

#import "AppController.h"
#import "Transcoder.h"

#define FileListItemType @"FileListItemType"

@implementation AppController

- (id)init
{
    if (self = [super init])
        m_files = [[NSMutableArray alloc] init];
    
    return self;
}

- (void)dealloc
{
    [m_files release];
    [super dealloc];
}

- (void) awakeFromNib
{
	// Register to accept filename drag/drop
	[m_fileListView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, FileListItemType, nil]];
    
    NSXMLDocument* doc = [[NSXMLDocument alloc] initWithXMLString: @"<foo bar='abc'><baz def='xyz'/></foo>" options: 0 error: nil];
    NSXMLElement* elt = [doc rootElement];
    NSXMLNode* node = [elt attributeForName: @"bar"];
    NSLog(@"*** root=%@\n", [node stringValue]);
}

// dataSource methods
- (int)numberOfRowsInTableView: (NSTableView *)aTableView
{
    return [m_files count];
}

static NSString* formatDuration(double duration)
{
    int ms = (int) round(fmod(duration, 1) * 1000);
    int hrs = (int) duration;
    int sec = hrs % 60;
    hrs /= 60;
    int min = hrs % 60;
    hrs /= 60;
    if (hrs == 0 && min == 0)
        return [NSString stringWithFormat:@"%.2fs", ((double) sec + ((double) ms / 1000.0))];
    else if (hrs == 0)
        return [NSString stringWithFormat:@"%dm %ds", min, sec];
    else
        return [NSString stringWithFormat:@"%dh %dm", hrs, min];
}

static NSString* formatFileSize(int size)
{
    if (size < 10000)
        return [NSString stringWithFormat:@"%dB", size];
    else if (size < 1000000)
        return [NSString stringWithFormat:@"%.1fKB", (double) size/1000.0];
    else if (size < 1000000000)
        return [NSString stringWithFormat:@"%.1fMB", (double) size/1000000.0];
    else
        return [NSString stringWithFormat:@"%.1fGB", (double) size/1000000000.0];
}

- (id)tableView: (NSTableView *)aTableView
    objectValueForTableColumn: (NSTableColumn *)aTableColumn
    row: (int)rowIndex
{
    if ([[aTableColumn identifier] isEqualToString: @"image"])
        return nil;
    if ([[aTableColumn identifier] isEqualToString: @"filename"])
        return [[m_files objectAtIndex: rowIndex] inputFilename];
    if ([[aTableColumn identifier] isEqualToString: @"filesize"])
        return formatFileSize([[m_files objectAtIndex: rowIndex] outputFileSize]);
    if ([[aTableColumn identifier] isEqualToString: @"duration"])
        return formatDuration([[m_files objectAtIndex: rowIndex] playTime]);
    return nil;
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
    [pboard setString: [[m_files objectAtIndex: m_draggedRow] inputFilename] forType: FileListItemType];
    
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
            id obj = [m_files objectAtIndex: m_draggedRow];
            [obj retain];
            [m_files removeObjectAtIndex: m_draggedRow];
            
            // insert the new string (same one that got dragger) into the array
            if (row > [m_files count])
                [m_files addObject: obj];
            else
                [m_files insertObject: obj atIndex: (row > m_draggedRow) ? (row-1) : row];
        
            [obj release];
            [m_fileListView reloadData];
        }
        else {
            // handle add of a new filename(s)
            NSArray *filenames = [pboard propertyListForType:NSFilenamesPboardType];
            if (filenames) {
                for (int i= 0; i < [filenames count]; i++) {
                    Transcoder* transcoder = [[Transcoder alloc] initWithController:self];
                    [transcoder addInputFile: [filenames objectAtIndex:i]];
                    
                    if (row < 0)
                        [m_files addObject:transcoder];
                    else
                        [m_files insertObject: transcoder atIndex: row];
                }
                [m_fileListView reloadData];
            }
        }
    }
    
    return YES;
}

- (IBAction)startConvert:(id)sender
{
    if ([m_files count] > 0)
        [[m_files objectAtIndex: 0] startEncode];
}

- (IBAction)pauseConvert:(id)sender
{
    printf("*** pause\n");
}

- (IBAction)stopConvert:(id)sender
{
    printf("*** stop\n");
}

-(void) setProgressFor: (Transcoder*) transcoder to: (double) progress
{
    [m_totalProgressBar setDoubleValue: progress];
}

-(void) encodeFinished: (Transcoder*) transcoder
{
    [m_totalProgressBar setDoubleValue: 0];
}

@end
