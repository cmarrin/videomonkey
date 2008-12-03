//
//  ProgressCell.m
//  VideoMonkey
//
//  Created by Chris Marrin on 12/1/08.
//  Copyright 2008 Apple. All rights reserved.
//

#import "ProgressCell.h"


@implementation ProgressCell

// Constructor.
- (id) init
{
    self = [super initImageCell: nil];
    
    
    // This creates a progress bar for the table cell
    m_progressIndicator = [[NSProgressIndicator alloc] init];
    //m_progressBar = [NSDictionary dictionaryWithObjectsAndKeys: progress, @"control", 0];
    
    // testing. set the bar to a value
    [m_progressIndicator setMaxValue:1];
    [m_progressIndicator setDoubleValue:4];
    [m_progressIndicator setIndeterminate: NO];

    return self;
}

// Draw the cell.
- (void) drawInteriorWithFrame : (NSRect) cellFrame inView: (NSView *) controlView
{
    // Removing subviews is tricky, if the progress bar gets removed when it gets
    // 100%, it could get re-created on resize. This is perhaps kludgy and should
    // be fixed.
    if([m_progressIndicator doubleValue] < 100) {
        if(![m_progressIndicator superview])
            [controlView addSubview: m_progressIndicator];

        // Make the indicator a bit smaller. The setControlSize method
        // doesn’t work in this scenario.
        cellFrame.origin.y += cellFrame.size.height / 3;
        cellFrame.size.height /= 1.5;

        [m_progressIndicator setFrame: cellFrame];
    }
}

- (void)setObjectValue:(id < NSCopying >) object
{
    NSObject* obj = (NSObject*) object;
    if ([obj isKindOfClass: [NSNumber class]])
        [m_progressIndicator setDoubleValue:[(NSNumber*) obj doubleValue]];
    else if ([obj isKindOfClass: [NSString class]])
        [m_progressIndicator setDoubleValue:[(NSString*) obj doubleValue]];
}

@end
