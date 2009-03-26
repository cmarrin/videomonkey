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
    
    IBOutlet NSTextField* m_inputFileFormat;
    IBOutlet NSTextField* m_inputFileDuration;
    IBOutlet NSTextField* m_inputFileSize;
    IBOutlet NSTextField* m_inputFileBitrate;

    IBOutlet NSTextField* m_inputFileVideoCodec;
    IBOutlet NSTextField* m_inputFileVideoProfile;
    IBOutlet NSTextField* m_inputFileVideoInterlacing;
    IBOutlet NSTextField* m_inputFileVideoFrameSize;
    IBOutlet NSTextField* m_inputFileVideoAspectRatio;
    IBOutlet NSTextField* m_inputFileVideoFramerate;
    IBOutlet NSTextField* m_inputFileVideoBitrate;

    BOOL m_isVisible;
}

@end
