#import "RegisterViewController.h"
#import "Tag.h"
#import "AsyncURLConnection.h"
#import "iToast.h"
#import "NSTimer+Blocks.h"

@implementation RegisterViewController
@synthesize delegate=_delegate;
@synthesize macCell=_macCell, managerNameCell=_managerNameCell, emailCell=_emailCell, pwd1Cell=_pwd1Cell, pwd2Cell=_pwd2Cell, allowMoreCell=_allowMoreCell;
@synthesize createBtn=_createBtn;

NSString* allowmoreText;

- (id)initWithDelegate:(id<RegisterViewControllerDelegate>)delegate
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
		validFields=0;
        self.delegate=delegate;
		_allowMoreCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
		_allowMoreCell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;//UILineBreakModeWordWrap;
		_allowMoreCell.textLabel.numberOfLines = 0;
		_allowMoreCell.textLabel.text = allowmoreText = NSLocalizedString(@"Allow creating more account to access currently selected Tag Manager",nil);
		_allowMoreCell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    return self;
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
	self.title = NSLocalizedString(@"Create New Account",nil);
	_macCell = [IASKPSTextFieldSpecifierViewCell newEditableWithPlaceholder:NSLocalizedString(@"Tag Manager Serial",nil) isLast:NO delegate:self];
	_macCell.textField.keyboardType=UIKeyboardTypeNamePhonePad;
	_macCell.textField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
	_macCell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
	
	_managerNameCell = [IASKPSTextFieldSpecifierViewCell newEditableWithPlaceholder:NSLocalizedString(@"Name this manager (e.g. Home)",nil) isLast:NO delegate:self];
	_managerNameCell.textField.keyboardType=UIKeyboardTypeDefault;
	
	_emailCell =[IASKPSTextFieldSpecifierViewCell newEditableWithPlaceholder:NSLocalizedString(@"Choose a Login Email",nil) isLast:NO delegate:self];
	_emailCell.textField.keyboardType=UIKeyboardTypeEmailAddress;
	_pwd1Cell = [IASKPSTextFieldSpecifierViewCell newEditableWithPlaceholder:NSLocalizedString(@"Choose a Password",nil) isLast:NO delegate:self];
	_pwd1Cell.textField.secureTextEntry=YES;
	_pwd1Cell.textField.autocorrectionType=UITextAutocorrectionTypeNo;
	_pwd2Cell = [IASKPSTextFieldSpecifierViewCell newEditableWithPlaceholder:NSLocalizedString(@"Retype the Password",nil) isLast:YES delegate:self];
	_pwd2Cell.textField.secureTextEntry=YES;
	_pwd2Cell.textField.autocorrectionType=UITextAutocorrectionTypeNo;
	_createBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Create",nil) style:UIBarButtonItemStyleBordered
												 target:self action:@selector(createBtnPressed)];
	_createBtn.enabled=NO;
	self.navigationItem.rightBarButtonItem = _createBtn;
}

-(void)releaseViews{
	self.macCell=nil; self.emailCell=nil; self.pwd1Cell=nil; self.pwd2Cell=nil; self.createBtn=nil; self.navigationItem.rightBarButtonItem=nil;	self.managerNameCell=nil;
}
-(void)dealloc{
	[self releaseViews];
	self.allowMoreCell=nil;
	[super dealloc];
}
- (void)viewDidUnload
{
    [super viewDidUnload];
	[self releaseViews];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}
-(void)viewDidAppear:(BOOL)animated{
	[_macCell.textField becomeFirstResponder];
	[super viewDidAppear:animated];
}

#pragma mark - Table view data source
// serial/email/password/password2/allow more
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 6;
}

+(BOOL) IsValidEmail:(NSString *)checkString
{
	BOOL stricterFilter = YES; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
	NSString *stricterFilterString = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
	NSString *laxString = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
	NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
	NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
	return [emailTest evaluateWithObject:checkString];
}

-(UIImage*)okImage{
	return [UIImage imageNamed:@"ok.png"];
}
-(UIImage*)errImage{
	return [UIImage imageNamed:@"bad.png"];
}

