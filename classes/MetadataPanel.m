//
//  Metadata.m
//  VideoMonkey
//
//  Created by Chris Marrin on 4/2/2009.
//  Copyright 2008 Apple. All rights reserved.
//

#import "MetadataPanel.h"
#import "FileInfoPanelController.h"
#import "Metadata.h"
#import "Transcoder.h"

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
    [m_mainTextField setDelegate:self];
    
    m_sourceMatrix = [[self contentView] viewWithTag:SOURCE_MATRIX];
    self.inputValue = nil;
    self.searchValue = nil;
    self.userValue = nil;
}

-(id) fileListController
{
    return [(MetadataPanel*)[[self superview] superview] fileListController];
}

-(IBAction)useThisValueForAllFiles:(id)sender
{
    NSString* value = [self value];
    NSString* keyPath = [NSString stringWithFormat:@"metadata.tags.%@.displayValue", [self key]];

    NSArray* array = [[self fileListController] arrangedObjects];
    for (Transcoder* transcoder in array) {
        [transcoder setValue:value forKeyPath:keyPath];
    }
    
    [[self fileListController] reloadData];
}

-(NSString*) value
{
    return [m_mainTextField stringValue];
}

-(void) setValue:(NSString*) value
{
    [m_mainTextField setStringValue:value ? value : @""];
}

-(NSString*) valueForSource:(TagType) type
{
    switch (type) {
        case INPUT_TAG:
            return m_inputValue;
        case SEARCH_TAG:
            return m_searchValue;
        case USER_TAG:
            return m_userValue;
    }
    return nil;
}

-(NSButtonCell*) inputButton { return [m_sourceMatrix cellAtRow:0 column:0]; }
-(NSButtonCell*) searchButton { return [m_sourceMatrix cellAtRow:0 column:1]; }
-(NSButtonCell*) userButton { return [m_sourceMatrix cellAtRow:0 column:2]; }

-(NSString*) inputValue { return m_inputValue; }
-(NSString*) searchValue { return m_searchValue; }
-(NSString*) userValue { return m_userValue; }

-(void) setInputValue:(NSString*) value
{
    [value retain];
    [m_inputValue release];
    m_inputValue = value;
    
    BOOL hasValue = value && [value length] > 0;
    [[self inputButton] setTransparent:!hasValue];
    [[self inputButton] setEnabled:hasValue];
}

-(void) setSearchValue:(NSString*) value
{
    [value retain];
    [m_searchValue release];
    m_searchValue = value;
    
    BOOL hasValue = value && [value length] > 0;
    [[self searchButton] setTransparent:!hasValue];
    [[self searchButton] setEnabled:hasValue];
}

-(void) setUserValue:(NSString*) value
{
    [m_userValue release];
    m_userValue = value ? [[NSString stringWithString:value] retain] : nil;
    
    BOOL hasValue = value && [value length] > 0;
    [[self userButton] setTransparent:!hasValue];
    [[self userButton] setEnabled:hasValue];
}

-(NSNumber*) currentSource
{
    return [NSNumber numberWithInt:(int) m_currentSource];
}

-(void) setCurrentSource:(NSNumber*) t
{
    TagType type = (TagType) [t intValue];
    switch(type) {
        case INPUT_TAG:     [self setValue: m_inputValue];  break;
        case SEARCH_TAG:     [self setValue: m_searchValue];  break;
        case USER_TAG:     [self setValue: m_userValue];  break;
    }
    
    [[self inputButton] setBordered:type == INPUT_TAG];
    [[self searchButton] setBordered:type == SEARCH_TAG];
    [[self userButton] setBordered:type == USER_TAG];
}

-(void) controlTextDidChange:(NSNotification*) notification
{
    NSString* value = [self value];
    NSString* keyPath = [NSString stringWithFormat:@"selection.metadata.tags.%@.displayValue", [self key]];
    [[self fileListController] setValue:value forKeyPath:keyPath];
    [[self fileListController] reloadData];
}

