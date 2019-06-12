//
//  SpecialOptionsViewController.m
//  MyTagList2
//
//  Created by cao on 4/6/17.
//
//

#import "SpecialOptionsViewController.h"
#import "Tag.h"
#import "AsyncURLConnection.h"
#import "iToast.h"

@interface SpecialOptionsViewController ()

@end

@implementation SpecialOptionsViewController
@synthesize tag=_tag, writeBtn=_writeBtn, lockFlashCell=_lockFlashCell, flashLEDCell=_flashLEDCell, cachePostbackCell=_cachePostbackCell;

- (id)initForTag:(NSMutableDictionary*) tag
{
	self = [super initWithStyle:UITableViewStyleGrouped];
	
	if(self){
		self.tag=tag;
		self.title=tag.name;
	}
	return self;
}

-(void)releaseViews{
	self.writeBtn=nil; self.lockFlashCell=nil; self.flashLEDCell=nil; self.cachePostbackCell=nil;
}
-(void)dealloc{
	[self releaseViews];
	self.tag=nil;
	self.dismissUI=nil;
	[super dealloc];
}
- (void)viewDidUnload
{
	[self releaseViews];
	[super viewDidUnload];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.contentSizeForViewInPopover = CGSizeMake(640, 300);
	
	_writeBtn = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"Update",nil) style:UIBarButtonItemStyleDone target:self action:@selector(_writeBtnPressed:)];
	int v2flag = _tag.v2flag;
	
	_lockFlashCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	_lockFlashCell.textLabel.lineBreakMode = NSLineBreakByWordWrapping; //UILineBreakModeWordWrap;
	_lockFlashCell.textLabel.numberOfLines = 0;
	_lockFlashCell.textLabel.text = NSLocalizedString(@"Lock flash memory",nil);
	_lockFlashCell.accessoryType = (v2flag&1)!=0? UITableViewCellAccessoryCheckmark: UITableViewCellAccessoryNone;
	
	_flashLEDCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	_flashLEDCell.textLabel.lineBreakMode = NSLineBreakByWordWrapping; //UILineBreakModeWordWrap;
	_flashLEDCell.textLabel.numberOfLines = 0;
	_flashLEDCell.textLabel.text = NSLocalizedString(@"Flash LED when auto-updating (may reduce battery life)",nil);
	_flashLEDCell.accessoryType = (v2flag&2)!=0? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark;
	
	_cachePostbackCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	_cachePostbackCell.textLabel.lineBreakMode = NSLineBreakByWordWrapping; //UILineBreakModeWordWrap;
	_cachePostbackCell.textLabel.numberOfLines = 0;
	_cachePostbackCell.textLabel.text = [NSLocalizedString(@"Buffer multiple temperature/humidity data points locally before updating",nil) stringByAppendingString:@" ℹ️"];
	_cachePostbackCell.accessoryType = (v2flag&8)!=0? UITableViewCellAccessoryCheckmark: UITableViewCellAccessoryNone;
	UITapGestureRecognizer* recog =[[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapTooltip:)] autorelease];
	[_cachePostbackCell addGestureRecognizer:recog];
	
	self.navigationItem.rightBarButtonItem = _writeBtn;
	
}

