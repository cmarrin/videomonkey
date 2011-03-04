//
//  ProgressCell.m
//  VideoMonkey
//
//  Created by Chris Marrin on 12/1/08.

/*
Copyright (c) 2009-2011 Chris Marrin (chris@marrin.com)
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

    - Redistributions of source code must retain the above copyright notice, this 
      list of conditions and the following disclaimer.

    - Redistributions in binary form must reproduce the above copyright notice, 
      this list of conditions and the following disclaimer in the documentation 
      and/or other materials provided with the distribution.

    - Neither the name of Video Monkey nor the names of its contributors may be 
      used to endorse or promote products derived from this software without 
      specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY 
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH 
DAMAGE.
*/

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
