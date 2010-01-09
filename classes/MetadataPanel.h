//
//  MetadataPanel.h
//  VideoMonkey
//
//  Created by Chris Marrin on 4/2/2009.
//  Copyright 2008 Apple. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum { INPUT_TAG, SEARCH_TAG, USER_TAG, OUTPUT_TAG } TagType;

@class FileListController;

@interface MetadataPanelItem : NSBox {
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
    IBOutlet FileListController* m_fileListController;
    IBOutlet NSTextField* m_artworkTitle;
    IBOutlet NSImageView* m_artworkImageWell;
    IBOutlet NSProgressIndicator* m_metadataSearchSpinner;
}

@property (readonly) FileListController* fileListController;

-(IBAction)useAllInputValuesForThisFile:(id)sender;
-(IBAction)useAllSearchValuesForThisFile:(id)sender;
-(IBAction)useAllUserValuesForThisFile:(id)sender;
-(IBAction)useAllInputValuesForAllFiles:(id)sender;
-(IBAction)useAllSearchValuesForAllFiles:(id)sender;
-(IBAction)useAllUserValuesForAllFiles:(id)sender;

-(void) setupMetadataPanelBindings;

-(void) setMetadataSearchSpinner:(BOOL) spinning;

@end
