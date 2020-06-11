#import "AbstractActionSheetPicker.h"

typedef void (^dateSelectedBlock)(NSDate* date);

@interface ActionSheetDatePicker : AbstractActionSheetPicker
{
	dateSelectedBlock _done;
}
@property (nonatomic, assign) UIDatePickerMode datePickerMode;
@property (nonatomic, retain) NSDate *selectedDate;

+ (id)showPickerWithTitle:(NSString *)title datePickerMode:(UIDatePickerMode)datePickerMode selectedDate:(NSDate *)selectedDate done:(dateSelectedBlock)done cancelled:(cancelledBlock)cancel origin:(id)origin;

- (id)initWithTitle:(NSString *)title datePickerMode:(UIDatePickerMode)datePickerMode selectedDate:(NSDate *)selectedDate done:(dateSelectedBlock)done cancelled:(cancelledBlock)cancel origin:(id)origin;

- (void)eventForDatePicker:(id)sender;

@end
