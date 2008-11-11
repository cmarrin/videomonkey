#import <Cocoa/Cocoa.h>

@interface ConversionParams : NSObject {
    IBOutlet float *quality;
    IBOutlet id conversionParamsTabView;
}
- (IBAction)selectTab:(id)sender;
@end
