//
//  AppController.m
//  VideoMonkey
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright 2008 Chris Marrin. All rights reserved.
//

#import "AppController.h"

@implementation AppController

- (void) awakeFromNib
{
	m_files = [[NSMutableArray alloc] init];
}

- (void) acceptFilenameDrag:(NSString *) filename
{
	[m_arrayController addObject:filename];
}

- (BOOL) tableView:(NSTableView *) aTableView acceptDrop:(id <NSDraggingInfo>) info row:(NSInteger) row dropOperation:(NSTableViewDropOperation) operation
{
    printf("***\n");
    return true;
}

- (NSDragOperation) tableView:(NSTableView *) aTableView validateDrop:(id <NSDraggingInfo>) info proposedRow:(NSInteger) row proposedDropOperation:(NSTableViewDropOperation) operation
{
    printf("***\n");
    return NSDragOperationNone;
}

@end
