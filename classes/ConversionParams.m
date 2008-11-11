#import "ConversionParams.h"

@implementation ConversionParams
- (IBAction)selectTab:(id)sender {
    [conversionParamsTabView selectTabViewItem: [sender representedObject]];
}
@end
