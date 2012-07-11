//
//  MoviePanelController.m
//  VideoMonkey
//
//  Created by Chris Marrin on 11/12/08.

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

#import "MoviePanelController.h"

#import "AppController.h"
#import <QTKit/QTMovie.h>
#import <QTKit/QTTimeRange.h>

@implementation MoviePanelController

@synthesize avOffsetValid = m_avOffsetValid;

- (BOOL) play
{
    QTMovie* movie = [m_movieView movie];
    return [movie rate] > 0;
}

- (void) setPlay:(BOOL)v
{
    m_isPlaying = v;
    if (m_isScrubbing)
        return;
    QTMovie* movie = [m_movieView movie];
    [movie setRate:v ? 1 : 0];
    if (m_isPlaying)
        [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateSlider) userInfo:nil repeats:NO];
}

- (double)currentTime
{
    QTMovie* movie = [m_movieView movie];
    QTTime durt = [movie duration];
    NSTimeInterval duration;
    QTGetTimeInterval(durt, &duration);
    QTTime curt = [movie currentTime];
    NSTimeInterval t;
    QTGetTimeInterval(curt, &t);
    
    return duration ? (t / duration) : 0;
}

- (void)setCurrentTime:(double)t
{
    if (!m_isScrubbing)
        return;
    QTMovie* movie = [m_movieView movie];
    QTTime durt = [movie duration];
    NSTimeInterval duration;
    QTGetTimeInterval(durt, &duration);
    QTTime curt = QTMakeTimeWithTimeInterval(t * duration);
    [movie setCurrentTime:curt];
}

- (void)removeAvOffset
{
    if (!m_movieIsSet)
        return;
    
    // Get the track to modify
    QTMovie* movie = [m_movieView movie];
    NSArray* tracks = [movie tracks];
    
    // create a QTTimeRange for the offset
    QTTimeRange offset = QTMakeTimeRange(QTMakeTimeWithTimeInterval(0), 
                         QTMakeTimeWithTimeInterval(fabs(m_avOffset)));
    
    // Look for the first 'vide' or 'soun' track
    for (QTTrack* track in tracks) {
        if ((m_avOffset > 0 && [[track attributeForKey:QTTrackMediaTypeAttribute] isEqualToString:@"vide"]) ||
            (m_avOffset < 0 && [[track attributeForKey:QTTrackMediaTypeAttribute] isEqualToString:@"soun"])) {
            [track deleteSegment:offset];
            break;
        }
    }
}

- (CGFloat)avOffset
{
    return m_avOffset;
}

- (void)setAvOffset:(CGFloat) value
{
    self.avOffsetValid = !isnan(m_avOffset);
    
    if (!m_movieIsSet)
        return;
    
    // remove any previously inserted segments
    [self removeAvOffset];

    m_avOffset = value;
    
    if (isnan(m_avOffset))
        return;

    // Get the track to modify
    QTMovie* movie = [m_movieView movie];
    NSArray* tracks = [movie tracks];
    
    // create a QTTimeRange for the offset
    QTTimeRange offset = QTMakeTimeRange(QTMakeTimeWithTimeInterval(0), 
                        QTMakeTimeWithTimeInterval(fabs(m_avOffset)));
    
    // Look for the first 'vide' or 'soun' track
    for (QTTrack* track in tracks) {
        if ((m_avOffset > 0 && [[track attributeForKey:QTTrackMediaTypeAttribute] isEqualToString:@"vide"]) ||
            (m_avOffset < 0 && [[track attributeForKey:QTTrackMediaTypeAttribute] isEqualToString:@"soun"])) {
            [track insertEmptySegmentAt:offset];
            break;
        }
    }
    
    [[AppController instance] uiChanged];
}

