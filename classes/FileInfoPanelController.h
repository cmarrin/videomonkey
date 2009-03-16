//
//  FileInfoPanelController.h
//  VideoMonkey
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright 2008 Chris Marrin. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FileInfoPanelController : NSObject {
@private
    IBOutlet NSTabView* m_fileInfoTabView;

    BOOL m_isVisible;
}

@end
