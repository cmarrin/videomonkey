//
//  MetadataPanel.h
//  VideoMonkey
//
//  Created by Chris Marrin on 4/2/2009.

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

typedef enum { INPUT_TAG, SEARCH_TAG, USER_TAG, OUTPUT_TAG } TagType;

@interface MetadataPanelItem : NSBox /* <NSTextFieldDelegate> */ {
    IBOutlet NSTextField* m_title;
    NSTextField* m_mainTextField;
    NSMatrix* m_sourceMatrix;
    TagType m_currentSource;
    NSString* m_inputValue;
    NSString* m_searchValue;
    NSString* m_userValue;
}

@property (retain) NSString* inputValue;
@property (retain) NSString* searchValue;
@property (retain) NSString* userValue;

-(IBAction)sourceMatrixChanged:(id)sender;

-(void) bind;

@end

@interface MetadataTrackDiskPanelItem : MetadataPanelItem {
    NSTextField* m_totalTextField;
}

@end

@interface MetadataYearPanelItem : MetadataPanelItem {
    NSTextField* m_monthTextField;
    NSTextField* m_dayTextField;
}

@end

@interface MetadataTextViewPanelItem : MetadataPanelItem {
    IBOutlet NSTextView* m_textView;
}

@end

@interface MetadataPopUpButtonPanelItem : MetadataPanelItem {
    NSPopUpButton* m_popupButton;
}

-(IBAction)valueChanged:(id)sender;

@end

@interface MetadataPanel : NSBox {
    IBOutlet NSTextField* m_artworkTitle;
    IBOutlet NSImageView* m_artworkImageWell;
    IBOutlet NSProgressIndicator* m_metadataSearchSpinner;
}

-(IBAction)useAllInputValuesForThisFile:(id)sender;
-(IBAction)useAllSearchValuesForThisFile:(id)sender;
-(IBAction)useAllUserValuesForThisFile:(id)sender;
-(IBAction)useAllInputValuesForAllFiles:(id)sender;
-(IBAction)useAllSearchValuesForAllFiles:(id)sender;
-(IBAction)useAllUserValuesForAllFiles:(id)sender;

-(void) setupMetadataPanelBindings;

-(void) setMetadataSearchSpinner:(BOOL) spinning;

@end
