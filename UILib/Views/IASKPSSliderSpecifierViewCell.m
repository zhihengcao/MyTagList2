//
//  IASKPSSliderSpecifierViewCell.m
//  http://www.inappsettingskit.com
//
//  Copyright (c) 2009-2010:
//  Luc Vandal, Edovia Inc., http://www.edovia.com
//  Ortwin Gentz, FutureTap GmbH, http://www.futuretap.com
//  All rights reserved.
// 
//  It is appreciated but not required that you give credit to Luc Vandal and Ortwin Gentz, 
//  as the original authors of this code. You can give credit in a blog post, a tweet or on 
//  a info page of your app. Also, the original authors appreciate letting them know if you use this code.
//
//  This code is licensed under the BSD license that is available at: http://www.opensource.org/licenses/bsd-license.php
//

#import "IASKPSSliderSpecifierViewCell.h"
#import "IASKSettingsReader.h"

@implementation IASKPSSliderSpecifierViewCell

@synthesize value = _value;
@synthesize title = _title;
@synthesize slider=_slider;
@synthesize delegate=_delegate, unit=_unit;
@synthesize step = _step;

+ (IASKPSSliderSpecifierViewCell*) newWithTitle:(NSString*)title Min:(float)min Max:(float)max Step:(float)step Unit:(NSString*)unit delegate:(id<IEditableTableViewCellDelegate>)delegate
{	
	IASKPSSliderSpecifierViewCell* cell =  
	(IASKPSSliderSpecifierViewCell*) [[[NSBundle mainBundle] loadNibNamed:@"IASKPSSliderSpecifierViewCell"
																	   owner:delegate 
																	 options:nil] objectAtIndex:0];
	cell.slider.maximumValue=max;
	cell.slider.minimumValue=min;
	
	//[cell.slider setThumbImage:[self offsetThumbImage:[UIImage imageNamed:@"handle_center.png"]] forState:UIControlStateNormal];
	
	[cell.slider setMinimumTrackImage:[[UIImage imageNamed:@"bar-highlight.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 0) resizingMode:UIImageResizingModeStretch] forState:UIControlStateNormal];
	[cell.slider setMaximumTrackImage:[[UIImage imageNamed:@"bar-background.png"] resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeStretch] forState:UIControlStateNormal];
	
	cell.step = step;
	
	cell.title.text = title;
	cell.delegate=delegate;
	cell.unit=unit;
	return [cell retain];
}
+(UIImage*)offsetThumbImage:(UIImage*)image {
	CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height+20);
	UIGraphicsBeginImageContextWithOptions(imageRect.size, FALSE, 0.0);
	[image drawInRect:CGRectMake(0, -20, image.size.width, image.size.height)];
	image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return image;
}
/*
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
*/
- (void)dealloc {
	[_title release];
	[_value release];
	self.slider=nil;
	[super dealloc];
}

-(void)showLoading{
	self.userInteractionEnabled =  NO;
	_slider.alpha=0.4;
	[self.loadingViewCell startAnimating];
}
-(void)revertLoading{
	self.userInteractionEnabled =  YES;
	_slider.alpha=1;
	[self.loadingViewCell stopAnimating];
}

- (IBAction)valueEditingDidEnd:(id)sender {
	float f = self.slider.value;
	NSScanner* scanner = [NSScanner scannerWithString:self.value.text];
	if(![scanner scanFloat:&f])return;
	self.slider.value = f;
	[_delegate editedTableViewCell:self];
}
- (IBAction)sliderDraggingDidEnd:(id)sender {
	[_delegate editedTableViewCell:self];
}

-(void)setVal:(float)value{
	self.slider.value=value;
	[self sliderValueChanged:self.slider];
}
- (IBAction)sliderValueChanged:(id)sender {
	self.value.text = [NSString stringWithFormat:@"%g %@", (int)roundf(self.slider.value/_step)*_step, _unit];
}
@end