- (void)didTapTooltip:(UITapGestureRecognizer *)recognizer {
	UILabel *textLabel = _cachePostbackCell.textLabel;
	CGPoint tapLocation = [recognizer locationInView:textLabel];
	
	// init text storage
	NSTextStorage *textStorage = [[[NSTextStorage alloc] initWithAttributedString:textLabel.attributedText] autorelease];
	NSLayoutManager *layoutManager = [[[NSLayoutManager alloc] init] autorelease];
	[textStorage addLayoutManager:layoutManager];
	
	// init text container
	NSTextContainer *textContainer = [[[NSTextContainer alloc] initWithSize:CGSizeMake(textLabel.frame.size.width, textLabel.frame.size.height+100) ] autorelease];
	textContainer.lineFragmentPadding  = 0;
	textContainer.maximumNumberOfLines = textLabel.numberOfLines;
	textContainer.lineBreakMode        = textLabel.lineBreakMode;
	
	[layoutManager addTextContainer:textContainer];
	
	NSUInteger characterIndex = [layoutManager characterIndexForPoint:tapLocation
													  inTextContainer:textContainer
							 fractionOfDistanceBetweenInsertionPoints:NULL];
	//NSLog(@"characterIndex=%uld",characterIndex);
	if(characterIndex> textLabel.text.length-8){

		[[[iToast makeText:@"For example, if you set recording interval to every 10 minutes, temperature is recorded every 10 minutes, but is transmitted every 130 minutes including 13 data points in one transmission. As a result temperature you see on screen can be up to 130 minute old unless you manually update, but you will get approx. 10% longer battery life (because it is more efficient to send in bulk) and can add more tags at a shorter logging interval to a single tag manager.  "] setDuration:iToastDurationLong] show];
		recognizer.cancelsTouchesInView=YES;
	}else{
		recognizer.cancelsTouchesInView=NO;
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)ip
{
	return 80;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return (_tag.version1>=2?(_tag.rev>=15?((_tag.version1>=4||_tag.rev>=0xB0||(_tag.rev>=0x90 && _tag.tagType!=ALS8k)||(_tag.rev>=0x22 && _tag.tagType==CapSensor))?3:2):1):0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)ip
{
	switch(ip.row){
		case 0: return _lockFlashCell;
		case 1: return _flashLEDCell;
		case 2: return _cachePostbackCell;
		default: return nil;
	}
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.row==0){
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		BOOL checked = (_lockFlashCell.accessoryType==UITableViewCellAccessoryCheckmark);
		if(checked){
			_lockFlashCell.accessoryType = UITableViewCellAccessoryNone;
		}
		else{
			_lockFlashCell.accessoryType = UITableViewCellAccessoryCheckmark;
		}
	}
	else if(indexPath.row==1){
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		BOOL checked = (_flashLEDCell.accessoryType==UITableViewCellAccessoryCheckmark);
		if(checked){
			_flashLEDCell.accessoryType = UITableViewCellAccessoryNone;
		}
		else{
			_flashLEDCell.accessoryType = UITableViewCellAccessoryCheckmark;
		}
	}
	else if(indexPath.row==2){
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		BOOL checked = (_cachePostbackCell.accessoryType==UITableViewCellAccessoryCheckmark);
		if(checked){
			_cachePostbackCell.accessoryType = UITableViewCellAccessoryNone;
		}
		else{
			_cachePostbackCell.accessoryType = UITableViewCellAccessoryCheckmark;

			if(![[NSUserDefaults standardUserDefaults] boolForKey:@"DisplayedMultipleTransmitWarning"] ){
				
				UIAlertView *alert = [[UIAlertView alloc] init];
				[alert setTitle:@"Please read below to understand what to expect when this option is ON"];
				[alert setMessage:@"For example, if you set recording interval to every 10 minutes, temperature is recorded every 10 minutes, but is transmitted every 130 minutes including 13 data points in one transmission. As a result temperature you see on screen can be up to 130 minute old unless you manually update, but you will get approx. 10% longer battery life (because it is more efficient to send in bulk) and can add more tags at a shorter logging interval to a single tag manager. "];
				[alert addButtonWithTitle:NSLocalizedString(@"Continue",nil)];
				[alert setCancelButtonIndex:0];
				[alert show];
				[alert release];
				
				[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"DisplayedMultipleTransmitWarning"];
			}

		}
	}
	
}

-(NSString*) xSetMac{
	if([[NSUserDefaults standardUserDefaults] boolForKey:TagManagerChooseAllPrefKey])
		return _tag.mac;
	else
		return nil;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return NSLocalizedString(@"Special Options",nil);
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	return NSLocalizedString(@"These special options are normally assigned during \"Associate a Tag\" and stored in flash memory. After update, the tag will automatically \"reboot.\"	Options related to motion or temperature monitoring need to be re-applied by \"enable monitoring\" or \"arm.\"",nil);
}
-(void)_writeBtnPressed:(id)sender{
	[super showLoadingBarItem:sender];
	int old_v2flag = _tag.v2flag;
	_tag.v2flag = (_lockFlashCell.accessoryType==UITableViewCellAccessoryCheckmark?1:0)+(_flashLEDCell.accessoryType==UITableViewCellAccessoryCheckmark?0:2)
	+(_cachePostbackCell.accessoryType==UITableViewCellAccessoryCheckmark?8:0);

	[AsyncURLConnection request:[WSROOT stringByAppendingString:@"ethClient.asmx/SaveTagInfo"]
						jsonObj:[NSDictionary dictionaryWithObjectsAndKeys:[_tag forUpload], @"tag",nil]
				  completeBlock:^(NSDictionary* retval){
					  [super revertLoadingBarItem:sender];
					  self.dismissUI(YES);
				  }errorBlock:^(NSError* err, id* showFrom){
					  _tag.v2flag=old_v2flag;
					  *showFrom = sender;
					  [super revertLoadingBarItem:sender];
					  return YES;
				  } setMac:self.xSetMac];
	
}


@end
