//
//  Metadata.m
//  VideoMonkey
//
//  Created by Chris Marrin on 4/2/2009.
//  Copyright 2008 Apple. All rights reserved.
//

#import "MetadataPanel.h"
#import "FileInfoPanelController.h"

#define MAIN_TEXTFIELD 10
#define TOTAL_TEXTFIELD 20
#define SOURCE_MATRIX 30

@implementation MetadataPanelItem

-(void) awakeFromNib
{
    m_mainTextField = [[self contentView] viewWithTag:MAIN_TEXTFIELD];
    m_totalTextField = [[self contentView] viewWithTag:TOTAL_TEXTFIELD];
    m_sourceMatrix = [[self contentView] viewWithTag:SOURCE_MATRIX];
}

-(id) fileListController
{
    return [(MetadataPanel*)[[self superview] superview] fileListController];
}

-(NSString*) value
{
    return [m_mainTextField stringValue];
}

-(void) setValue:(NSString*) value
{
    [m_mainTextField setStringValue:value ? value : @""];
}

-(NSString*) key
{
    return [self title];
}

-(void) bindToTagItem:(id) item
{
    NSString* keyPath = [NSString stringWithFormat:@"selection.metadata.tags.%@.displayValue", [self key]];
    [self bind:@"value" toObject:[self fileListController] withKeyPath:keyPath options:nil];
}

@end

@implementation MetadataPanel

@synthesize fileListController = m_fileListController;

@end
