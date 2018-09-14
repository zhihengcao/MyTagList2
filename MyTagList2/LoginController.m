//
//  LoginController.m
//  newsyc
//
//  Created by Grant Paul on 3/22/11.
//  Copyright 2011 Xuzz Productions, LLC. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "LoginController.h"
#import "WebViewController.h"
#import "Tag.h"

NSString * const TagListRememberLoginPrefKey = @"TagListRememberLoginPrefKey";
NSString * const TagListLoginEmailPrefKey = @"TagListLoginEmailPrefKey";
NSString * const TagListLoginPwdPrefKey = @"TagListLoginPwdPrefKey";
NSString * const TagManagerChooseAllPrefKey = @"TagManagerChooseAllPrefKey";
NSString * const TagSelectedToArmPrefKey = @"TagSelectedToArmPrefKey";

@implementation LoginController
@synthesize delegate;

- (void)dealloc {
    [tableView release];
//	[loadingCell release];
    [usernameCell release];
    [passwordCell release];
//    [backgroundImageView release];
    [cancelItem release];
    [completeItem release];
    [loadingItem release];
    
    [super dealloc];
}
-(void)clearUserInputs{
	usernameField.text=nil;
	passwordField.text=nil;
}
- (id)init {
    if ((self = [super init])) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            [self setModalPresentationStyle:UIModalPresentationFormSheet];
    }
    
    return self;
}

- (void)_updateCompleteItem {
	
    if (([[usernameField text] length] > 0 && [[passwordField text] length] > 2) ) {
        [completeItem setEnabled:YES];
    } else {
        [completeItem setEnabled:NO];
    }
}

- (UITextField *)_createCellTextField {
    UITextField *field = [[UITextField alloc] initWithFrame:CGRectZero];
    [field setAdjustsFontSizeToFitWidth:YES];
    [field setTextColor:[UIColor blackColor]];
    [field setDelegate:self];
	[field addTarget:self
				  action:@selector(textFieldDidChange:)
		forControlEvents:UIControlEventEditingChanged];
    [field setBackgroundColor:[UIColor clearColor]];
    [field setAutocorrectionType:UITextAutocorrectionTypeNo];
    [field setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    //[field setTextAlignment:NSTextAlignmentLeft];
	[field setTextAlignment:NSTextAlignmentCenter];
    [field setEnabled:YES];
    [field setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    return [field autorelease];
}

- (NSArray *)gradientColors {
    return nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	// Return YES for supported orientations
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
	} else {
		return YES;
	}
}

- (void)loadView {
    [super loadView];

    tableView = [[UITableView alloc] initWithFrame:[[self view] bounds]  //CGRectMake(0, 0, [[self view] bounds].size.width, 300.0f)
													style:UITableViewStyleGrouped];
	//[tableView setBackgroundColor:[UIColor clearColor]];
    [tableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [tableView setDelegate:self];
    [tableView setDataSource:self];
    [tableView setScrollEnabled:NO];
    [tableView setAllowsSelection:YES];
    [[self view] addSubview:tableView];
	
    usernameCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    [[usernameCell textLabel] setText:NSLocalizedString(@"Email",nil)];
    usernameField = [self _createCellTextField];
    usernameField.frame = CGRectMake(125, 12, usernameCell.bounds.size.width - 125, 30);
    [usernameField setReturnKeyType:UIReturnKeyNext];
	[usernameField setKeyboardType:UIKeyboardTypeURL];
    [usernameCell addSubview:usernameField];
    
    passwordCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    [[passwordCell textLabel] setText:NSLocalizedString(@"Password",nil)];
    passwordField = [self _createCellTextField];
    passwordField.frame = CGRectMake(125, 12, passwordCell.bounds.size.width - 125, 30);
    [passwordField setSecureTextEntry:YES];
    [passwordField setReturnKeyType:UIReturnKeyDone];
    [passwordCell addSubview:passwordField];
    
    completeItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Confirm",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(_authenticate)];
    cancelItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(_cancel)];
    		
	loadingItem = [ActivityIndicatorItem new];
        
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[self navigationItem] setRightBarButtonItem:completeItem];
    [[self navigationItem] setLeftBarButtonItem:cancelItem];
    
    [self setTitle:NSLocalizedString(@"Login",nil)];
}

- (void)viewDidUnload {
    [super viewDidUnload];
	
//    [loadingCell release];
//	loadingCell = nil;
    [passwordCell release];
    passwordCell = nil;
    [usernameCell release];
    usernameCell = nil;
    [loadingItem release];
    loadingItem = nil;
    [cancelItem release];
    cancelItem = nil;
    [completeItem release];
    completeItem = nil;
    [tableView release];
    tableView = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
	passwordField.text = [[NSUserDefaults standardUserDefaults] stringForKey:TagListLoginPwdPrefKey];
	usernameField.text = [[NSUserDefaults standardUserDefaults] stringForKey:TagListLoginEmailPrefKey];
	if(usernameField.text.length==0)
		[usernameField becomeFirstResponder];
	
	[self _updateCompleteItem];
}

//- (void)finish {
//    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
//}

