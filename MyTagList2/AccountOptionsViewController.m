//
//  AccountOptionsViewController.m
//  MyTagList2
//
//  Created by Pei Chang on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AccountOptionsViewController.h"
#import "RegisterViewController.h"
#import "iToast.h"

@implementation AccountOptionsViewController
@synthesize modified=_modified;
- (id)initWithDelegate:(id<OptionsViewControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self) {
		self.title = @"Account Options";
		_modified=NO;
    }
    return self;
}
-(void)releaseViews{
	[email release]; email=nil;
	[pwd release];pwd=nil;
	[twitterLogin release]; twitterLogin=nil;
	[allowMore release]; allowMore=nil;
	[webappAccount release]; webappAccount=nil;
	[referralProgramLink release]; referralProgramLink=nil;
}
-(void)dealloc{
	[self releaseViews];
	self.config=nil;
	[super dealloc];
}

-(UIImage*)okImage{
	return [UIImage imageNamed:@"ok.png"];
}
-(UIImage*)errImage{
	return [UIImage imageNamed:@"bad.png"];
}
-(void)navbarSave{

	if([RegisterViewController IsValidEmail:email.textField.text]){
		email.accessoryView = [[[UIImageView alloc]initWithImage:[self okImage]] autorelease];
	}else{
		[[[iToast makeText:@"Valid email address required for password recovery."] setDuration:iToastDurationNormal] showFrom:email];
		email.accessoryView = [[[UIImageView alloc]initWithImage:[self errImage]] autorelease];
		return;
	}

	if(pwd.textField.text.length>=3){
		pwd.accessoryView = [[[UIImageView alloc]initWithImage:[self okImage]] autorelease];
	}else{
		[[[iToast makeText:@"Password must be at least 3 characters."] setDuration:iToastDurationNormal]  showFrom:pwd];
		pwd.accessoryView = [[[UIImageView alloc]initWithImage:[self errImage]] autorelease];
		return;
	}

	
	self.config.loginEmail = email.textField.text;
	self.config.loginPwd = pwd.textField.text;
	self.config.allowMore = allowMore.accessoryType==UITableViewCellAccessoryCheckmark;

	if(self.delegate)
		[self.delegate optionViewSaveBtnClicked:self];
}

-(void)setConfig:(NSMutableDictionary *)c{
	[super view];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave
																						   target:self action:@selector(navbarSave)] autorelease];	
	email.textField.text = c.loginEmail;
	pwd.textField.text = c.loginPwd;
	allowMore.accessoryType = c.allowMore?UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;
	[super setConfig:c];
}

-(void) editedTableViewCell:(UITableViewCell*)cell
{
	_modified=YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	email = [IASKPSTextFieldSpecifierViewCell newEditableWithPlaceholder:@"Login Email" isLast:NO delegate:self];
	email.textField.keyboardType=UIKeyboardTypeEmailAddress;
	pwd = [IASKPSTextFieldSpecifierViewCell newEditableWithPlaceholder:@"Login Password" isLast:NO delegate:self];
	pwd.textField.secureTextEntry=YES;
	pwd.textField.autocorrectionType=UITextAutocorrectionTypeNo;

	twitterLogin = [TableLoadingButtonCell newWithTitle:@"Twitter Login..." Progress:@"Redirecting..."];
	webappAccount = [TableLoadingButtonCell newWithTitle:@"Add/Edit Tag Managers..." Progress:@"Loading..."];
	referralProgramLink = [TableLoadingButtonCell newWithTitle:@"Earn Referral Fee" Progress:@"Loading..."];

/*
	twitterID = [IASKPSTextFieldSpecifierViewCell newEditableWithPlaceholder:@"Twitter Login" isLast:NO delegate:self];
	twitterID.textField.keyboardType=UIKeyboardTypeEmailAddress;
	twitterPwd = [IASKPSTextFieldSpecifierViewCell newEditableWithPlaceholder:@"Twitter Password" isLast:NO delegate:self];
	twitterPwd.textField.secureTextEntry=YES;
	twitterPwd.textField.autocorrectionType=UITextAutocorrectionTypeNo;
	*/
	allowMore = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	allowMore.textLabel.lineBreakMode = NSLineBreakByWordWrapping;//UILineBreakModeWordWrap;
	allowMore.textLabel.numberOfLines = 0;
	allowMore.textLabel.text = allowmoreText = NSLocalizedString(@"Allow creating more account to access currently selected Tag Manager",nil);
	allowMore.accessoryType = UITableViewCellAccessoryCheckmark;

	UITapGestureRecognizer *gestureRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)] autorelease];
	gestureRecognizer.cancelsTouchesInView=NO;
	[self.tableView addGestureRecognizer:gestureRecognizer];
}
- (IBAction)hideKeyboard{
	[[self view]endEditing:YES];
}

- (void)viewDidUnload
{
    [self releaseViews];
    [super viewDidUnload];
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table view data source

// [when out of range (email, addr, ringpc, usespeech, vib)
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 4;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if(section==0)
		return @"Twitter Account:";
	else if(section==1)
		return @"WirelessTag Account:";
	else if(section==2)
		return nil;
	else
		return @"Love Wireless Tag? Let people know about it and earn referral fees";
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if(section==0 || section==2 || section==3)return 1;
	else return 3;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)ip
{
	if(ip.row==2 && ip.section==1){
		NSString *cellText = allowmoreText;
		UIFont *cellFont = [UIFont fontWithName:@"Helvetica" size:17.0];
		CGSize constraintSize = CGSizeMake(280.0f, MAXFLOAT);
		CGSize labelSize = [cellText sizeWithFont:cellFont constrainedToSize:constraintSize lineBreakMode:NSLineBreakByWordWrapping];
		return labelSize.height + 18;
	}else{
		return 44;
	}
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)ip
{
	if (ip.section==0) {
		return twitterLogin;
	}else if(ip.section==1){
		if(ip.row==0)return email;
		else if(ip.row==1)return pwd;
		else return allowMore;
	}else if(ip.section==2){
		return webappAccount;
	}else
		return referralProgramLink;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if(indexPath.section==0)
	{
		[self.delegate optionViewTwitterLoginBtnClicked:twitterLogin];
	}
	else if(indexPath.row==2 && indexPath.section==1){
		BOOL checked = (allowMore.accessoryType==UITableViewCellAccessoryCheckmark);
		if(checked){
			allowMore.accessoryType = UITableViewCellAccessoryNone;
		}
		else{
			allowMore.accessoryType = UITableViewCellAccessoryCheckmark;
		}
	}else if(indexPath.section==2){
		[self.delegate optionViewWebAccountBtnClicked:webappAccount];
	}else if(indexPath.section==3){
		[self.delegate optionEarnReferralBtnClicked:referralProgramLink];
	}
}

@end

