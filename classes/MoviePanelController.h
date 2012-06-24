//
//  MoviePanelController.h
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

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>

@interface MoviePanelController : NSObjectController {
    IBOutlet QTMovieView* m_movieView;
    
@private
    BOOL m_isVisible;
    BOOL m_movieIsSet;
    NSString* m_filename;
    int m_extraContentWidth;
    int m_extraContentHeight;
    int m_extraFrameWidth;
    int m_extraFrameHeight;
    NSTimeInterval m_selectionStart;
    NSTimeInterval m_selectionEnd;
    CGFloat m_avOffset;
    BOOL m_avOffsetValid;
    int m_width, m_height, m_padLeft, m_padRight, m_padTop, m_padBottom;
    double m_aspect;
    
    NSMutableDictionary* m_currentTimeDictionary;
}

@property(assign) CGFloat avOffset;
@property(assign) BOOL avOffsetValid;

-(IBAction)startSelection:(id)sender;
-(IBAction)endSelection:(id)sender;
-(IBAction)encodeSelection:(id)sender;

-(void) setMovie:(NSString*) filename withAvOffset:(float) avOffset;

-(void) setWidth:(int) width height:(int)height aspect:(double)aspect padLeft:(int)padLeft padRight:(int)padRight padTop:(int)padTop padBottom:(int)padBottom;

@end
