#import "ActionSheetStringPicker.h"

@interface ActionSheetStringPicker()
@property (nonatomic,retain) NSArray *data;
@property (nonatomic,assign) NSInteger selectedIndex;
@end

@implementation ActionSheetStringPicker
@synthesize data = _data;
@synthesize selectedIndex = _selectedIndex;
@synthesize onActionSheetDone = _onActionSheetDone;
@synthesize onActionSheetCancel = _onActionSheetCancel;

+ (id)showPickerWithTitle:(NSString *)title rows:(NSArray *)strings initialSelection:(NSInteger)index doneBlock:(ActionStringDoneBlock)doneBlock cancelBlock:(ActionStringCancelBlock)cancelBlockOrNil origin:(id)origin {
    ActionSheetStringPicker * picker = [[ActionSheetStringPicker alloc] initWithTitle:title rows:strings initialSelection:index doneBlock:doneBlock cancelBlock:cancelBlockOrNil origin:origin];
    [picker showActionSheetPicker];
    return [picker autorelease];
}

- (id)initWithTitle:(NSString *)title rows:(NSArray *)strings initialSelection:(NSInteger)index doneBlock:(ActionStringDoneBlock)doneBlock cancelBlock:(ActionStringCancelBlock)cancelBlockOrNil origin:(id)origin {

	self = [super initWithCancelBlock:cancelBlockOrNil origin:origin];
    if (self) {
		self.data = strings;
		self.selectedIndex = index;
        self.onActionSheetDone = doneBlock;
        self.onActionSheetCancel = cancelBlockOrNil;
        self.title = title;
    }
    return self;
}

- (void)dealloc {
    self.data = nil;
    
    Block_release(_onActionSheetDone);
    Block_release(_onActionSheetCancel);
    
    [super dealloc];
}

- (UIView *)configuredPickerView {
    if (!self.data)
        return nil;
    CGRect pickerFrame = CGRectMake(0, 40, self.viewSize.width, 216);
    UIPickerView *stringPicker = [[[UIPickerView alloc] initWithFrame:pickerFrame] autorelease];
    stringPicker.delegate = self;
    stringPicker.dataSource = self;
    stringPicker.showsSelectionIndicator = YES;
    [stringPicker selectRow:self.selectedIndex inComponent:0 animated:NO];
    
    //need to keep a reference to the picker so we can clear the DataSource / Delegate when dismissing
    self.pickerView = stringPicker;
    
    return stringPicker;
}

- (void)notifyTargetSucceed{
    if (self.onActionSheetDone) {
        _onActionSheetDone(self, self.selectedIndex, [self.data objectAtIndex:self.selectedIndex]);
        return;
    }
}

#pragma mark - UIPickerViewDelegate / DataSource

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.selectedIndex = row;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.data.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [self.data objectAtIndex:row];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    return pickerView.frame.size.width - 30;
}

#pragma mark - Block setters

    // NOTE: Sometimes see crashes when relying on just the copy property. Using Block_copy ensures correct behavior

- (void)setOnActionSheetDone:(ActionStringDoneBlock)onActionSheetDone {
    if (_onActionSheetDone) {
        Block_release(_onActionSheetDone);
        _onActionSheetDone = nil;
    }
    _onActionSheetDone = Block_copy(onActionSheetDone);
}

- (void)setOnActionSheetCancel:(ActionStringCancelBlock)onActionSheetCancel {
    if (_onActionSheetCancel) {
        Block_release(_onActionSheetCancel);
        _onActionSheetCancel = nil;
    }
    _onActionSheetCancel = Block_copy(onActionSheetCancel);
}

@end