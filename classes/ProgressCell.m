//
//  ProgressCell.m
//  VideoMonkey
//
//  Created by Chris Marrin on 12/1/08.
//  Copyright 2008 Apple. All rights reserved.
//

#import "ProgressCell.h"
#import "Transcoder.h"

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
    Transcoder* tr = (Transcoder*) [[self objectValue] pointerValue];
    
    // make sure neither is in the view right now
    [[tr statusImageView] removeFromSuperview];
    [[tr progressIndicator] removeFromSuperview];
    
    // now add the appropriate one
    id obj = ([tr fileStatus] == FS_ENCODING) ? (id) [tr progressIndicator] : (id) [tr statusImageView];
    if ([tr fileStatus] == FS_ENCODING) {
        // Make the indicator a bit smaller. The setControlSize method
        // doesn’t work in this scenario.
        cellFrame.origin.y += cellFrame.size.height / 4;
        cellFrame.size.height /= 1.5;
    }
    
    [controlView addSubview:obj];
    [obj setFrame: cellFrame];
}

@end
