#import "AbstractActionSheetPicker.h"

@interface AbstractActionSheetPicker()

@property (nonatomic, retain) UIBarButtonItem *barButtonItem;
@property (nonatomic, retain) UIView *containerView;

@property (nonatomic, retain) UIActionSheet *actionSheet;
@property (nonatomic, retain) UIPopoverController *popOverController;
@property (nonatomic, retain) NSObject *selfReference;

- (void)presentPickerForView:(UIView *)aView;
- (void)configureAndPresentPopoverForView:(UIView *)aView;
- (void)configureAndPresentActionSheetForView:(UIView *)aView;
- (void)presentActionSheet:(UIActionSheet *)actionSheet;
- (void)presentPopover:(UIPopoverController *)popover;
- (void)dismissPicker;
- (BOOL)isViewPortrait;

- (UIBarButtonItem *)createToolbarLabelWithTitle:(NSString *)aTitle;
- (UIToolbar *)createPickerToolbarWithTitle:(NSString *)aTitle;
- (UIBarButtonItem *)createButtonWithType:(UIBarButtonSystemItem)type target:(id)target action:(SEL)buttonAction;
- (IBAction)actionPickerDone:(id)sender;
- (IBAction)actionPickerCancel:(id)sender;
@end

@implementation AbstractActionSheetPicker
@synthesize title = _title;
@synthesize containerView = _containerView;
@synthesize barButtonItem = _barButtonItem;
@synthesize actionSheet = _actionSheet;
@synthesize popOverController = _popOverController;
@synthesize selfReference = _selfReference;
@synthesize pickerView = _pickerView;
@dynamic viewSize;
@synthesize customButtons = _customButtons;
@synthesize hideCancel = _hideCancel;
@synthesize presentFromRect = _presentFromRect;

#pragma mark - Abstract Implementation

- (id)initWithCancelBlock:(cancelledBlock)cancel origin:(id)origin{
    self = [super init];
    if (self) {
		_cancelled = [cancel copy];
		
        self.presentFromRect = CGRectZero;
        
		if([origin isKindOfClass:[UITableViewCell class]]){
			self.presentFromRect = ((UITableViewCell*)origin).bounds;
			self.containerView = 	((UITableViewCell*)origin).contentView;	
		}
		else if ([origin isKindOfClass:[UIBarButtonItem class]])
			self.barButtonItem = origin;
		else if ([origin isKindOfClass:[UIView class]]){
			self.containerView = origin;
		}else
			NSAssert(NO, @"Invalid origin provided to ActionSheetPicker ( %@ )", origin);

        //allows us to use this without needing to store a reference in calling class
        self.selfReference = self;
    }
    return self;
}
- (void)dealloc {
    
    //need to clear picker delegates and datasources, otherwise they may call this object after it's gone
    if ([self.pickerView respondsToSelector:@selector(setDelegate:)])
        [self.pickerView performSelector:@selector(setDelegate:) withObject:nil];
    
    if ([self.pickerView respondsToSelector:@selector(setDataSource:)])
        [self.pickerView performSelector:@selector(setDataSource:) withObject:nil];
    
    self.actionSheet = nil;
    self.popOverController = nil;
    self.customButtons = nil;
    self.pickerView = nil;
    self.containerView = nil;
    self.barButtonItem = nil;

	[_cancelled release];
    [super dealloc];
}

- (UIView *)configuredPickerView {
    return nil;
}
- (void)notifyTargetSucceed{
}
- (void)notifyTargetCancel{
	if(_cancelled!=nil)
		_cancelled();
}

#pragma mark - Actions

- (void)showActionSheetPicker {
    UIView *masterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.viewSize.width, 260)];    
    UIToolbar *pickerToolbar = [self createPickerToolbarWithTitle:self.title];
    [pickerToolbar setBarStyle:UIBarStyleBlackTranslucent];
    [masterView addSubview:pickerToolbar];
    self.pickerView = [self configuredPickerView];
    NSAssert(_pickerView != NULL, @"Picker view failed to instantiate, perhaps you have invalid component data.");
    [masterView addSubview:_pickerView];
    [self presentPickerForView:masterView];
    [masterView release];
}

- (IBAction)actionPickerDone:(id)sender {
    [self notifyTargetSucceed];
    [self dismissPicker];
}

- (IBAction)actionPickerCancel:(id)sender {
    [self notifyTargetCancel];
    [self dismissPicker];
}

