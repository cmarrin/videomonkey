//
//  MetadataPanel.h
//  VideoMonkey
//
//  Created by Chris Marrin on 4/2/2009.
//  Copyright 2008 Apple. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class FileListController;

@interface MetadataPanelItem : NSBox {
    NSTextField* m_mainTextField;
    NSMatrix* m_sourceMatrix;
}

-(void) bindToTagItem:() item;

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

@end

@interface MetadataPanel : NSBox {
    IBOutlet FileListController* m_fileListController;
}

@property (readonly) FileListController* fileListController;

@end
