#import <Cocoa/Cocoa.h>
//#import <Cocoa/NSTabViewItem.h>

@interface ConversionTab : NSTabViewItem {
    IBOutlet id m_h264Button;
}
@end

@interface ConversionParams : NSObject {
    IBOutlet float *m_quality;
    IBOutlet id m_conversionParamsTabView;
    
    ConversionTab* m_currentTabViewItem;
}
- (IBAction)selectTab:(id)sender;
- (IBAction)paramChanged:(id)sender;
@end
