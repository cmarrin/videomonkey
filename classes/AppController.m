//
//  AppController.m
//  VideoMonkey
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright 2008 Chris Marrin. All rights reserved.
//

#import "AppController.h"
#import "DeviceController.h"
#import "JavaScriptContext.h"
#import "Transcoder.h"
#import "ProgressCell.h"

#define FileListItemType @"FileListItemType"

@implementation AppController

- (id)init
{
    if (self = [super init]) {
        m_files = [[NSMutableArray alloc] init];
    }
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
    
    // Setup ProgressCell
    [[m_fileListView tableColumnWithIdentifier: @"progress"] setDataCell: [[ProgressCell alloc] init]];

    [m_totalProgressBar setUsesThreadedAnimation:YES];

    [m_stopEncodeItem setEnabled: NO];
    [m_pauseEncodeItem setEnabled: NO];
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

static NSString* getOutputFileName(NSString* inputFileName, NSString* savePath, NSString* suffix)
{
    // extract filename
    NSString* lastComponent = [inputFileName lastPathComponent];
    NSString* inputPath = [inputFileName stringByDeletingLastPathComponent];
    NSString* baseName = [lastComponent stringByDeletingPathExtension];

    if (!savePath)
        savePath = inputPath;
        
    // now make sure the file doesn't exist
    NSString* filename;
    for (int i = 0; i < 10000; ++i) {
        if (i == 0)
            filename = [[savePath stringByAppendingPathComponent: baseName] stringByAppendingPathExtension: suffix];
        else
            filename = [[savePath stringByAppendingPathComponent: 
                        [NSString stringWithFormat: @"%@_%d", baseName, i]] stringByAppendingPathExtension: suffix];
            
        if (![[NSFileManager defaultManager] fileExistsAtPath: filename])
            break;
    }
    
    return filename;
}

- (id)tableView: (NSTableView *)aTableView
    objectValueForTableColumn: (NSTableColumn *)aTableColumn
    row: (int)rowIndex
{
    if ([[aTableColumn identifier] isEqualToString: @"enable"])
        return [NSNumber numberWithBool:[[m_files objectAtIndex: rowIndex] isEnabled]];
    if ([[aTableColumn identifier] isEqualToString: @"progress"])
        return [NSValue valueWithPointer:[m_files objectAtIndex: rowIndex]];
    if ([[aTableColumn identifier] isEqualToString: @"filename"])
        return [[m_files objectAtIndex: rowIndex] inputFileName];
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
    [pboard setString: [[m_files objectAtIndex: m_draggedRow] inputFileName] forType: FileListItemType];
    
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
                    [transcoder addOutputFile: getOutputFileName([filenames objectAtIndex:i], m_savePath, [m_deviceController fileSuffix])];
                    [transcoder setVideoFormat: [m_deviceController videoFormat]];
                    [m_moviePanel setMovie: [filenames objectAtIndex:i]];
                    
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

-(void) setOutputFileName
{
    NSEnumerator* e = [m_files objectEnumerator];
    Transcoder* transcoder;
    NSString* suffix = [m_deviceController fileSuffix];
    NSString* format = [m_deviceController videoFormat];
    
    while ((transcoder = (Transcoder*) [e nextObject])) {
        [transcoder changeOutputFileName: getOutputFileName([transcoder inputFileName], m_savePath, suffix)];
        [transcoder setVideoFormat: format];
    }
}

-(IBAction)clickFileEnable:(id)sender
{
    Transcoder* tr = [m_files objectAtIndex:[sender selectedRow]];
    [tr setEnabled: ![tr isEnabled]];
    [m_fileListView reloadData];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    return [theItem isEnabled];
}

-(void) startNextEncode
{
    if (!m_isTerminated) {
        if (++m_currentEncoding < [m_files count]) {
            [[m_files objectAtIndex: m_currentEncoding] startEncode];
            return;
        }
    }
    else {
        [m_totalProgressBar setDoubleValue: 0];
        [m_fileListView reloadData];
    }
    
    [self setRunState: RS_STOPPED];
}

- (IBAction)startEncode:(id)sender
{
    [m_totalProgressBar setDoubleValue: 0];
    m_isTerminated = NO;
    
    if (m_runState == RS_PAUSED) {
        [[m_files objectAtIndex: m_currentEncoding] resumeEncode];
        [self setRunState: RS_RUNNING];
    }
    else {
        [self setOutputFileName];
        [self setRunState: RS_RUNNING];
    
        m_currentEncoding = -1;
        [self startNextEncode];
    }
}

- (IBAction)pauseEncode:(id)sender
{
    [[m_files objectAtIndex: m_currentEncoding] pauseEncode];
    [self setRunState: RS_PAUSED];
    [m_fileListView reloadData];
}

- (IBAction)stopEncode:(id)sender
{
    m_isTerminated = YES;
    [[m_files objectAtIndex: m_currentEncoding] stopEncode];
    [self setRunState: RS_STOPPED];
    [m_fileListView reloadData];
}

-(IBAction)toggleConsoleDrawer:(id)sender
{
    [m_consoleDrawer toggle:sender];
}

-(IBAction)changeSaveToText:(id)sender
{
    [m_savePath release];
    m_savePath = [m_saveToPathTextField stringValue];
    [m_savePath retain];
    [m_saveToPathTextField abortEditing];
    [m_saveToPathTextField setStringValue:m_savePath];
    [self setOutputFileName];
}

-(IBAction)selectSaveToPath:(id)sender
{
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:NO];
    [panel setCanChooseDirectories:YES];
    [panel setCanCreateDirectories:YES];
    [panel setTitle:@"Choose a Folder"];
    [panel setPrompt:@"Choose"];
    if ([panel runModalForTypes: nil] == NSOKButton) {
        m_savePath = [[panel filenames] objectAtIndex:0];
        [m_savePath retain];
        [m_saveToPathTextField setStringValue:m_savePath];
        [self setOutputFileName];
    }
}

-(void) setProgressFor: (Transcoder*) transcoder to: (double) progress
{
    [m_totalProgressBar setDoubleValue: progress];
    [m_fileListView reloadData];
}

-(void) encodeFinished: (Transcoder*) transcoder
{
    [m_totalProgressBar setDoubleValue: m_isTerminated ? 0 : 1];
    [m_fileListView reloadData];
    [self startNextEncode];
}

-(void) setRunState: (RunStateType) state
{
    m_runState = state;
    switch(m_runState) {
        case RS_STOPPED:
            [m_startEncodeItem setEnabled: YES];
            [m_startEncodeItem setLabel:@"Start"];
            [m_stopEncodeItem setEnabled: NO];
            [m_pauseEncodeItem setEnabled: NO];
            break;
        case RS_RUNNING:
            [m_startEncodeItem setEnabled: NO];
            [m_startEncodeItem setLabel:@"Start"];
            [m_stopEncodeItem setEnabled: YES];
            [m_pauseEncodeItem setEnabled: YES];
            break;
        case RS_PAUSED:
            [m_startEncodeItem setEnabled: YES];
            [m_startEncodeItem setLabel:@"Resume"];
            [m_stopEncodeItem setEnabled: YES];
            [m_pauseEncodeItem setEnabled: NO];
            break;
    }
}

-(DeviceController*) deviceController
{
    return m_deviceController;
}

-(void) log: (NSString*) format, ...
{
    va_list args;
    va_start(args, format);
    NSString* s = [[NSString alloc] initWithFormat:format arguments: args];
    
    // Output to stderr
    fprintf(stderr, [s UTF8String]);
    
    // Output to log file
    [(Transcoder*) [m_files objectAtIndex: m_currentEncoding] logToFile: s];
    [[[m_consoleView textStorage] mutableString] appendString: s];
    
    // scroll to the end
    NSRange range = NSMakeRange ([[m_consoleView string] length], 0);
    [m_consoleView scrollRangeToVisible: range];    
}

@end
