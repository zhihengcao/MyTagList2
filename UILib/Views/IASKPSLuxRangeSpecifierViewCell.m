
#import "IASKPSLuxRangeSpecifierViewCell.h"
#import "IASKSettingsReader.h"

@implementation IASKPSLuxRangeSpecifierViewCell

@synthesize title = _title;
@synthesize delegate=_delegate;
@synthesize range_index=_range_index;

- (IBAction)rangeChanged:(id)sender {
	
	_range_index = self.rangeChoice.selectedSegmentIndex;
	
	[self.delegate editedTableViewCell:self];
}
-(void)setRange_index:(NSUInteger)range_index{
	self.rangeChoice.selectedSegmentIndex = _range_index= range_index;
}

+ (IASKPSLuxRangeSpecifierViewCell*) newWithTitle:(NSString*)title delegate:(id<IEditableTableViewCellDelegate>)delegate;
{
	IASKPSLuxRangeSpecifierViewCell* cell =  
	(IASKPSLuxRangeSpecifierViewCell*) [[[NSBundle mainBundle] loadNibNamed:@"IASKPSLuxRangeSpecifierViewCell"
																	   owner:delegate 
																	 options:nil] objectAtIndex:0];
	cell.title.text = title;
	cell.delegate=delegate;
	UIFont *font = [UIFont boldSystemFontOfSize:14.0f];
	NSDictionary *attributes = [NSDictionary dictionaryWithObject:font
														   forKey:UITextAttributeFont];
	[cell.rangeChoice setTitleTextAttributes:attributes
									forState:UIControlStateNormal];
	cell.rangeChoice.userInteractionEnabled=YES;
	return [cell retain];
}


- (void)dealloc {
	self.title=nil;
	self.rangeChoice=nil;
	[super dealloc];
}
@end