-(NSString*) key
{
    return [self title];
}

-(IBAction)sourceMatrixChanged:(id)sender
{
    TagType type = OUTPUT_TAG;
    
    if ([sender selectedCell] == [self inputButton])
        type = INPUT_TAG;
    else if ([sender selectedCell] == [self searchButton])
        type = SEARCH_TAG;
    else if ([sender selectedCell] == [self userButton])
        type = USER_TAG;

    if (type != OUTPUT_TAG) {
        [self setCurrentSource: [NSNumber numberWithInt:(int) type]];
        NSString* keyPath = [NSString stringWithFormat:@"selection.metadata.tags.%@.currentSource", [self key]];
        [[self fileListController] setValue:[NSNumber numberWithInt:(int) type] forKeyPath:keyPath];
        [[self fileListController] reloadData];
    }
}

-(void) bind
{
    // add a context menu
    NSMenu* menu = [[NSMenu alloc]init];
    [menu addItem:[[NSMenuItem alloc] initWithTitle:@"Use this value for all files" 
                                        action:@selector(useThisValueForAllFiles:) 
                                        keyEquivalent:@""]];
    [m_title setMenu:menu];
    [menu release];

    // bind value
    NSString* keyPath = [NSString stringWithFormat:@"selection.metadata.tags.%@.displayValue", [self key]];
    [self bind:@"value" toObject:[self fileListController] withKeyPath:keyPath options: nil];
        
    // bind the value properties
    keyPath = [NSString stringWithFormat:@"selection.metadata.tags.%@.inputValue", [self key]];
    [self bind:@"inputValue" toObject:[self fileListController] withKeyPath:keyPath options: nil];

    keyPath = [NSString stringWithFormat:@"selection.metadata.tags.%@.searchValue", [self key]];
    [self bind:@"searchValue" toObject:[self fileListController] withKeyPath:keyPath options: nil];

    keyPath = [NSString stringWithFormat:@"selection.metadata.tags.%@.userValue", [self key]];
    [self bind:@"userValue" toObject:[self fileListController] withKeyPath:keyPath options: nil];
    
    // bind currentSource
    keyPath = [NSString stringWithFormat:@"selection.metadata.tags.%@.currentSource", [self key]];
    [self bind:@"currentSource" toObject:[self fileListController] withKeyPath:keyPath options: nil];
}

@end

@implementation MetadataTrackDiskPanelItem

-(void) awakeFromNib
{
    [super awakeFromNib];
    m_totalTextField = [[self contentView] viewWithTag:TOTAL_TEXTFIELD];
    [m_totalTextField setDelegate:self];
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
        
    [m_mainTextField setStringValue:main ? main : @""];
    [m_totalTextField setStringValue:total ? total : @""];
}

@end

@implementation MetadataYearPanelItem

-(void) awakeFromNib
{
    [super awakeFromNib];
    m_monthTextField = [[self contentView] viewWithTag:MONTH_TEXTFIELD];
    [m_monthTextField setDelegate:self];
    m_dayTextField = [[self contentView] viewWithTag:DAY_TEXTFIELD];
    [m_dayTextField setDelegate:self];
}

-(NSString*) value
{
    NSString* year = [m_mainTextField stringValue];
    NSString* month = [m_monthTextField stringValue];
    NSString* day = [m_dayTextField stringValue];
    
    if (!year)
        year = @"";
        
    if (!month)
        month = @"";
        
    if (!day)
        day = @"";
        
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
            
    [m_mainTextField setStringValue:year ? year : @""];
    [m_monthTextField setStringValue:month ? month : @""];
    [m_dayTextField setStringValue:day ? day : @""];
}

@end

@implementation MetadataTextViewPanelItem

-(void) textDidChange:(NSNotification*) notification
{
    NSString* value = [self value];
    NSString* keyPath = [NSString stringWithFormat:@"selection.metadata.tags.%@.displayValue", [self key]];
    [[self fileListController] setValue:value forKeyPath:keyPath];
    [[self fileListController] reloadData];
}

