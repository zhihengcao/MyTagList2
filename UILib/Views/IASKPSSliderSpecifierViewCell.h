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


@interface IASKPSSliderSpecifierViewCell : UITableViewCell {
    UISlider *_slider;
}
+ (UIImage*)offsetThumbImage:(UIImage*)image;

+ (IASKPSSliderSpecifierViewCell*) newWithTitle:(NSString*)title Min:(float)min Max:(float)max Step:(float)step Unit:(NSString*)unit delegate:(id<IEditableTableViewCellDelegate>)delegate;
- (IBAction)valueEditingDidEnd:(id)sender;
- (IBAction)sliderValueChanged:(id)sender;
@property (retain, nonatomic) IBOutlet UITextField *value;
@property (retain, nonatomic) IBOutlet UILabel *title;
@property (nonatomic, assign) IBOutlet UISlider *slider;
@property (nonatomic, assign) IBOutlet UIActivityIndicatorView *loadingViewCell;
@property (nonatomic, assign) id<IEditableTableViewCellDelegate> delegate;
@property (nonatomic, assign) NSString* unit;
@property (nonatomic, assign) float step;
- (IBAction)sliderDraggingDidEnd:(id)sender;

-(void)setVal:(float)value;
-(void)showLoading;
-(void)revertLoading;

@end
