
#import <UIKit/UIKit.h>

#import "IASKSettingsReader.h"

@interface IASKPSTextFieldSpecifierViewCell : UITableViewCell <UITextFieldDelegate>{
}

//@property (retain, nonatomic) IBOutlet UIImageView *rightImageView;
- (IBAction)editingDidEnd:(id)sender;
@property (nonatomic, assign) IBOutlet UILabel *label;
@property (nonatomic, assign) IBOutlet UITextField *textField;
@property (nonatomic, assign) id<IEditableTableViewCellDelegate> delegate;
@property (retain, nonatomic) IBOutlet UIImageView *iconImage;
@property (retain, nonatomic) CAGradientLayer *gradient;

-(void)showLoading;
-(void)revertLoading;
-(void)addSwatch:(NSString*)swatch animated:(BOOL)animated;

+ (IASKPSTextFieldSpecifierViewCell*) newEditableWithPlaceholder:(NSString*)title isLast:(BOOL)isLast delegate:(id<IEditableTableViewCellDelegate>)delegate;
+(IASKPSTextFieldSpecifierViewCell*)newEditableWithTitle:(NSString*)title delegate:(id<IEditableTableViewCellDelegate>)delegate;

+ (IASKPSTextFieldSpecifierViewCell*) newMultipleChoiceWithTitle:(NSString*)title andIcon:(NSString*)iconName;
+ (IASKPSTextFieldSpecifierViewCell*) newMultipleChoiceWithTitle:(NSString*)title;
+ (IASKPSTextFieldSpecifierViewCell*)newReadonlyWithTitle:(NSString*)title andIcon:(NSString*)iconName;
+ (IASKPSTextFieldSpecifierViewCell*)newReadonlyWithTitle:(NSString*)title;
@end

@interface UIPlaceHolderTextView : UITextView

@property (nonatomic, retain) NSString *placeholder;
@property (nonatomic, retain) UIColor *placeholderColor;

-(void)textChanged:(NSNotification*)notification;

@end

@interface IASKPSTextViewSpecifierViewCell : UITableViewCell <UITextViewDelegate>{
}

@property (nonatomic, assign) IBOutlet UIPlaceHolderTextView *textField;
@property (nonatomic, assign) id<IEditableTableViewCellDelegate> delegate;

+ (IASKPSTextViewSpecifierViewCell*) newEditableWithPlaceholder:(NSString*)title delegate:(id<IEditableTableViewCellDelegate>)delegate;
+ (IASKPSTextViewSpecifierViewCell*) newEditableWithText:(NSString*)value delegate:(id<IEditableTableViewCellDelegate>)delegate;

@end
