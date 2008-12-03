//
//  ProgressCell.h
//  VideoMonkey
//
//  Created by Chris Marrin on 12/1/08.
//  Copyright 2008 Apple. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// Some handy definitions.
#define kControl @"control"

@interface ProgressCell : NSCell {
}

// Initialize.
- (id) init;

// Draw the cell.
- (void) drawInteriorWithFrame : (NSRect) cellFrame inView: (NSView *) controlView;

@end