-(void)createBtnPressed{
	[super showLoadingBarItem:_createBtn];
	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethAccount.asmx/CreateAccount2"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:
								 _macCell.textField.text,@"MAC", _emailCell.textField.text,@"email",
								 _pwd1Cell.textField.text,@"password", _managerNameCell.textField.text,@"managerName",
								 [NSNumber numberWithBool:_allowMoreCell.accessoryType==UITableViewCellAccessoryCheckmark],@"allowMore", nil]				  
				  completeBlock:^(NSDictionary* retval){
					  [super revertLoadingBarItem:_createBtn];
					  NSString* wsRoot = [retval objectForKey:@"d"];
					  if(wsRoot!=nil && wsRoot.length>1){
						  [_delegate registerViewDone:self withNewWsRoot:wsRoot];
					  }else{
						  [_delegate registerViewDone:self];
					  }
				  }errorBlock:^(NSError* err, id* showFrom){
					  *showFrom = _createBtn;
					  [super revertLoadingBarItem:_createBtn];
					  return YES;
				  } setMac:nil];
}
-(BOOL) validateTableViewCellEntry:(UITableViewCell*)cell{
	if(cell==_macCell){
		if(_macCell.textField.text.length!=12){
			validFields&=~1;
			_macCell.accessoryView = [[[UIImageView alloc]initWithImage:[self errImage]] autorelease];
			[[[iToast makeText:NSLocalizedString(@"Serial number is 12 character long.",nil)] setDuration:iToastDurationNormal] showFrom:_macCell];
			return NO;
		}else{
			_macCell.textField.text = [_macCell.textField.text uppercaseString];
			[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethAccount.asmx/GetTagManagerName"]
						 jsonString:[NSString stringWithFormat:@"{mac: \"%@\"}",_macCell.textField.text] completeBlock:^(NSDictionary* retval){
							 _macCell.accessoryView = [[[UIImageView alloc]initWithImage:[self okImage]] autorelease];
							 validFields|=1;
							 _managerNameCell.textField.text = [retval objectForKey:@"d"];
							 [_managerNameCell.textField becomeFirstResponder];
						 }errorBlock:^(NSError* err, id* showFrom){
							 *showFrom = _macCell;
							 validFields&=~1;
							 _macCell.accessoryView = [[[UIImageView alloc]initWithImage:[self errImage]] autorelease];
							 return YES;
						 }setMac:nil];
			return YES;
		}
	}
	else if(cell==_managerNameCell){
		
		_managerNameCell.accessoryView = [[[UIImageView alloc]initWithImage:[self okImage]] autorelease];
//		[_emailCell.textField becomeFirstResponder];
		return YES;
	}
	else if(cell==_emailCell){
		if([RegisterViewController IsValidEmail:_emailCell.textField.text]){
			validFields|=2;
			_emailCell.accessoryView = [[[UIImageView alloc]initWithImage:[self okImage]] autorelease];
//			[_pwd1Cell.textField becomeFirstResponder];
			return YES;
		}else{
			validFields&=~2;
			[[[iToast makeText:NSLocalizedString(@"Valid email address required for password recovery.",nil)] setDuration:iToastDurationNormal] showFrom:_emailCell];
			_emailCell.accessoryView = [[[UIImageView alloc]initWithImage:[self errImage]] autorelease];
			return NO;
		}
	}else if(cell==_pwd1Cell){
		if(_pwd1Cell.textField.text.length>=3){
			validFields|=4;
			_pwd1Cell.accessoryView = [[[UIImageView alloc]initWithImage:[self okImage]] autorelease];
//			[_pwd2Cell.textField becomeFirstResponder];
			return YES;
		}else{
			validFields&=~4;
			[[[iToast makeText:NSLocalizedString(@"Password must be at least 3 characters.",nil)] setDuration:iToastDurationNormal]  showFrom:_pwd1Cell];
			_pwd1Cell.accessoryView = [[[UIImageView alloc]initWithImage:[self errImage]] autorelease];
			return NO;
		}
	}else if(cell==_pwd2Cell){
		if([_pwd2Cell.textField.text isEqualToString:_pwd1Cell.textField.text]){
			validFields|=8;
			_pwd2Cell.accessoryView = [[[UIImageView alloc]initWithImage:[self okImage]] autorelease];
//			[self createBtnPressed];
			return YES;
		}else{
			validFields&=~8;
			[[[iToast makeText:NSLocalizedString(@"Passwords must match.",nil)] setDuration:iToastDurationNormal]  showFrom:_pwd2Cell];
			_pwd2Cell.accessoryView = [[[UIImageView alloc]initWithImage:[self errImage]] autorelease];
			return NO;
		}		
	}
	return YES;
}
-(void)editedTableViewCell:(UITableViewCell *)cell
{
	if([self validateTableViewCellEntry:cell]){
		if(cell==_managerNameCell){
			[NSTimer scheduledTimerWithTimeInterval:0.1 block:^
			 { [_emailCell.textField becomeFirstResponder];} repeats:NO];
		}
		if(cell==_emailCell){
			[NSTimer scheduledTimerWithTimeInterval:0.1 block:^
			 { [_pwd1Cell.textField becomeFirstResponder];} repeats:NO];
		}
		else if(cell==_pwd1Cell){
			[NSTimer scheduledTimerWithTimeInterval:0.1 block:^
			 { [_pwd2Cell.textField becomeFirstResponder];} repeats:NO];			
		}
	}
	if(validFields==1+2+4+8)_createBtn.enabled=YES;
	else _createBtn.enabled=NO;	
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)ip
{
	if(ip.row==5){
		NSString *cellText = allowmoreText;
		UIFont *cellFont = [UIFont fontWithName:@"Helvetica" size:18.0];
		CGSize constraintSize = CGSizeMake(280.0f, MAXFLOAT);
		CGSize labelSize = [cellText sizeWithFont:cellFont constrainedToSize:constraintSize lineBreakMode:NSLineBreakByWordWrapping];
		return labelSize.height + 18;
	}else{
		return 44;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)ip
{
	switch(ip.row){
		case 0: return _macCell;
		case 1: return _managerNameCell;
		case 2: return _emailCell;
		case 3: return _pwd1Cell;
		case 4: return _pwd2Cell;
		case 5: return _allowMoreCell;
	}
	return nil;
}
#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if(indexPath.row==5){
		BOOL checked = (_allowMoreCell.accessoryType==UITableViewCellAccessoryCheckmark);
		if(checked){
			_allowMoreCell.accessoryType = UITableViewCellAccessoryNone;
		}
		else{
			_allowMoreCell.accessoryType = UITableViewCellAccessoryCheckmark;
		}
	}
}

@end