-(NSString*) value
{
    return [m_textView string];
}

-(void) setValue:(NSString*) value
{
    [m_textView setString:value ? value : @""];
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

-(IBAction)valueChanged:(id)sender
{
    NSString* value = [self value];
    NSString* keyPath = [NSString stringWithFormat:@"selection.metadata.tags.%@.displayValue", [self key]];
    [[self fileListController] setValue:value forKeyPath:keyPath];
    [[self fileListController] reloadData];
}

@end

@implementation MetadataPanel

@synthesize fileListController = m_fileListController;

-(void) setMetadataSource:(TagType) type
{
    NSNumber* t = [NSNumber numberWithInt:(int) type];
    
    for (MetadataPanelItem* item in [[self contentView] subviews]) {
        if (![item isKindOfClass:[MetadataPanelItem class]])
            continue;
        
        if ([item valueForSource:type])
            [item setCurrentSource:t];
    }
}

-(void) setAllMetadataSource:(TagType) type
{
    for (Transcoder* transcoder in [m_fileListController arrangedObjects])
        [[transcoder metadata] setMetadataSource:type];
    
    [self setMetadataSource:type];
}

-(void) useAllInputValuesForThisFile:(id)sender
{
    [self setMetadataSource:INPUT_TAG];
}

-(void) useAllSearchValuesForThisFile:(id)sender
{
    [self setMetadataSource:SEARCH_TAG];
}

-(void) useAllUserValuesForThisFile:(id)sender
{
    [self setMetadataSource:USER_TAG];
}

-(void) useAllInputValuesForAllFiles:(id)sender
{
    [self setAllMetadataSource:INPUT_TAG];
}

-(void) useAllSearchValuesForAllFiles:(id)sender
{
    [self setAllMetadataSource:SEARCH_TAG];
}

-(void) useAllUserValuesForAllFiles:(id)sender
{
    [self setAllMetadataSource:USER_TAG];
}

-(IBAction)addThisImageToAllFiles:(id)sender
{
    NSImage* image = [m_artworkImageWell image];
    NSString* keyPath = @"metadata.primaryArtwork";

    NSArray* array = [[self fileListController] arrangedObjects];
    for (Transcoder* transcoder in array)
        [transcoder setValue:image forKeyPath:keyPath];
    
    [[self fileListController] reloadData];
}

-(IBAction)uncheckAllArtworkOnAllFiles:(id)sender
{
    NSArray* array = [[self fileListController] arrangedObjects];
    for (Transcoder* transcoder in array)
        [[transcoder metadata] uncheckAllArtwork];
    
    [[self fileListController] reloadData];
}

-(void) setupMetadataPanelBindings
{
    for (MetadataPanelItem* item in [[self contentView] subviews]) {
        if (![item isKindOfClass:[MetadataPanelItem class]])
            continue;
            
        [item bind];
    }
    
    // Add a context menu for the artwork
    NSMenu* menu = [[NSMenu alloc]init];
    [menu addItem:[[NSMenuItem alloc] initWithTitle:@"Add this image to all files" 
                                        action:@selector(addThisImageToAllFiles:) 
                                        keyEquivalent:@""]];
    [menu addItem:[[NSMenuItem alloc] initWithTitle:@"Uncheck all artwork on all files" 
                                        action:@selector(uncheckAllArtworkOnAllFiles:) 
                                        keyEquivalent:@""]];
    [m_artworkTitle setMenu:menu];
}

-(void) setMetadataSearchSpinner:(BOOL) spinning
{
    if (spinning) {
        [m_metadataSearchSpinner setHidden:NO];
        [m_metadataSearchSpinner startAnimation:self];
    }
    else {
        [m_metadataSearchSpinner setHidden:YES];
        [m_metadataSearchSpinner stopAnimation:self];
    }
}

@end
