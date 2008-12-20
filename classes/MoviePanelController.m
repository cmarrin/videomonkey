//
//  MoviePanelController.m
//  VideoMonkey
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright 2008 Chris Marrin. All rights reserved.
//

#import "MoviePanelController.h"
#import <QTKit/QTMovie.h>
#import <QTKit/QTTimeRange.h>

@implementation MoviePanelController

- (void)awakeFromNib {
    //QTTimeRange range = QTMakeTimeRange(QTMakeTimeWithTimeInterval(5), QTMakeTimeWithTimeInterval(10));
    //[[m_movieView movie] setSelection: range];
    
    //[[m_movieView movie] setAttribute: (NSValue) range forKey: QTMovieCurrentTimeAttribute];
    printf("foo\n");
    //[m_movieView movie
}

-(void) setMovie:(NSString*) filename
{
    if (m_isVisible) {
        BOOL canInit = [QTMovie canInitWithFile: filename];
        NSError* error;
        [[m_movieView movie] initWithFile:filename error:&error];
        NSString* errorString = [error localizedDescription];
        m_isMovieSet = YES;
    }
}

-(void) setVisible: (BOOL) b
{
    if (b != m_isVisible) {
        printf("*** movie is becoming %s\n", b ? "visible" : "invisible");
        m_isVisible = b;
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
