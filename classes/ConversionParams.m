//
//  ConversionParams.m
//  ConversionParams
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright Chris Marrin 2008. All rights reserved.
//

#import "ConversionParams.h"

@implementation ConversionTab
- (bool) h264 {
    return [(NSButton*) m_h264Button state] != 0;
}
@end

@implementation ConversionParams
- (IBAction)selectTab:(id)sender {
    m_currentTabViewItem = [sender representedObject];
    [m_conversionParamsTabView selectTabViewItem: m_currentTabViewItem];
}

- (IBAction)paramChanged:(id)sender {
    printf("paramChanged: quality=%d\n", (int) [m_currentTabViewItem h264]);
}
@end
