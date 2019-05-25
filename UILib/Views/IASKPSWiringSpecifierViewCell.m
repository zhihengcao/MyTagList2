
#import "IASKPSWiringSpecifierViewCell.h"
#import "IASKSettingsReader.h"

@implementation IASKPSWiringSpecifierViewCell

@synthesize title = _title;
@synthesize delegate=_delegate;

+ (IASKPSWiringSpecifierViewCell*) newWithTitle:(NSString*)title delegate:(id<IEditableTableViewCellDelegate>)delegate;
{
	IASKPSWiringSpecifierViewCell* cell =  
	(IASKPSWiringSpecifierViewCell*) [[[NSBundle mainBundle] loadNibNamed:@"IASKPSWiringSpecifierViewCell"
																	   owner:delegate 
																	 options:nil] objectAtIndex:0];
	cell.title.text = title;
	cell.delegate=delegate;
	UIFont *font = [UIFont boldSystemFontOfSize:14.0f];
	NSDictionary *attributes = [NSDictionary dictionaryWithObject:font
														   forKey:UITextAttributeFont];
	[cell.wiring setTitleTextAttributes:attributes
									forState:UIControlStateNormal];
	return [cell retain];
}

-(void)setValue:(unsigned char)value{
	NSMutableIndexSet* selected = [[[NSMutableIndexSet alloc]init] autorelease];
	if(value&4)[selected addIndex:0];
	if(value&2)[selected addIndex:1];
	if(value&1)[selected addIndex:2];
	if(value&32)[selected addIndex:3];
	if(value&16)[selected addIndex:4];
	if(value&128)[selected addIndex:5];
	if(value&64)[selected addIndex:6];
	self.wiring.selectedSegmentIndexes = selected;
}
-(unsigned char)value{
	unsigned char value=0;
	NSIndexSet* indexes =self.wiring.selectedSegmentIndexes;
	if([indexes containsIndex:0])value|=4;
	if([indexes containsIndex:1])value|=2;
	if([indexes containsIndex:2])value|=1;
	if([indexes containsIndex:3])value|=32;
	if([indexes containsIndex:4])value|=16;
	if([indexes containsIndex:5])value|=128;
	if([indexes containsIndex:6])value|=64;
	return value;
}

- (void)dealloc {
	self.title=nil;
	self.wiring=nil;
	[super dealloc];
}
@end