- (void)awakeFromNib
{
    [[m_movieView window] setExcludedFromWindowsMenu:YES];
    
    m_isVisible = NO;
    m_movieIsSet = NO;
    NSRect frame = [[m_movieView superview] frame];
    m_currentWidth = frame.size.width;
    m_currentHeight = frame.size.height;
    m_extraContentWidth = [[[m_movieView window] contentView] frame].size.width - m_currentWidth;
    m_extraContentHeight = [[[m_movieView window] contentView] frame].size.height - m_currentHeight;
    m_extraFrameWidth = [[m_movieView window] frame].size.width - m_currentWidth;
    m_extraFrameHeight = [[m_movieView window] frame].size.height - m_currentHeight;

    m_selectionStart = -1;
    m_selectionEnd = -1;
    
    m_currentTimeDictionary = [[NSMutableDictionary alloc] init];

    self.avOffset = nan(0);
    self.avOffsetValid = NO;
    
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

- (void)sliderDone:(id)sender
{
    m_isScrubbing = NO;
    if (m_isPlaying) {
        QTMovie* movie = [m_movieView movie];
        [movie setRate:1];
    }
}

- (void)updateSlider
{
    [self setCurrentTime:self.currentTime];
    if (m_isPlaying && !m_isScrubbing)
        [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateSlider) userInfo:nil repeats:NO];
}

-(IBAction)sliderChanged:(id)sender
{
    if (m_isScrubbing)
        return;
    m_isScrubbing = YES;
    if (m_isPlaying) {
        QTMovie* movie = [m_movieView movie];
        [movie setRate:0];
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sliderDone:) object:sender];
    [self performSelector:@selector(sliderDone:) withObject:sender afterDelay:0.0];
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

- (float)aspectRatio
{
    float totalWidth = m_width + m_padLeft + m_padRight;
    float totalHeight = m_height + m_padTop + m_padBottom;
    float aspectRatio = totalWidth / totalHeight;
    if (!aspectRatio || isnan(aspectRatio) || aspectRatio < 0 || aspectRatio > 20)
        aspectRatio = 1;
    return aspectRatio;
}

- (void)updateFrame
{
    float multiplier = m_currentWidth / m_width;
    NSRect frame = NSMakeRect(m_padLeft * multiplier, m_padBottom * multiplier,
                              (m_currentWidth - m_padLeft - m_padRight) * multiplier,
                              (m_currentHeight - m_padTop - m_padBottom) * multiplier);
    [m_movieView setFrame:frame];
}

- (void)updateWindow
{
    // set the aspect ratio of its window
    float aspectRatio = [self aspectRatio];
    m_currentWidth = m_currentHeight * aspectRatio;
    
    NSSize size;
    size.width = m_currentWidth + m_extraContentWidth;
    size.height = m_currentHeight + m_extraContentHeight;
    [[m_movieView window] setContentSize:size];
    [self updateFrame];
    [m_movieView setEditable:YES];
}

-(void) setMovie:(NSString*) filename withAvOffset:(float) avOffset
{
    if ([filename isEqualToString:m_filename] && m_movieIsSet)
        return;
    
    [self saveCurrentTime];
    
    [m_filename release];
    m_filename = [filename retain];
    [self setAvOffset:avOffset];

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
                    
                [self updateWindow];
            }
            else
                [m_movieView setMovie:nil];
        }
        
        m_movieIsSet = YES;
    }
    else
        m_movieIsSet = NO;
}

-(void) setWidth:(int) width height:(int)height padLeft:(int)padLeft padRight:(int)padRight padTop:(int)padTop padBottom:(int)padBottom
{
    m_width = width;
    m_height = height;
    m_padLeft = padLeft;
    m_padRight = padRight;
    m_padTop = padTop;
    m_padBottom = padBottom;
    [self updateWindow];
}

-(void) setVisible: (BOOL) b
{
    if (b != m_isVisible) {
        m_isVisible = b;
        if (m_isVisible)
            [self setMovie: m_filename withAvOffset:m_avOffset];
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
    // maintain aspect ratio
    float aspectRatio = [self aspectRatio];
    
    // The desired width of the movie is the current width minus the extra width
    m_currentHeight = proposedFrameSize.height - m_extraFrameHeight;
    m_currentWidth = m_currentHeight * aspectRatio;
    proposedFrameSize.width = m_currentWidth + m_extraFrameWidth;
    [self updateFrame];
    return proposedFrameSize;
}

@end
