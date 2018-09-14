//
//  IASKPSThermostatViewCell.m
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

#import "IASKPSThermostatViewCell.h"
#import "IASKSettingsReader.h"

@implementation IASKPSThermostatViewCell

@synthesize th_low=_th_low, th_high=_th_high;
@synthesize title = _title;
@synthesize slider=_slider;
@synthesize delegate=_delegate, useDegF=_useDegF;
@synthesize step = _step;

+ (IASKPSThermostatViewCell*) newWithDelegate:(id<IEditableTableViewCellDelegate>)delegate useDegF:(BOOL)useDegF
{	
	IASKPSThermostatViewCell* cell =  
	(IASKPSThermostatViewCell*) [[[NSBundle mainBundle] loadNibNamed:@"IASKPSThermostatViewCell"
																	   owner:delegate 
																	 options:nil] objectAtIndex:0];
	cell.useDegF=useDegF;
	cell.slider.maximumValue=32; //(50-32)*5.0/9.0;  //50;
	cell.slider.minimumValue=10; //(90-32)*5.0/9.0; //0;
	cell.step = 0.5;
	cell.delegate=delegate;
	
/*	UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 50)];
    numberToolbar.barStyle = UIBarStyleBlackTranslucent;
    numberToolbar.items = [NSArray arrayWithObjects:
						   [[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:cell action:@selector(cancelNumberPad)],
						   [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
						   [[UIBarButtonItem alloc]initWithTitle:@"Set" style:UIBarButtonItemStyleDone target:cell action:@selector(doneWithNumberPad)],
						   nil];
    [numberToolbar sizeToFit];
    cell.th_low.inputAccessoryView = numberToolbar;
    cell.th_high.inputAccessoryView = numberToolbar;*/
	
	return [cell retain];
}
/*-(void)cancelNumberPad{
	[self updateValueText];
	if([self.th_high isFirstResponder])
		[self.th_high resignFirstResponder];
	else if([self.th_low isFirstResponder])
		[self.th_low resignFirstResponder];
}

-(void)doneWithNumberPad{
	if([self.th_high isFirstResponder])
		[self.th_high resignFirstResponder];
	else if([self.th_low isFirstResponder])
		[self.th_low resignFirstResponder];
}*/
-(BOOL) textFieldShouldReturn:(UITextField *)textField{
	[textField resignFirstResponder];
	if(textField == _th_low){
		[_th_high becomeFirstResponder];
		return NO;
	}else

	return YES;
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
	[_th_low release];
	[_th_high release];
	[_slider release];
	[_loadingViewCell release];
	[_hvacOn release];
	[_fanOn release];
	[_tempUnit release];
	[_tempUnitLeft release];
    [_homeAwayLabel release];
	[super dealloc];
}
- (IBAction)valueEditingDidEnd:(id)sender {
	float f;
	UITextField* t = sender;
	NSScanner* scanner = [NSScanner scannerWithString:t.text];
	if(![scanner scanFloat:&f]){
		[self updateValueText];
		return;
	}
	if(_useDegF)
		f=(f-32)*5/9;
	
	if(t==_th_low){
		
		if(f>_slider.setValueHigh - _slider.minimumRange){
			f=_slider.setValueHigh - _slider.minimumRange;
		}
		if(self.slider.setValueLow!=f){
			self.slider.setValueLow = f;
			[self.slider setNeedsLayout];
			[self.slider startAnimation];
			//[self updateValueText];
			[_delegate editedTableViewCell:self];
		}
	}else{
		if(f<_slider.setValueLow+_slider.minimumRange){
			f=_slider.setValueLow+_slider.minimumRange;
		}

		if(self.slider.setValueHigh!=f){
			self.slider.setValueHigh = f;
			[self.slider setNeedsLayout];
			[self.slider startAnimation];
			//[self updateValueText];
			[_delegate editedTableViewCell:self];
		}
	}
}
/*-(void)setVal:(float)value{
	self.slider.setValue=value;
	[self sliderValueChanged:self.slider];
}*/
-(void)updateValueText{
	if(_useDegF){
		_th_high.text = [NSString stringWithFormat:@"%.1f", (self.slider.setValueHigh*9.0/5.0+32.0)];
		_th_low.text = [NSString stringWithFormat:@"%.1f", (self.slider.setValueLow*9.0/5.0+32.0)];
	}else{
		_th_low.text = [NSString stringWithFormat:@"%.1f", self.slider.setValueLow];
		_th_high.text = [NSString stringWithFormat:@"%.1f", self.slider.setValueHigh];
	}
}
-(void)setUseDegF:(BOOL)useDegF{
	_useDegF=useDegF;
	self.tempUnit.text=self.tempUnitLeft.text=_useDegF?@"°F":@"°C";
	
	[self updateValueText];	
}
- (IBAction)sliderValueChanged:(id)sender {
	[self updateValueText];
}
- (IBAction)sliderValueEditEnded:(id)sender {
	[_delegate editedTableViewCell:self];
}
-(int)findZoneThHigh:(float)thHigh ThLow:(float)thLow Current:(float)current{
	if(current<thLow)return -1;
	else if(current>thHigh)return 1;
	else return 0;
}
-(void)setThHgh:(float)thHigh ThLow:(float)thLow currentDegC:(float)current  rangeMin:(float)rangeMin rangeMax:(float)rangeMax stepSize:(float)stepSize{
	int zoneNew = [self findZoneThHigh:thHigh ThLow:thLow Current:current];
	int zoneOld = [self findZoneThHigh:_slider.setValueHigh ThLow:_slider.setValueLow Current:_slider.currentValue];

	if(rangeMax!=0 && stepSize!=0){
		self.slider.maximumValue=rangeMax;
		self.slider.minimumValue=rangeMin;
		self.slider.stepSize = stepSize;
	}

	self.slider.setValueHigh = 150; // allows any low value to be set. 
	self.slider.setValueLow = thLow;
	self.slider.setValueHigh = thHigh;
	self.slider.currentValue = current;
	[self.slider setNeedsLayout];
	if(zoneNew!=zoneOld)
		[self.slider startAnimation];
	[self sliderValueChanged:self.slider];
}

-(void)showLoading{
	//	self.label.alpha = self.textLabel.alpha = 0.439216f;
	self.userInteractionEnabled =  NO;
	[self.slider showLoading];
	[self.loadingViewCell startAnimating];
}
-(void)revertLoading{
	//	self.label.alpha = self.textLabel.alpha =1;
	self.userInteractionEnabled =  YES;
	[self.slider revertLoading];
	[self.loadingViewCell stopAnimating];
}

- (IBAction)valueEditDidBegin:(id)sender {
	((UITextField*)sender).text=@"";
}

- (IBAction)hvacOnChanged:(id)sender {
	[_delegate editedTableViewCell:sender];
}

- (IBAction)fanOnChanged:(id)sender {
	[_delegate editedTableViewCell:sender];
}
@end
