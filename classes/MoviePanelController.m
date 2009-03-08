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
    m_isVisible = NO;
    m_movieIsSet = NO;
    m_controlHeight = [[[m_movieView window] contentView] frame].size.height - [m_movieView frame].size.height;
    m_selectionStart = -1;
    m_selectionEnd = -1;
    
    //QTTimeRange range = QTMakeTimeRange(QTMakeTimeWithTimeInterval(5), QTMakeTimeWithTimeInterval(10));
    //[[m_movieView movie] setSelection: range];
    
    //[[m_movieView movie] setAttribute: (NSValue) range forKey: QTMovieCurrentTimeAttribute];
    //[m_movieView movie
}

-(NSTimeInterval) currentMovieTime
{
    QTTime curt = [[m_movieView movie] currentTime];
    NSTimeInterval t;
    QTGetTimeInterval(curt, &t);
    return t;
}

-(void) setMovieSelection
{
    QTTimeRange range = QTMakeTimeRange(QTMakeTimeWithTimeInterval(m_selectionStart), 
                                        QTMakeTimeWithTimeInterval(m_selectionEnd-m_selectionStart));
    [[m_movieView movie] setSelection: range];
}

-(IBAction)startSelection:(id)sender
{
    m_selectionStart = [self currentMovieTime];
    if (m_selectionEnd < 0 || m_selectionEnd <= m_selectionStart)
        m_selectionEnd = m_selectionStart + 0.033;
    [self setMovieSelection];
}

-(IBAction)endSelection:(id)sender
{
    m_selectionEnd = [self currentMovieTime];
    if (m_selectionEnd < 0 || m_selectionEnd <= m_selectionStart)
        m_selectionStart = m_selectionEnd - 0.033;
    [self setMovieSelection];
}

-(IBAction)encodeSelection:(id)sender
{
}

-(void) setMovie:(NSString*) filename
{
    if ([filename isEqualToString:m_filename] && m_movieIsSet)
        return;
    
    [m_filename release];
    m_filename = [filename retain];

    if (m_isVisible) {
        if (m_filename && ![QTMovie canInitWithFile: filename]) {
            NSBeginAlertSheet(@"Can't Show Movie", nil, nil, nil, [m_movieView window], 
                          nil, nil, nil, nil, 
                          @"The movie '%@' can't be opened by QuickTime. Try transcoding it to "
                          "another format (mp4 works well) and then opening that.", [filename lastPathComponent]);
            [m_movieView setMovie:nil];
        }
        else {
            if (m_filename) {
                QTMovie* movie = [QTMovie movieWithFile:filename error:nil];
                [m_movieView setMovie:movie];
            }
            else
                [m_movieView setMovie:nil];
        }
        
        m_movieIsSet = YES;
    }
    else
        m_movieIsSet = NO;
}

-(void) setVisible: (BOOL) b
{
    if (b != m_isVisible) {
        m_isVisible = b;
        if (m_isVisible)
            [self setMovie: m_filename];
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

- (void)sendEvent:(NSEvent *)event
{
    static int i = 0;
    if ([event type] == NSMouseMoved)
        printf("*** sendEvent %d\n", i++);
}

@end
