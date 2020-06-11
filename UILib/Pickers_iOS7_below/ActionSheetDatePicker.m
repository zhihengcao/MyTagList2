
#import "ActionSheetDatePicker.h"

@implementation ActionSheetDatePicker
@synthesize selectedDate = _selectedDate;
@synthesize datePickerMode = _datePickerMode;

+ (id)showPickerWithTitle:(NSString *)title 
           datePickerMode:(UIDatePickerMode)datePickerMode selectedDate:(NSDate *)selectedDate                                                                             
                 done:(dateSelectedBlock)done cancelled:(cancelledBlock)cancel origin:(id)origin {
    ActionSheetDatePicker *picker = [[ActionSheetDatePicker alloc] initWithTitle:title datePickerMode:datePickerMode selectedDate:selectedDate done:done cancelled:cancel origin:origin];
    [picker showActionSheetPicker];
    return [picker autorelease];
}

- (id)initWithTitle:(NSString *)title datePickerMode:(UIDatePickerMode)datePickerMode selectedDate:(NSDate *)selectedDate done:(dateSelectedBlock)done cancelled:(cancelledBlock)cancel origin:(id)origin {
    self = [super initWithCancelBlock:cancel origin:origin];
    if (self) {
		_done = [done copy];
        self.title = title;
        self.datePickerMode = datePickerMode;
        self.selectedDate = selectedDate;
    }
    return self;
}

- (void)dealloc {
    self.selectedDate = nil;
    [super dealloc];
}

- (UIView *)configuredPickerView {
    CGRect datePickerFrame = CGRectMake(0, 40, self.viewSize.width, 216);
    UIDatePicker *datePicker = [[[UIDatePicker alloc] initWithFrame:datePickerFrame] autorelease];
    datePicker.datePickerMode = self.datePickerMode;
	datePicker.minuteInterval = 15;
    [datePicker setDate:self.selectedDate animated:NO];
    [datePicker addTarget:self action:@selector(eventForDatePicker:) forControlEvents:UIControlEventValueChanged];
    
    //need to keep a reference to the picker so we can clear the DataSource / Delegate when dismissing (not used in this picker, but just in case somebody uses this as a template for another picker)
    self.pickerView = datePicker;
    
    return datePicker;
}

- (void)notifyTargetSucceed{
	if(_done)
		_done(self.selectedDate);
}

- (void)eventForDatePicker:(id)sender {
    if (!sender || ![sender isKindOfClass:[UIDatePicker class]])
        return;
    UIDatePicker *datePicker = (UIDatePicker *)sender;
    self.selectedDate = datePicker.date;
}

- (void)customButtonPressed:(id)sender {
    UIBarButtonItem *button = (UIBarButtonItem*)sender;
    NSInteger index = button.tag;
    NSAssert((index >= 0 && index < self.customButtons.count), @"Bad custom button tag: %d, custom button count: %d", (int)index, (int)self.customButtons.count);
    NSAssert([self.pickerView respondsToSelector:@selector(setDate:animated:)], @"Bad pickerView for ActionSheetDatePicker, doesn't respond to setDate:animated:");
    NSDictionary *buttonDetails = [self.customButtons objectAtIndex:index];
    NSDate *itemValue = [buttonDetails objectForKey:@"buttonValue"];
    UIDatePicker *picker = (UIDatePicker *)self.pickerView;    
    [picker setDate:itemValue animated:YES];
    [self eventForDatePicker:picker];
}

@end