- (void) enableControls:(BOOL) enable
{
	if(enable){
		usernameCell.textLabel.alpha = usernameField.alpha = 1;
		usernameCell.userInteractionEnabled = usernameField.userInteractionEnabled= YES;
		passwordCell.textLabel.alpha = passwordField.alpha = 1;
		passwordCell.userInteractionEnabled = passwordField.userInteractionEnabled = YES;
	}else{
		usernameCell.textLabel.alpha = passwordCell.textLabel.alpha = 
		passwordField.alpha = usernameField.alpha = 0.439216f;
		usernameCell.userInteractionEnabled =  usernameField.userInteractionEnabled= NO;
		passwordCell.userInteractionEnabled = passwordField.userInteractionEnabled = NO;
	}
	[tableView reloadData];
}

- (void)notifyLoginFailed {	
    UIAlertView *alert = [[UIAlertView alloc] init];
    [alert setTitle:NSLocalizedString(@"Unable to Authenticate",nil)];
    [alert setMessage:NSLocalizedString(@"Unable to authenticate. Make sure your email and password are correct.",nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Continue",nil)];
    [alert setCancelButtonIndex:0];
    [alert show];
    [alert release];    	
	
	[self enableControls: YES];
	[passwordField becomeFirstResponder];
    [[self navigationItem] setRightBarButtonItem:completeItem];
}

- (void)_cancel {
	[self enableControls: YES];
    [[self navigationItem] setRightBarButtonItem:completeItem];

	[delegate loginControllerDidCancel:self];
}
-(void)_authenticate
{	
	[self enableControls:NO];
	[[self navigationItem] setRightBarButtonItem:loadingItem];

	if([[NSUserDefaults standardUserDefaults] boolForKey:TagListRememberLoginPrefKey]){
		[[NSUserDefaults standardUserDefaults] setValue:usernameField.text forKey:TagListLoginEmailPrefKey];
		[[NSUserDefaults standardUserDefaults] setValue:passwordField.text forKey:TagListLoginPwdPrefKey];
	}
	
	[delegate loginController:self doLoginWithEmail:[usernameField text] Password:[passwordField text]];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == usernameField) {
        [passwordField becomeFirstResponder];
    } else if (textField == passwordField) {
		[self _authenticate];
    }
    
    return YES;
}
-(void)textFieldDidChange:(id)sender{
	[self performSelector:@selector(_updateCompleteItem) withObject:nil afterDelay:0.0f];
}

/*- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

	[self performSelector:@selector(_updateCompleteItem) withObject:nil afterDelay:0.0f];
    
    return YES;
}*/


- (NSInteger)numberOfSectionsInTableView:(UITableView *)table {
    return 3;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: return 3; //return isAuthenticating ? 1 : 2;
		case 1: return 1;
		case 2: return 1;
        default: return 0;
    }
}

- (CGFloat)tableView:(UITableView *)table heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 44; //isAuthenticating ? 88.0 : 44.0;
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if(indexPath.section==1){
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RegisterBtnCell"];
		if(!cell){
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"RegisterBtnCell"] autorelease];
			cell.textLabel.text = NSLocalizedString(@"Create New Account",nil);
			cell.textLabel.textAlignment=NSTextAlignmentCenter;
		}
		return cell;
	}
	else if(indexPath.section==2){
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ForgotPasswordBtnCell"];
		if(!cell){
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ForgotPasswordBtnCell"] autorelease];
			cell.textLabel.text = NSLocalizedString(@"Password Recovery",nil);
			cell.textLabel.textAlignment=NSTextAlignmentCenter;
		}
		return cell;
	}
	else{
		if ([indexPath row] == 0) {		
			return /*isAuthenticating ? loadingCell : */usernameCell;
		} else if ([indexPath row] == 1) {
			return passwordCell;
		} else {
			UITableViewCell *cell = 
			[tableView dequeueReusableCellWithIdentifier:@"RememberOption"];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
											   reuseIdentifier:@"RememberOption"] 
						autorelease];
				cell.textLabel.text = NSLocalizedString(@"Remember Me",nil);
				if([[NSUserDefaults standardUserDefaults] boolForKey:TagListRememberLoginPrefKey])
					[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
			}
			return cell;
		}
	}
}
- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)ip
{
	[table deselectRowAtIndexPath:ip animated:YES];
	if(ip.section==0){
		if(ip.row==2){
			UITableViewCell *cell = [table cellForRowAtIndexPath:ip];
			BOOL checked = (cell.accessoryType==UITableViewCellAccessoryCheckmark);
			if(checked){
				cell.accessoryType = UITableViewCellAccessoryNone;
				[[NSUserDefaults standardUserDefaults] removeObjectForKey:TagListLoginEmailPrefKey];
				[[NSUserDefaults standardUserDefaults] removeObjectForKey:TagListLoginPwdPrefKey];
				
			}
			else{
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
			}
			
			[[NSUserDefaults standardUserDefaults] setBool:!checked forKey:TagListRememberLoginPrefKey];
		}
	}else if(ip.section==1){

		[delegate loginControllerRegisterRequest:self];
	}else{
		WebViewController* wv = [[[WebViewController alloc]initWithTitle:NSLocalizedString(@"Password Recovery",nil)] autorelease];
		
		[(UINavigationController*)self.navigationController pushViewController:wv animated:YES];
		
		NSURL *url = [NSURL URLWithString:	[WSROOT stringByAppendingString:@"recoverpassword.aspx"]];
		NSURLRequest *req = [NSURLRequest requestWithURL:url];
		
		[[wv webView] loadRequest:req];
	}
}

@end
