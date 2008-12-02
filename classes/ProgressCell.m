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
    return self;
}

// Draw the cell.
- (void) drawInteriorWithFrame : (NSRect) cellFrame inView: (NSView *) controlView
{
    NSProgressIndicator * indicator = [[self objectValue] objectForKey: kControl];

    // Removing subviews is tricky, if the progress bar gets removed when it gets
    // 100%, it could get re-created on resize. This is perhaps kludgy and should
    // be fixed.
    if([indicator doubleValue] < 100) {
        if(![indicator superview])
            [controlView addSubview: indicator];

        // Make the indicator a bit smaller. The setControlSize method
        // doesn’t work in this scenario.
        cellFrame.origin.y += cellFrame.size.height / 3;
        cellFrame.size.height /= 1.5;

        [indicator setFrame: cellFrame];
    }
}

@end
