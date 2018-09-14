//
//  IASKPSThermostatViewCell.h
//  http://www.inappsettingskit.com
//
//  Copyright (c) 2009:
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

#import <UIKit/UIKit.h>
#import "IASKSettingsReader.h"
#import "ThermostatSlider.h"

@interface IASKPSThermostatViewCell : UITableViewCell <UITextFieldDelegate> {
}

+ (IASKPSThermostatViewCell*) newWithDelegate:(id<IEditableTableViewCellDelegate>)delegate useDegF:(BOOL)useDegF;
- (IBAction)valueEditingDidEnd:(id)sender;
- (IBAction)sliderValueChanged:(id)sender;
@property (retain, nonatomic) IBOutlet UILabel *tempUnitLeft;
@property (retain, nonatomic) IBOutlet UITextField *th_high;
@property (retain, nonatomic) IBOutlet UILabel *title;
@property (retain, nonatomic) IBOutlet ThermostatSlider *slider;
- (IBAction)sliderValueEditEnded:(id)sender;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *loadingViewCell;
@property (retain, nonatomic) IBOutlet UISwitch *hvacOn;
@property (retain, nonatomic) IBOutlet UISwitch *fanOn;
@property (retain, nonatomic) IBOutlet UILabel *tempUnit;
@property (retain, nonatomic) IBOutlet UITextField *th_low;
- (IBAction)valueEditDidBegin:(id)sender;
@property (retain, nonatomic) IBOutlet UILabel *homeAwayLabel;

- (IBAction)hvacOnChanged:(id)sender;

- (IBAction)fanOnChanged:(id)sender;
@property (nonatomic, assign) id<IEditableTableViewCellDelegate> delegate;
@property (nonatomic, assign) float step;
@property (nonatomic, assign) BOOL useDegF;
-(void)showLoading;
-(void)revertLoading;
-(void)setThHgh:(float)thHigh ThLow:(float)thLow currentDegC:(float)current rangeMin:(float)rangeMin rangeMax:(float)rangeMax stepSize:(float)stepSize;
@end
