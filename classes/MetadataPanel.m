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
#define MONTH_TEXTFIELD 15
#define DAY_TEXTFIELD 20
#define TOTAL_TEXTFIELD 20
#define POPUPBUTTON 25
#define SOURCE_MATRIX 30

@implementation MetadataPanelItem

-(void) awakeFromNib
{
    m_mainTextField = [[self contentView] viewWithTag:MAIN_TEXTFIELD];
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

@implementation MetadataTrackDiskPanelItem

-(void) awakeFromNib
{
    [super awakeFromNib];
    m_totalTextField = [[self contentView] viewWithTag:TOTAL_TEXTFIELD];
}

-(NSString*) value
{
    NSString* total = [m_totalTextField stringValue];
    if (total && [total length] > 0)
        return [NSString stringWithFormat:@"%@/%@", [m_mainTextField stringValue], total];
    else
        return [m_mainTextField stringValue];
}

-(void) setValue:(NSString*) value
{
    NSString* main = value;
    NSString* total = nil;
    
    NSArray* array = [value componentsSeparatedByString:@" of "];
    if (array && [array count] == 2) {
        main = [array objectAtIndex:0];
        total = [array objectAtIndex:1];
    }
    else {
        array = [value componentsSeparatedByString:@"/"];
        if (array && [array count] == 2) {
            main = [array objectAtIndex:0];
            total = [array objectAtIndex:1];
        }
    }
        
    [m_mainTextField setStringValue:value ? main : @""];
    [m_totalTextField setStringValue:value ? total : @""];
}

@end

@implementation MetadataYearPanelItem

-(void) awakeFromNib
{
    [super awakeFromNib];
    m_monthTextField = [[self contentView] viewWithTag:MONTH_TEXTFIELD];
    m_dayTextField = [[self contentView] viewWithTag:DAY_TEXTFIELD];
}

-(NSString*) value
{
    NSString* year = [m_mainTextField stringValue];
    NSString* month = [m_monthTextField stringValue];
    NSString* day = [m_dayTextField stringValue];
    
    if (!year || [year length] == 0)
        return @"";
        
    if (!month || [month length] == 0)
        return year;
        
    if (!day || [day length] == 0)
        return [NSString stringWithFormat:@"%@-%@", year, month];
    
    return [NSString stringWithFormat:@"%@-%@-%@", year, month, day];
}

-(void) setValue:(NSString*) value
{
    NSString* year = value;
    NSString* month = nil;
    NSString* day = nil;
    
    NSArray* array = [value componentsSeparatedByString:@"-"];
    if (array) {
        if ([array count] > 0) {
            year = [array objectAtIndex:0];
            if ([array count] > 1) {
                month = [array objectAtIndex:1];
                if ([array count] > 2)
                    day = [array objectAtIndex:2];
            }
        }
    }
            
    [m_mainTextField setStringValue:value ? year : @""];
    [m_monthTextField setStringValue:value ? month : @""];
    [m_dayTextField setStringValue:value ? day : @""];
}

@end

@implementation MetadataTextViewPanelItem

-(void) awakeFromNib
{
    [super awakeFromNib];
    //m_textView = [[self contentView] viewWithTag:TOTAL_TEXTFIELD];
}

-(NSString*) value
{
    return [m_mainTextField stringValue];
}

-(void) setValue:(NSString*) value
{
    [m_mainTextField setStringValue:value ? value : @""];
}

@end

@implementation MetadataPopUpButtonPanelItem

-(void) awakeFromNib
{
    [super awakeFromNib];
    m_popupButton = [[self contentView] viewWithTag:POPUPBUTTON];
}

-(NSString*) value
{
    return [m_popupButton titleOfSelectedItem];
}

-(void) setValue:(NSString*) value
{
    [m_popupButton selectItemWithTitle:value ? value : @""];
}

@end

@implementation MetadataPanel

@synthesize fileListController = m_fileListController;

@end
