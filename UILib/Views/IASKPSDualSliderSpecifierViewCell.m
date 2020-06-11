#import "IASKPSDualSliderSpecifierViewCell.h"
#import "IASKSlider.h"
#import "IASKSettingsReader.h"

@implementation IASKPSDualSliderSpecifierViewCell

@synthesize upper = _upper, lower=_lower;
@synthesize title = _title;
@synthesize slider=_slider;
@synthesize delegate=_delegate, unit=_unit;

+ (IASKPSDualSliderSpecifierViewCell*) newWithTitle:(NSString*)title Min:(float)min Max:(float)max Unit:(NSString*)unit numberFormat:(NSString*)format delegate:(id<IEditableTableViewCellDelegate>)delegate
{	
	IASKPSDualSliderSpecifierViewCell* cell =  
	(IASKPSDualSliderSpecifierViewCell*) [[[NSBundle mainBundle] loadNibNamed:@"IASKPSDualSliderSpecifierViewCell"
																	   owner:delegate 
																	 options:nil] objectAtIndex:0];
	cell.slider.minimumRange=0.1;
	cell.slider.stepSize=1;
	cell.slider.maximumValue=max;
	cell.slider.minimumValue=min;
	cell.title.text = title;
	cell.delegate=delegate;
	cell.unit=unit;
	cell.numberFormat = format;
	
	
	UIToolbar *upperToolbar = [[[UIToolbar alloc] init] autorelease];
	[upperToolbar setItems:@[
							 [[[UIBarButtonItem alloc] initWithTitle:@"+/-"
															  style:UIBarButtonItemStyleBordered target:cell
															 action:@selector(upperNegateClicked:)] autorelease],
							 [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL] autorelease],
													[[[UIBarButtonItem alloc] initWithTitle:@"Done"
																		style:UIBarButtonItemStyleBordered target:cell
															 action:@selector(upperEditDoneClicked:)] autorelease]]];
	[upperToolbar sizeToFit];
	cell.upper.inputAccessoryView = upperToolbar;

	UIToolbar *lowerToolbar = [[[UIToolbar alloc] init] autorelease];
	[lowerToolbar setItems:@[ [[[UIBarButtonItem alloc] initWithTitle:@"+/-"
															  style:UIBarButtonItemStyleBordered target:cell
															 action:@selector(lowerNegateClicked:)] autorelease],
							  [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL] autorelease],
											[[[UIBarButtonItem alloc] initWithTitle:@"Done"
															  style:UIBarButtonItemStyleBordered target:cell
															 action:@selector(lowerEditDoneClicked:)] autorelease]  ]];
	[lowerToolbar sizeToFit];
	cell.lower.inputAccessoryView = lowerToolbar;
	
	return [cell retain];
}
/*-(BOOL) textFieldShouldReturn:(UITextField *)textField{
	[textField resignFirstResponder];
	if(textField == _lower){
		[_upper becomeFirstResponder];
		return NO;
	}else
		return YES;
}*/
-(IBAction)upperNegateClicked:(id)sender{
	NSString* text = _upper.text;
	if(text.length==0)return;

	if([text characterAtIndex:0]=='-') _upper.text = [text substringFromIndex:1];
	else _upper.text = [@"-" stringByAppendingString:text];
}
-(IBAction)lowerNegateClicked:(id)sender{
	NSString* text = _lower.text;
	if(text.length==0)return;
	
	if([text characterAtIndex:0]=='-') _lower.text = [text substringFromIndex:1];
	else _lower.text = [@"-" stringByAppendingString:text];
}

- (IBAction)upperEditDoneClicked:(id)sender
{
	[_upper resignFirstResponder];
}
- (IBAction)lowerEditDoneClicked:(id)sender
{
	[_lower resignFirstResponder];
}

- (IBAction)lowerEditingEnded:(id)sender {
	float f;
	NSScanner* scanner = [NSScanner scannerWithString:self.lower.text];
	if(![scanner scanFloat:&f])return;
	if(f>_slider.selectedMaximumValue - _slider.minimumRange){
		f=_slider.selectedMaximumValue - _slider.minimumRange;
	}
	_slider.selectedMinimumValue = f;
	[_delegate editedTableViewCell:self];
	[self sliderValueChanged:nil];
}

- (IBAction)upperEditingEnded:(id)sender {
	float f;
	NSScanner* scanner = [NSScanner scannerWithString:self.upper.text];
	if(![scanner scanFloat:&f])return;
		
	if(f<_slider.selectedMinimumValue+_slider.minimumRange){
		f=_slider.selectedMinimumValue+_slider.minimumRange;
	}
	_slider.selectedMaximumValue = f;
	[_delegate editedTableViewCell:self];
	[self sliderValueChanged:nil];
}

- (void)layoutSubviews {
    [super layoutSubviews];
	CGRect  sliderBounds    = _slider.bounds;
    CGPoint sliderCenter    = _slider.center;
    const double superViewWidth = _slider.superview.frame.size.width;
    
    sliderCenter.x = superViewWidth / 2;
    sliderBounds.size.width = superViewWidth - kIASKSliderNoImagesPadding * 2;

	// Check if there are min and max images. If so, change the layout accordingly.	
	_slider.bounds = sliderBounds;
    _slider.center = sliderCenter;
}	

- (void)dealloc {
	[_title release];
	[_upper release]; [_lower release];
	self.slider=nil;
	[_tempUnitLeft release];
	[_tempUnitRight release];
	self.numberFormat=nil;
	[super dealloc];
}
-(void) setUnit:(NSString *)unit{
	_tempUnitLeft.text = _tempUnitRight.text = unit;
}
- (IBAction)sliderValueChanged:(id)sender {
	self.lower.text = [NSString stringWithFormat:self.numberFormat, self.slider.selectedMinimumValue];
	self.upper.text = [NSString stringWithFormat:self.numberFormat, self.slider.selectedMaximumValue];
	[_slider setNeedsLayout];
	[_delegate editedTableViewCell:self];
}
@end
