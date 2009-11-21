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

- (void)awakeFromNib
{
    [[m_movieView window] setExcludedFromWindowsMenu:YES];
    
    m_isVisible = NO;
    m_movieIsSet = NO;
    m_extraContentWidth = [[[m_movieView window] contentView] frame].size.width - [m_movieView frame].size.width;
    m_extraContentHeight = [[[m_movieView window] contentView] frame].size.height - [m_movieView frame].size.height;
    m_extraFrameWidth = [[m_movieView window] frame].size.width - [m_movieView frame].size.width;
    m_extraFrameHeight = [[m_movieView window] frame].size.height - [m_movieView frame].size.height;

    m_selectionStart = -1;
    m_selectionEnd = -1;
    
    m_currentTimeDictionary = [[NSMutableDictionary alloc] init];
    
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

-(void) saveCurrentTime
{
    if (!m_filename)
        return;
        
    BOOL isPaused = [[m_movieView movie] rate] == 0;
        
    [m_movieView pause:self];
    NSTimeInterval currentTime = [self currentMovieTime];
    
    // negative currentTime means we are paused
    if (isPaused && currentTime > 0)
        currentTime = -currentTime;
        
    [m_currentTimeDictionary setValue:[NSNumber numberWithDouble:currentTime] forKey:m_filename];
}

-(void) setMovie:(NSString*) filename
{
    if ([filename isEqualToString:m_filename] && m_movieIsSet)
        return;
    
    [self saveCurrentTime];
    
    [m_filename release];
    m_filename = [filename retain];
    
    // add it to the dictionary if needed
    NSNumber* ct = nil;
    if (m_filename) {
        ct = [m_currentTimeDictionary valueForKey:filename];
        if (!ct) {
            ct = [NSNumber numberWithDouble:0];
            [m_currentTimeDictionary setValue:ct forKey:m_filename];
        }
    }
    
    NSTimeInterval currentTime = ct ? [ct doubleValue] : 0;
    BOOL isPaused = currentTime < 0;
    if (isPaused)
        currentTime = -currentTime;
    if (currentTime == 0)
        isPaused = YES;

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
                [movie setCurrentTime: QTMakeTimeWithTimeInterval(currentTime)];
                if (!isPaused)
                    [movie setRate:1];
                
                // set the aspect ratio of its window
                NSSize size = [[[m_movieView window] contentView] frame].size;
                NSSize movieSize = [(NSValue*) [movie attributeForKey:QTMovieNaturalSizeAttribute] sizeValue];
                float aspectRatio = movieSize.width / movieSize.height;
                float movieControllerHeight = [m_movieView controllerBarHeight];
                
                // The desired width of the movie is the current width minus the extra width
                NSSize desiredMovieSize;
                desiredMovieSize.width = size.width - m_extraContentWidth;
                desiredMovieSize.height = desiredMovieSize.width / aspectRatio;
                size.height = desiredMovieSize.height + m_extraContentHeight + movieControllerHeight;
                
                [[m_movieView window] setContentSize:size];
                [m_movieView setEditable:YES];
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
    [self saveCurrentTime];
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

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)proposedFrameSize
{
    // maintain aspect ration
    NSSize movieSize = [(NSValue*) [[m_movieView movie] attributeForKey:QTMovieNaturalSizeAttribute] sizeValue];
    float aspectRatio = movieSize.width / movieSize.height;
    float movieControllerHeight = [m_movieView controllerBarHeight];
    
    // The desired width of the movie is the current width minus the extra width
    NSSize desiredMovieSize;
    desiredMovieSize.width = proposedFrameSize.width - m_extraFrameWidth;
    desiredMovieSize.height = desiredMovieSize.width / aspectRatio;
    proposedFrameSize.height = desiredMovieSize.height + m_extraFrameHeight + movieControllerHeight;
    
    // determine the aspect ratio
    return proposedFrameSize;
}

@end
