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
    id obj = (id) [[self objectValue] pointerValue];
    NSArray* subviews = [controlView subviews];
    if ([subviews count] > 0) {
        id oldobj = [subviews objectAtIndex:0];
        if (oldobj == obj)
            return;
            
        [controlView replaceSubview:oldobj with:obj];
    }
    else
        [controlView addSubview: obj];
        
    if ([obj isKindOfClass:[NSProgressIndicator class]]) {
        // Make the indicator a bit smaller. The setControlSize method
        // doesn’t work in this scenario.
        cellFrame.origin.y += cellFrame.size.height / 4;
        cellFrame.size.height /= 1.5;
    }
    
    [obj setFrame: cellFrame];
}

@end
