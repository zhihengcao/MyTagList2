//
//  IASKPSSliderSpecifierViewCell.h
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
#import "RangeSlider.h"

@interface IASKPSDualSliderSpecifierViewCell : UITableViewCell <UITextFieldDelegate>{
}

+ (IASKPSDualSliderSpecifierViewCell*) newWithTitle:(NSString*)title Min:(float)min Max:(float)max Unit:(NSString*)unit numberFormat:(NSString*)format delegate:(id<IEditableTableViewCellDelegate>)delegate;
- (IBAction)lowerEditingEnded:(id)sender;
- (IBAction)upperEditingEnded:(id)sender;
- (IBAction)sliderValueChanged:(id)sender;
@property (retain, nonatomic) IBOutlet UILabel *tempUnitRight;

@property(retain, nonatomic) NSString* numberFormat;

@property (retain, nonatomic) IBOutlet UILabel *tempUnitLeft;
@property (retain, nonatomic) IBOutlet UITextField *upper;
@property (retain, nonatomic) IBOutlet UITextField *lower;
@property (retain, nonatomic) IBOutlet UILabel *title;
@property (nonatomic, assign) IBOutlet RangeSlider *slider;
@property (nonatomic, assign) id<IEditableTableViewCellDelegate> delegate;
@property (nonatomic, assign) NSString* unit;

@end
