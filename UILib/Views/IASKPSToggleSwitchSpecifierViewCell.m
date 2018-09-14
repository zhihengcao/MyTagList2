#import "IASKPSToggleSwitchSpecifierViewCell.h"
#import "IASKSwitch.h"
#import "NSTimer+Blocks.h"

@implementation IASKPSToggleSwitchSpecifierViewCell

@synthesize label=_label, delegate=_delegate,toggle=_toggle, progressTitle=_progressTitle, title=_title, script,toggleOn=_toggleOn, helpText, toggleState;

-(void)setToggleOn:(BOOL)toggleOn{
	_toggle.on = _toggleOn=toggleOn;
	self.toggleState.text = toggleOn?NSLocalizedString(@"On",nil):NSLocalizedString(@"Off",nil);
}
-(void)updateToggleOn{
	_toggleOn=_toggle.on;
}
- (IBAction)valueChanged:(id)sender {
	/*[NSTimer scheduledTimerWithTimeInterval:0.4 block:^()
	 {
		 [_delegate editedTableViewCell:self];
	 } repeats:NO];*/
	/*NSLog(@"IASKPSToggleSwitchSpecifierViewCell valueChanged:%@", [sender description]);
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[_delegate editedTableViewCell:self];
	});*/
	//[_delegate performSelector:@selector(editedTableViewCell:) withObject:self ];
	
	//NSLog(@"valueChanged toggle.on = %d, _toggleOn=%d", _toggle.on, _toggleOn);

	if(_toggle.on!=_toggleOn){
	//	_toggle.userInteractionEnabled=NO;
		[_delegate editedTableViewCell:self];
//		_toggle.userInteractionEnabled=YES;
	}
/*	else{
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

			NSLog(@"dispatch valueChanged toggle.on = %d, _toggleOn=%d", _toggle.on, _toggleOn);
			if(_toggle.on!=_toggleOn)
				[_delegate editedTableViewCell:self];
		});
	}
 */
}

-(void) updateHelpTextHeightFor:(NSString*)text{
	hideHelp=YES;
	if(text==nil){
		firstTimeHelp=NO;
		helpTextHeight=0;
	}
	else{

		firstTimeHelp = ![[NSUserDefaults standardUserDefaults] boolForKey:self.title];
		self.toggle.hidden=firstTimeHelp;
		self.toggleState.hidden=!firstTimeHelp;
		if(firstTimeHelp){
			self.toggleState.text = self.toggle.on?NSLocalizedString(@"On",nil):NSLocalizedString(@"Off",nil);
		}
		
		self.contentView.clipsToBounds = YES;
		
		CGSize constrainedSize = CGSizeMake(self.helpText.frame.size.width  , 9999);
		NSMutableAttributedString *string = [[[NSMutableAttributedString alloc] initWithString:text
																					attributes:[NSDictionary dictionaryWithObjectsAndKeys:  self.helpText.font, NSFontAttributeName,
																								nil]] autorelease];
		CGRect requiredHeight = [string boundingRectWithSize:constrainedSize options:NSStringDrawingUsesLineFragmentOrigin context:nil];
		helpTextHeight = requiredHeight.size.height;
	}
}

+ (IASKPSToggleSwitchSpecifierViewCell*) newWithTitle:(NSString*)title helpText:(NSString *)help delegate:(id<IEditableTableViewCellDelegate>)delegate
{	
	IASKPSToggleSwitchSpecifierViewCell* cell =  
	(IASKPSToggleSwitchSpecifierViewCell*) [[[NSBundle mainBundle] loadNibNamed:@"IASKPSToggleSwitchSpecifierViewCell"
																	owner:delegate 
																  options:nil] objectAtIndex:0];
	cell.title = title;
	cell.helpText.text = help;
	[cell updateHelpTextHeightFor:help];
	cell.delegate=delegate;
	[cell.spinner removeFromSuperview];
	return [cell retain];
}
-(void) setTitle:(NSString *)title{
	[_title autorelease];
	_title = [title retain];
	if(self.userInteractionEnabled)
		self.label.text=title;
}
+(IASKPSToggleSwitchSpecifierViewCell*) newLoadingWithTitle:(NSString*)title Progress:(NSString*)progressTitle helpText:(NSString *)help delegate:(id<IEditableTableViewCellDelegate>)delegate
{
	IASKPSToggleSwitchSpecifierViewCell* cell =
	(IASKPSToggleSwitchSpecifierViewCell*) [[[NSBundle mainBundle] loadNibNamed:@"IASKPSToggleSwitchSpecifierViewCell"
																		  owner:delegate
																		options:nil] objectAtIndex:0];
	cell.progressTitle= progressTitle;
	cell.delegate = delegate;
	cell.title = title;
	cell.helpText.text = help;
	[cell updateHelpTextHeightFor:help];
	cell.spinner.hidesWhenStopped = YES;

	return [cell retain];

}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
-(NSString*) detailText{
	return helpText.text;
}
-(void)setDetailText:(NSString *)detailText{
	self.helpText.hidden=NO;
	self.helpText.text=detailText;

	self.contentView.clipsToBounds = YES;
	CGSize constrainedSize = CGSizeMake(self.helpText.frame.size.width  , 9999);
	NSMutableAttributedString *string = [[[NSMutableAttributedString alloc] initWithString:detailText
																				attributes:[NSDictionary dictionaryWithObjectsAndKeys:  self.helpText.font, NSFontAttributeName,
																							nil]] autorelease];
	CGRect requiredHeight = [string boundingRectWithSize:constrainedSize options:NSStringDrawingUsesLineFragmentOrigin context:nil];
	helpTextHeight = requiredHeight.size.height;
	hideHelp=NO;
}
-(void)toggleHelp{
	hideHelp=!hideHelp;
	//self.helpText.hidden=!self.helpText.hidden;
	
	if(!hideHelp)
		[NSTimer scheduledTimerWithTimeInterval:0.3 block:^()
		 {
			 self.helpText.hidden=NO;
		 } repeats:NO];
	else self.helpText.hidden=YES;
	
	if(!hideHelp && firstTimeHelp){
		self.toggleState.hidden = YES;
		self.toggle.hidden=NO;
	}
	if(hideHelp){
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:self.title];
	}
//	[self setNeedsLayout];
/*	if(!hideHelp)
	[NSTimer scheduledTimerWithTimeInterval:0.6 block:^()
	 {
		 self.helpText.hidden=NO;
	 } repeats:NO];
	else self.helpText.hidden=YES;*/
}

-(CGFloat)getHeight{
	if(hideHelp)return 44;
	else return 44+helpTextHeight+12;
}
-(void)showLoading{
	if(_progressTitle)
		self.label.text=self.progressTitle;
	self.label.alpha = 0.439216f;
	self.toggle.enabled = NO;
	self.userInteractionEnabled =  NO;
	[self.spinner startAnimating];
}
-(void)revertLoading{
	if(_progressTitle)
		self.label.text=self.title;
	self.label.alpha =1;
	self.toggle.enabled = YES;
	self.userInteractionEnabled =  YES;
	[self.spinner stopAnimating];
}

- (void)dealloc {
	self.script=nil;
	self.progressTitle = nil;
	self.title=nil;
	self.spinner=nil;
	self.label=nil;
	self.toggle=nil;
    [super dealloc];
}


@end
