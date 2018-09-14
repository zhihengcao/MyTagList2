
#import "OptionsViewController.h"
#import "IASKPSWiringSpecifierViewCell.h"

@interface KumostatOptionsViewController : OptionsViewController<IEditableTableViewCellDelegate>
{
	IASKPSWiringSpecifierViewCell* heat3, *heat2, *heat1, *ac3, *ac2, *ac1, *fan3, *fan2, *fan1;
}

@end