- (void)dismissPicker {
#if __IPHONE_4_1 <= __IPHONE_OS_VERSION_MAX_ALLOWED
    if (self.actionSheet)
#else
    if (self.actionSheet && [self.actionSheet isVisible])
#endif
        [_actionSheet dismissWithClickedButtonIndex:0 animated:YES];
    else if (self.popOverController && self.popOverController.popoverVisible)
        [_popOverController dismissPopoverAnimated:YES];
    self.actionSheet = nil;
    self.popOverController = nil;
    self.selfReference = nil;
}

#pragma mark - Custom Buttons

- (void)addCustomButtonWithTitle:(NSString *)title value:(id)value {
    if (!self.customButtons)
        _customButtons = [[NSMutableArray alloc] init];
    if (!title)
        title = @"";
    if (!value)
        value = [NSNumber numberWithInt:0];
    NSDictionary *buttonDetails = [[NSDictionary alloc] initWithObjectsAndKeys:title, @"buttonTitle", value, @"buttonValue", nil];
    [self.customButtons addObject:buttonDetails];
    [buttonDetails release];
}

- (IBAction)customButtonPressed:(id)sender {
    UIBarButtonItem *button = (UIBarButtonItem*)sender;
    NSInteger index = button.tag;
    NSAssert((index >= 0 && index < self.customButtons.count), @"Bad custom button tag: %d, custom button count: %d", index, self.customButtons.count);
    NSAssert([self.pickerView respondsToSelector:@selector(selectRow:inComponent:animated:)], @"customButtonPressed not overridden, cannot interact with subclassed pickerView");
    NSDictionary *buttonDetails = [self.customButtons objectAtIndex:index];
    NSAssert(buttonDetails != NULL, @"Custom button dictionary is invalid");
    NSInteger buttonValue = [[buttonDetails objectForKey:@"buttonValue"] intValue];
    UIPickerView *picker = (UIPickerView *)self.pickerView;
    NSAssert(picker != NULL, @"PickerView is invalid");
    [picker selectRow:buttonValue inComponent:0 animated:YES];

    if ([self respondsToSelector:@selector(pickerView:didSelectRow:inComponent:)]) {
        void (*objc_msgSendTyped)(id self, SEL _cmd, id pickerView, NSInteger row, NSInteger component) = (void*)objc_msgSend; // sending Integers as params
        objc_msgSendTyped(self, @selector(pickerView:didSelectRow:inComponent:), picker, buttonValue, 0);
    }
}

- (UIToolbar *)createPickerToolbarWithTitle:(NSString *)title  {
    CGRect frame = CGRectMake(0, 0, self.viewSize.width, 44);
    UIToolbar *pickerToolbar = [[[UIToolbar alloc] initWithFrame:frame] autorelease];
    pickerToolbar.barStyle = UIBarStyleBlackOpaque;
    NSMutableArray *barItems = [[NSMutableArray alloc] init];
    NSInteger index = 0;
    for (NSDictionary *buttonDetails in self.customButtons) {
        NSString *buttonTitle = [buttonDetails objectForKey:@"buttonTitle"];
      //NSInteger buttonValue = [[buttonDetails objectForKey:@"buttonValue"] intValue];
        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:buttonTitle style:UIBarButtonItemStyleBordered target:self action:@selector(customButtonPressed:)];
        button.tag = index;
        [barItems addObject:button];
        [button release];
        index++;
    }
    if (NO == self.hideCancel) {
        UIBarButtonItem *cancelBtn = [self createButtonWithType:UIBarButtonSystemItemCancel target:self action:@selector(actionPickerCancel:)];
        [barItems addObject:cancelBtn];
    }
    UIBarButtonItem *flexSpace = [self createButtonWithType:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [barItems addObject:flexSpace];
    if (title){
        UIBarButtonItem *labelButton = [self createToolbarLabelWithTitle:title];
        [barItems addObject:labelButton];    
        [barItems addObject:flexSpace];
    }
    UIBarButtonItem *doneButton = [self createButtonWithType:UIBarButtonSystemItemDone target:self action:@selector(actionPickerDone:)];
    [barItems addObject:doneButton];
    [pickerToolbar setItems:barItems animated:YES];
    [barItems release];
    return pickerToolbar;
}

