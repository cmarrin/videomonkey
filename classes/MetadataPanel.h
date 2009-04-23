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
    NSTextField* m_totalTextField;
    NSMatrix* m_sourceMatrix;
}

-(NSString*) key;
-(void) bindToTagItem:() item;

@end

@interface MetadataPanel : NSBox {
    IBOutlet FileListController* m_fileListController;
}

@property (readonly) FileListController* fileListController;

@end
