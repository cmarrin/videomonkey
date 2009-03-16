//
//  FileInfoPanelController.m
//  VideoMonkey
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright 2008 Chris Marrin. All rights reserved.
//

#import "FileInfoPanelController.h"

@implementation FileInfoPanelController

- (void)awakeFromNib {
}

-(void) setVisible: (BOOL) b
{
    if (b != m_isVisible) {
        m_isVisible = b;
        if (m_isVisible)
            // Update info
            ;
    }
}

- (void)windowWillMiniaturize:(NSNotification *)notification
{
    [self setVisible:NO];
}

- (void)windowDidDeminiaturize:(NSNotification *)notification
{
    [self setVisible:YES];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self setVisible:NO];
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
    [self setVisible:YES];
}

@end