- (UIBarButtonItem *)createToolbarLabelWithTitle:(NSString *)aTitle {
    UILabel *toolBarItemlabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 180,30)];
    [toolBarItemlabel setTextAlignment:NSTextAlignmentCenter];
    [toolBarItemlabel setTextColor:[UIColor whiteColor]];
    [toolBarItemlabel setFont:[UIFont boldSystemFontOfSize:16]];    
    [toolBarItemlabel setBackgroundColor:[UIColor clearColor]];    
    toolBarItemlabel.text = aTitle;    
    UIBarButtonItem *buttonLabel = [[[UIBarButtonItem alloc]initWithCustomView:toolBarItemlabel] autorelease];
    [toolBarItemlabel release];    
    return buttonLabel;
}

- (UIBarButtonItem *)createButtonWithType:(UIBarButtonSystemItem)type target:(id)target action:(SEL)buttonAction {
    return [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:type target:target action:buttonAction] autorelease];
}

#pragma mark - Utilities and Accessors

- (CGSize)viewSize {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
		return CGSizeMake(340, 320);
	}else{
		if (![self isViewPortrait])
			return CGSizeMake(480, 320);
		return CGSizeMake(320, 480);
	}
}

- (BOOL)isViewPortrait {
    return UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation);
}

- (id)storedOrigin {
    if (self.barButtonItem)
        return self.barButtonItem;
    return self.containerView;
}

#pragma mark - Popovers and ActionSheets

- (void)presentPickerForView:(UIView *)aView {
    self.presentFromRect = aView.frame;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        [self configureAndPresentPopoverForView:aView];
    else
        [self configureAndPresentActionSheetForView:aView];
}

- (void)configureAndPresentActionSheetForView:(UIView *)aView {
    NSString *paddedSheetTitle = nil;
    CGFloat sheetHeight = self.viewSize.height - 47;
    if ([self isViewPortrait]) {
        paddedSheetTitle = @"\n\n\n"; // looks hacky to me
    } else {
        NSString *reqSysVer = @"5.0";
        NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
        if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending) {
            sheetHeight = self.viewSize.width;
        } else {
            sheetHeight += 103;
        }
    }
    _actionSheet = [[UIActionSheet alloc] initWithTitle:paddedSheetTitle delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    [_actionSheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
    [_actionSheet addSubview:aView];
    [self presentActionSheet:_actionSheet];
    _actionSheet.bounds = CGRectMake(0, 0, self.viewSize.width, sheetHeight);
	
//	UITapGestureRecognizer *gestureRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)] autorelease];
//	gestureRecognizer.cancelsTouchesInView=NO;
//	[_containerView addGestureRecognizer:gestureRecognizer];
}
/*- (IBAction)hideKeyboard{
	[self dismissPicker];
}
*/
- (void)presentActionSheet:(UIActionSheet *)actionSheet {
    NSParameterAssert(actionSheet != NULL);
    if (self.barButtonItem)
        [actionSheet showFromBarButtonItem:_barButtonItem animated:YES];
    else if (self.containerView && NO == CGRectIsEmpty(self.presentFromRect))
        [actionSheet showFromRect:_presentFromRect inView:_containerView animated:YES];
    else
        [actionSheet showInView:_containerView];
}

- (void)configureAndPresentPopoverForView:(UIView *)aView {
    UIViewController *viewController = [[UIViewController alloc] initWithNibName:nil bundle:nil];
    viewController.view = aView;
    viewController.contentSizeForViewInPopover = viewController.view.frame.size;
    _popOverController = [[UIPopoverController alloc] initWithContentViewController:viewController];
    [self presentPopover:_popOverController];
    [viewController release];
}

- (void)presentPopover:(UIPopoverController *)popover {
    NSParameterAssert(popover != NULL);
    if (self.barButtonItem) {
        [popover presentPopoverFromBarButtonItem:_barButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        return;
    }
    else if ((self.containerView) && NO == CGRectIsEmpty(self.presentFromRect)) {
        [popover presentPopoverFromRect:_presentFromRect inView:_containerView permittedArrowDirections:UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown  animated:YES];
        return;
    }
    // Unfortunately, things go to hell whenever you try to present a popover from a table view cell.  These are failsafes.
/*    UIView *origin = nil;
    CGRect presentRect = CGRectZero;
    @try {
        origin = (_containerView.superview ? _containerView.superview : _containerView);
        presentRect = origin.bounds;
        [popover presentPopoverFromRect:presentRect inView:origin permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    @catch (NSException *exception) {
        origin = [[[[UIApplication sharedApplication] keyWindow] rootViewController] view];
        presentRect = CGRectMake(origin.center.x, origin.center.y, 1, 1);
        [popover presentPopoverFromRect:presentRect inView:origin permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
*/
}

@end

