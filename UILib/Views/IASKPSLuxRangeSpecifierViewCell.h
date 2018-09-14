#import <UIKit/UIKit.h>
#import "IASKSettingsReader.h"

static float  min_range_values[] = {0,10,200,2000,10000};
static float max_range_values[] = {20,1000,5000,30000,80000};

@interface IASKPSLuxRangeSpecifierViewCell : UITableViewCell {
}

+ (IASKPSLuxRangeSpecifierViewCell*) newWithTitle:(NSString*)title delegate:(id<IEditableTableViewCellDelegate>)delegate;

@property (retain, nonatomic) IBOutlet UILabel *title;
@property (nonatomic, assign) id<IEditableTableViewCellDelegate> delegate;
@property (retain, nonatomic) IBOutlet UISegmentedControl *rangeChoice;
@property (assign, nonatomic) NSUInteger range_index;
@end
