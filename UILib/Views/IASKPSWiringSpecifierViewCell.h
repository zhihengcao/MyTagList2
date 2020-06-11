#import <UIKit/UIKit.h>
#import "IASKSettingsReader.h"
#import "MultiSelectSegmentedControl-Swift.h"

@interface IASKPSWiringSpecifierViewCell : UITableViewCell {
}

- (IBAction)rangeChanged:(id)sender;
+ (IASKPSWiringSpecifierViewCell*) newWithTitle:(NSString*)title delegate:(id<IEditableTableViewCellDelegate>)delegate;

@property (retain, nonatomic) IBOutlet UILabel *title;
@property (nonatomic, assign) id<IEditableTableViewCellDelegate> delegate;
@property (retain, nonatomic) IBOutlet MultiSelectSegmentedControl *wiring;
@property (assign, nonatomic) unsigned char value;
@end
