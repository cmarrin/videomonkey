//
//  ConversionParams.h
//  ConversionParams
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright Chris Marrin 2008. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//#import <Cocoa/NSTabViewItem.h>

@interface ConversionTab : NSTabViewItem {
    IBOutlet id m_h264Button;
}
@end

@interface ConversionParams : NSObject {
    IBOutlet float *m_quality;
    IBOutlet NSTabView* m_conversionParamsTabView;
    IBOutlet NSPopUpButton* m_conversionParamsButton;
    
    ConversionTab* m_currentTabViewItem;
}

- (IBAction)selectTab:(id)sender;
- (IBAction)paramChanged:(id)sender;
@end
