//
//  DetailViewController.m
//  MyTagList2
//
//  Created by Pei Chang on 1/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DetailViewController.h"
#import "Tag.h"
#import "ActionSheet+Blocks.h"
#import "ImageStore.h"
#import "IASKPSTextFieldSpecifierViewCell.h"
#import "UIImage+Resize.h"
#import "UIImage+RoundedCorner.h"
#import "OptionPicker.h"
#import "DailyGraphViewController.h"
#import "WebImageOperations.h"
#import "OptionsViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>


@implementation UIPopoverController (UniversalPresent)
-(void)presentPopoverFromAnything:(id)sender{
//	if(([[UIDevice currentDevice].systemVersion floatValue] >= 8)){
		
//	}else{
		if([sender isKindOfClass:[UIBarButtonItem class]])
		[self presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		else if([sender isKindOfClass: [UITableViewCell class]]){
			UITableViewCell* cell = sender;
			[self presentPopoverFromRect:cell.bounds inView:cell.contentView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		}
		else if([sender isKindOfClass: [UIView class]]){
			UIView* view = sender;
			[self presentPopoverFromRect:view.frame inView:view.superview permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		}
//	}
}
@end



@implementation DetailViewController

@synthesize delegate=_delegate;
@synthesize tag = _tag;
@synthesize masterPopoverController = _masterPopoverController;
@synthesize stopBeepBtn=_stopBeepBtn;
@synthesize beepBtn=_beepBtn;
@synthesize armBtn=_armBtn;
@synthesize pingBtn=_pingBtn;
@synthesize pingNowBtn=_pingNowBtn;
@synthesize optionsBtn=_optionsBtn;
@synthesize pictureBtn=_pictureBtn;
@synthesize thermostatCell=_thermostatCell;

-(NSString*) xSetMac{
	if([[NSUserDefaults standardUserDefaults] boolForKey:TagManagerChooseAllPrefKey])
		return _tag.mac;
	else
		return nil;
}
#pragma mark - Managing the detail item

static int beep_option_choices_val_ms[]={1001, 5,10,15,20,30,1000,0};
//static int beep_option_choices_val_bt[]={5,10,15,20,30,1000,0};
static NSInteger dim_speed_choices_val[] = {0, 10, 50};

-(NSInteger)dim_speed{
	return [[NSUserDefaults standardUserDefaults] integerForKey:[@"dim_speed_" stringByAppendingString:_tag.uuid]];
}
-(NSInteger) dim_speed_index{
	for(NSInteger i=0;i<sizeof(dim_speed_choices_val)/sizeof(NSInteger);i++){
		if(dim_speed_choices_val[i]==[self dim_speed]) return i;
	}
	return 0;
}
-(int) beep_option_index{
	int i=0;
	while(beep_option_choices_val[i]!=0){
		if(beep_option_choices_val[i]== _tag.beepDurationDefault)
			return i;
		i++;
	}
	return 0;
}
-(void)updateAgo{
	updatedCell.textField.text =  _tag.lastComm==0? NSLocalizedString(@"(Never updated)",nil) : [NSString stringWithFormat:NSLocalizedString(@"%@ ago",nil), [_tag UserFriendlyTimeSpanString:NO]];
}
// loadThermSlider is YES unless you don't want to re-animate the slider because the slider was just adjusted by user.
-(void)updateTag:(NSMutableDictionary*)newTag loadThermostatSlider:(BOOL)loadThermSlider animated:(BOOL)animated;
{
	[self view];  // make sure sub views are loaded.
	
	NSMutableDictionary* oldtag = _tag;
	if(oldtag!=nil)
		[self.tableView beginUpdates];

	NSArray* oldCells = [[cellArray copy] autorelease];
	_tag = [newTag retain];

	if(_tag.isCam && !oldtag.isCam){
		lightOnCell.title = NSLocalizedString(@"Streaming On",nil);
		lightOffCell.title = NSLocalizedString(@"Streaming Off",nil);
		camDetailCell.textField.text = _tag.beeping?NSLocalizedString(@"Taking Time Lapse...",nil) : NSLocalizedString(@"Click to view",nil);
	}
	else if(!_tag.isCam && oldtag.isCam)
	{
		lightOnCell.title = NSLocalizedString(@"Light On",nil);
		lightOffCell.title = NSLocalizedString(@"Light Off",nil);
	}
	[self updateCellArray];
	
	if(_tag.hasBeeper)
		beepOptionCell.textField.text = [self.beep_option_choices objectAtIndex:[self beep_option_index]];
	if(_tag.isWeMoLED){
		dimSpeedCell.textField.text = [self.dim_speed_choices objectAtIndex:[self dim_speed_index]];
		[dimCell setVal:_tag.cap];
	}
	
	self.title = _tag.name;
	batteryCell.textField.text = [NSString stringWithFormat:NSLocalizedString(@"%.2f volts, %d%% left",nil), _tag.batteryVolt, _tag.batteryPercent];
	if(_tag.batteryVolt < _tag.LBTh)
		batteryCell.textField.textColor = [UIColor redColor];
	else
		batteryCell.textField.textColor = signalCell.textField.textColor;
	
	ds18Cell.toggleOn = _tag.ds18;
	
	signalCell.textField.text = _tag.signaldBm>-118? [NSString stringWithFormat:NSLocalizedString(@"%.0fdBm (%.0f%% power)",nil), _tag.signaldBm, _tag.txpwr*100.0f/255.0f]:
	[NSString stringWithFormat:NSLocalizedString(@"No signal at %@",nil), _tag.managerName];
	managerCell.textField.text = [NSString stringWithFormat:@"%@ %@", _tag.tagTypeText, _tag.tagRevisionText];
	nameCell.textField.text = _tag.name;
	commentCell.textField.text= _tag.comment;
	[self updateAgo];
	
	if(_tag.hasThermostat){
		thermostatChoiceCell.label.text = NSLocalizedString(@"Controlled by",nil);
		thermostatChoiceCell.textField.text = _tag.targetRef.name;
		if(loadThermSlider)
			[_thermostatCell setThHgh:_tag.thermostat.th_high ThLow:_tag.thermostat.th_low currentDegC:_tag.targetRef.temperatureDegC
			  rangeMin:_tag.thermostat.threshold_q.min rangeMax:_tag.thermostat.threshold_q.max stepSize:_tag.thermostat.threshold_q.step];
		_thermostatCell.fanOn.on = _tag.thermostat.fanOn;
		_thermostatCell.hvacOn.on = !_tag.thermostat.turnOff;
		_thermostatCell.homeAwayLabel.text = (_tag.supportsHomeAway&&!_tag.thermostat.disableLocal)?@"Home":@"Heat/AC";
		[allowLocalCell setToggleOn:_tag.thermostat.disableLocal];
	}else{
		thermostatChoiceCell.label.text = NSLocalizedString(@"Controls Thermostat",nil);
		if(_tag.thermostatRef!=nil){
			NSDictionary* tref =_tag.thermostatRef;
			thermostatChoiceCell.textField.text = tref.name;
			if(loadThermSlider)
				[_thermostatCell setThHgh:tref.thermostat.th_high ThLow:tref.thermostat.th_low currentDegC:_tag.temperatureDegC
					rangeMin:tref.thermostat.threshold_q.min rangeMax:tref.thermostat.threshold_q.max stepSize:tref.thermostat.threshold_q.step];
			_thermostatCell.fanOn.on = tref.thermostat.fanOn;
			_thermostatCell.hvacOn.on = !tref.thermostat.turnOff;
		}else{
			thermostatChoiceCell.textField.text = NSLocalizedString(@"None",nil);
		}
	}
	motionCell.textField.text = _tag.msEventString;
	[motionCell addSwatch:_tag.eventStateSwatch animated:animated];
	
	//[motionCell.textField sizeToFit];
	//motionCell.textField.backgroundColor = [UIColor redColor];
	//NSLog(@"setting motionCell.textField=%@", _tag.msEventString);
	
	if(_tag.has3DCompass){
		motionCell.label.text=NSLocalizedString(@"Motion Sensor",nil);
	}else if(_tag.tagType == PIR){
		motionCell.label.text=NSLocalizedString(@"IR Sensor",nil);
	}else if(_tag.hasALS){
		motionCell.label.text=NSLocalizedString(@"Motion Light Sensor",nil);
	}
	else{
		motionCell.label.text=NSLocalizedString(@"Reed Sensor",nil);
	}
	if(_tag.cap!=0)
	{
		NSString *capCellText;
		if(_tag.has13bit && _tag.tagType!=TCProbe){
			float dp = dewPoint(_tag.cap, _tag.temperatureDegC);
			capCellText = [NSString stringWithFormat:@"%.0f%%/%.0f°%@", _tag.cap, temp_unit==1?dp*9.0/5.0+32.0:dp,temp_unit==1?@"F":@"C"];
		}
		else if(_tag.hasThermocouple){
			// internal chip temperature
			capCellText = [NSString stringWithFormat:@"%.0f°C/%.0f°F\t\t", _tag.cap, _tag.cap*9.0/5.0+32.0];
		}
		else
			capCellText = [NSString stringWithFormat:@"%.0f%%", _tag.cap];
		
		NSString *capEvent = _tag.capEventString;
		if(capEvent.length>0)
			capCell.textField.text = [capCellText stringByAppendingFormat:@" (%@)", capEvent];
		else
			capCell.textField.text = capCellText;

		[capCell addSwatch:_tag.capEventStateSwatch animated:animated];
	};
	if(_tag.hasALS)
	{
		NSString* lightCellText = [NSString stringWithFormat:_tag.lux<100?@"%.2f lux" : @"%.1f lux", _tag.lux];
		NSString* lightEvent = _tag.lightEventString;
		if(lightEvent.length>0)
			lightCell.textField.text = [lightCellText stringByAppendingFormat:@" (%@)", lightEvent];
		else
			lightCell.textField.text = lightCellText;
		
		[lightCell addSwatch:_tag.lightEventStateSwatch animated:animated];
	}
	
	NSString *tempCellText = [NSString stringWithFormat:@"%.0f°C/%.0f°F", _tag.temperatureDegC, _tag.temperatureDegC*9.0/5.0+32.0];	
	if(_tag.tempEventState==TooLow)
		temperatureCell.textField.text = [tempCellText stringByAppendingString:NSLocalizedString(@"(Too low)",nil)];
	else if(_tag.tempEventState==TooHigh)
		temperatureCell.textField.text = [tempCellText stringByAppendingString:NSLocalizedString(@"(Too high)",nil)];
	else
		temperatureCell.textField.text = tempCellText;

	[temperatureCell addSwatch:_tag.tempEventStateSwatch animated:animated];
	
	if(newTag.isCam){
		if([self.navigationController.topViewController isKindOfClass:[DropcamViewController class]]){
			[((DropcamViewController*)self.navigationController.topViewController) updateTag:newTag];
		}
		[WebImageOperations processImageDataWithURLString:[NSString stringWithFormat:@"%@dropcam/%@/thumb?%f",WSROOT,
														   newTag.uuid, [[NSDate date] timeIntervalSinceReferenceDate] ]
												 andBlock:^(NSData *d) {
													 
													 UIImage* image = [[[UIImage alloc]initWithData:d] autorelease];
													 if(image==nil){
														 imageView.image = [UIImage imageNamed:@"camera_off.png"];
														 return;
													 }
													 imageView.image = [image roundedCornerImage:8*[[UIScreen mainScreen] scale] borderSize:0];
													 
												 }];
		
	}else if(oldtag==nil || ![oldtag.image_md5 isEqualToString:newTag.image_md5])
	{
		UIImage* image = newTag.image_md5.length>0?[[[ImageStore defaultImageStore] imageForKey:_tag.uuid] roundedCornerImage:8*[[UIScreen mainScreen]scale] borderSize:0]
		: [ImageStore placeholderImageNamed:_tag.placeHolderImageName];
		imageView.image = image;
		NSLog(@"image size=%f x %f", image.size.width, image.size.height);
	}

	
	if(oldtag!=nil){
		
		//<##>
		[self animateCellPresence:resetEventCell fromArray:oldCells toArray:cellArray];
		[self animateCellPresence:calibrateRadioCell fromArray:oldCells toArray:cellArray];
		[self animateCellPresence:ds18Cell fromArray:oldCells toArray:cellArray];
		[self animateCellPresence:_thermostatCell fromArray:oldCells toArray:cellArray];

		//[self animateCellPresence:updatedCell fromArray:oldCells toArray:cellArray];
		if(moreCell1.expansionStyle==UIExpansionStyleExpanded){
			[self animateCellPresence:signalCell fromArray:oldCells toArray:cellArray];
			[self animateCellPresence:batteryCell fromArray:oldCells toArray:cellArray];
			[self animateCellPresence:beepOptionCell fromArray:oldCells toArray:cellArray];
		}
		[self animateCellPresence:lightCell fromArray:oldCells toArray:cellArray];
		[self animateCellPresence:motionCell fromArray:oldCells toArray:cellArray];
		[self animateCellPresence:capCell fromArray:oldCells toArray:cellArray];
		[self animateCellPresence:dimCell fromArray:oldCells toArray:cellArray];
		[self animateCellPresence:dimSpeedCell fromArray:oldCells toArray:cellArray];
		[self animateCellPresence:camDetailCell fromArray:oldCells toArray:cellArray];
		
		[self animateScriptListFromOld:oldtag.scripts ToNew:newTag.scripts];
		

		//int oldTagSec2 = (oldtag.hasThermostat?4: 3) + (moreCell2.expansionStyle==UIExpansionStyleExpanded?(oldtag.hasMotion?4:3):0) ;
		if((oldtag.isNest != newTag.isNest) || (oldtag.supportsHomeAway!=newTag.supportsHomeAway))
		{
			[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationFade];
		}
		else
		if(oldtag.isWeMo != newTag.isWeMo || oldtag.isCam!=newTag.isCam)
		{
			[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationFade];
		}
		else{

			if(oldtag.lit!=newTag.lit){
				if(newTag.isWeMo || newTag.isCam){
					[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];

					//[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:1 inSection:0], [NSIndexPath indexPathForItem:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
				}else{
					if(moreCell2.expansionStyle==UIExpansionStyleExpanded){
						[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:1 inSection:2], [NSIndexPath indexPathForItem:3 inSection:2]] withRowAnimation:UITableViewRowAnimationFade];
						[[self tableView] reloadData];
					}else
					[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:1 inSection:2]] withRowAnimation:UITableViewRowAnimationFade];
				}
			}
			
			//if(moreCell2.expansionStyle==UIExpansionStyleExpanded){
				if(!oldtag.hasMotion && newTag.hasMotion)
				[self.tableView insertRowsAtIndexPaths:
				 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:1 inSection:2],nil] withRowAnimation:UITableViewRowAnimationFade];
				else if(oldtag.hasMotion && !newTag.hasMotion)
				[self.tableView deleteRowsAtIndexPaths:
				 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:1 inSection:2],nil] withRowAnimation:UITableViewRowAnimationFade];
			//}
			
			if(!oldtag.isKumostat && newTag.isKumostat)
			[self.tableView insertRowsAtIndexPaths:
			 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:0 inSection:2],nil] withRowAnimation:UITableViewRowAnimationFade];
			else if(oldtag.isKumostat && !newTag.isKumostat)
			[self.tableView deleteRowsAtIndexPaths:
			 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:0 inSection:2],nil] withRowAnimation:UITableViewRowAnimationFade];

		}
		[oldtag release];
		if(oldtag!=nil)
			[self.tableView endUpdates];
	}
}
// don't change _dvc.tag.scripts directly, call this function
-(void)updateScripts:(NSMutableArray*) scripts{
	NSMutableArray* old_list = [_tag.scripts retain];
	
	[self.tableView beginUpdates];
	_tag.scripts = scripts;

	[self animateScriptListFromOld:old_list ToNew:scripts];
	[self.tableView endUpdates];
	[old_list release];
}
-(void)animateScriptListFromOld:(NSArray*)old_list ToNew:(NSArray*)new_list{
	NSUInteger base;
	if(old_list.count > new_list.count)
	{
		base = new_list.count+1;
		NSUInteger diff = old_list.count +1- base;
		
		NSMutableArray* ips =[[[NSMutableArray alloc] initWithCapacity:diff] autorelease];
		for(NSUInteger i=base;i<base+diff;i++)
			[ips addObject:[NSIndexPath indexPathForRow:i inSection:1]];
		[self.tableView deleteRowsAtIndexPaths:ips withRowAnimation:UITableViewRowAnimationFade];
	}
	else if(old_list.count < new_list.count){
		base = old_list.count+1;
		NSUInteger diff = new_list.count +1- base;
		
		NSMutableArray* ips =[[[NSMutableArray alloc] initWithCapacity:diff] autorelease];
		for(NSUInteger i=base;i<base+diff;i++)
			[ips addObject:[NSIndexPath indexPathForRow:i inSection:1]];
		[self.tableView insertRowsAtIndexPaths:ips withRowAnimation:UITableViewRowAnimationFade];
	}//else
		//base = old_list.count+1;
	/*
	NSMutableArray* ips2 =[[[NSMutableArray alloc] initWithCapacity:base-1] autorelease];
	for(NSUInteger i=1;i<base;i++)
		[ips2 addObject:[NSIndexPath indexPathForRow:i inSection:1]];
	[self.tableView reloadRowsAtIndexPaths:ips2 withRowAnimation:UITableViewRowAnimationFade];
	*/
	[self.tableView reloadData];
}
-(void)animateCellPresence:(UITableViewCell*)cell fromArray:(NSArray*)oldCells toArray:(NSArray*)newCells{
	NSUInteger oldIndex = [oldCells indexOfObject:cell];
	NSUInteger newIndex = [newCells indexOfObject:cell];
	if(oldIndex==NSNotFound && newIndex!=NSNotFound){
		[self.tableView insertRowsAtIndexPaths:
		 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:newIndex inSection:0],nil] withRowAnimation:UITableViewRowAnimationFade];
	}else if(newIndex==NSNotFound && oldIndex!=NSNotFound){
		[self.tableView deleteRowsAtIndexPaths:
		 [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:oldIndex inSection:0],nil] withRowAnimation:UITableViewRowAnimationFade];
	}
}
- (void)setTag:(NSMutableDictionary*)newTag
{
	self.beep_option_choices = @[NSLocalizedString(@"Until moved",nil),NSLocalizedString(@"5 times",nil),NSLocalizedString(@"10 times",nil),
							NSLocalizedString(@"15 times",nil),NSLocalizedString(@"20 times",nil),NSLocalizedString(@"30 times",nil),NSLocalizedString(@"Until stopped",nil)];
	self.dim_speed_choices =@[NSLocalizedString(@"Immediate",nil),NSLocalizedString(@"Gradually",nil),NSLocalizedString(@"Very gradually",nil)];

	if(newTag.hasBeeper){
		beep_option_choices_val=beep_option_choices_val_ms;
		self.navigationItem.rightBarButtonItem = _beepBtn;
	}
	else{
		self.navigationItem.rightBarButtonItem =  _pingNowBtn;
	}
	[self updateTag:newTag loadThermostatSlider:YES animated:NO];
	
	switch(_tag.tagType){
		case ExtResSensor:
		case CapSensor:
			self.staticToolBarItems = [NSArray arrayWithObjects:_pictureBtn, spacerItem, _pingBtn, spacerItem, _optionsBtn, nil];
			capCell.label.text=NSLocalizedString(@"Water/Moisture",nil);
			break;

		case MotionSensor:
		case MotionRH:
		case TagPro:
		case ALS8k:
			self.staticToolBarItems = [NSArray arrayWithObjects:_pictureBtn, spacerItem , _stopBeepBtn,
									   spacerItem, _armBtn, spacerItem, _pingBtn, spacerItem, _optionsBtn, nil];
			capCell.label.text=NSLocalizedString(@"Humidity",nil);
			break;

		case Thermostat:
			self.staticToolBarItems = [NSArray arrayWithObjects:_pictureBtn, spacerItem , _pingBtn, spacerItem, _optionsBtn, nil];
			capCell.label.text=NSLocalizedString(@"Humidity",nil);
			break;
		case ReedSensor:
		case ReedSensor_noHTU:
		case PIR:
			self.staticToolBarItems = [NSArray arrayWithObjects:_pictureBtn, spacerItem ,
									   _armBtn, spacerItem, _pingBtn, spacerItem, _optionsBtn, nil];
			capCell.label.text=NSLocalizedString(@"Humidity",nil);
			break;
		case TCProbe:
			self.staticToolBarItems = [NSArray arrayWithObjects:_pictureBtn, spacerItem, _pingBtn, spacerItem, _optionsBtn, nil];
			capCell.label.text= _tag.hasThermocouple?NSLocalizedString(@"Chip Temperature",nil): NSLocalizedString(@"Wood Moisture Equivalent",nil);
			break;

		case WeMo:
			self.staticToolBarItems = [NSArray arrayWithObjects:_pictureBtn, nil];
		break;
		
		default:
			self.staticToolBarItems = [NSArray arrayWithObjects:_pictureBtn, spacerItem,_stopBeepBtn, 
									   spacerItem, _pingBtn, spacerItem, _optionsBtn, nil];
			break;
			
	}
	if(_tag.hasThermocouple){
		capCell.iconImage.image = [UIImage imageNamed:@"icon_chip"];
		capCell.accessoryType = UITableViewCellAccessoryNone;
		capCell.userInteractionEnabled=NO;
	}else{
		capCell.iconImage.image = [UIImage imageNamed:@"icon_humidity"];
		capCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		capCell.userInteractionEnabled=YES;
	}
	if(_tag.hasProtimeter){
		temperatureCell.label.text = NSLocalizedString(@"Chip Temperature",nil);
	}else{
		temperatureCell.label.text = NSLocalizedString(@"Temperature",nil);
	}
	switch(_tag.tagType){
		
		case MotionSensor:
		case MotionRH:
		case TagPro:
		case ALS8k:
			doorStatsCell.textLabel.text=NSLocalizedString(@"Motion/Door Logs",nil);
			break;
			
		case ReedSensor:
		case ReedSensor_noHTU:
			doorStatsCell.textLabel.text=NSLocalizedString(@"Door/Window Logs",nil);
			
		case PIR:
			doorStatsCell.textLabel.text=NSLocalizedString(@"Motion/Occupancy Logs",nil);
			break;
			
		default:
			break;			
	}
	if(_tag.hasALS){
		tempStatsCell.textLabel.text =NSLocalizedString(@"Temperature/RH/Lux Chart",nil);
	}else if(_tag.hasCap){
		tempStatsCell.textLabel.text = _tag.tagType==CapSensor?NSLocalizedString(@"Temperature/Moisture Chart",nil): NSLocalizedString(@"Temperature/RH Chart",nil);
	}else{
		tempStatsCell.textLabel.text =NSLocalizedString(@"Temperature Chart",nil);
	}
	if(_tag.isNest)
		allowLocalCell.title = NSLocalizedString(@"Turn off instead of set away",nil);
	else
		allowLocalCell.title = NSLocalizedString(@"Disable Local Control",nil);
	
	self.toolbarItems=self.staticToolBarItems;
	
	[self.tableView reloadData];
	[self.tableView reloadSectionIndexTitles];
	[self.tableView setNeedsLayout];
	
	if (self.masterPopoverController != nil) {
		[self.masterPopoverController dismissPopoverAnimated:YES];
	}		
}
-(NSString*)doorCellName{
	return doorStatsCell.textLabel.text;
}
- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	
}
- (void)showLoadingBarItem:(id) item
{
	if([item isKindOfClass:[TableLoadingButtonCell class]]){
		[((TableLoadingButtonCell*)item) showLoading];
	}
	else if([item isKindOfClass:[IASKPSThermostatViewCell class]]){
		[((IASKPSThermostatViewCell*)item) showLoading];
	}
	else if([item isKindOfClass:[IASKPSSliderSpecifierViewCell class]]){
		[((IASKPSSliderSpecifierViewCell*)item) showLoading];
	}
	else if([item isKindOfClass:[IASKPSTextFieldSpecifierViewCell class]]){
		[((IASKPSTextFieldSpecifierViewCell*)item) showLoading];
	}
	else if([item isKindOfClass:[IASKPSToggleSwitchSpecifierViewCell class]]){
		[((IASKPSToggleSwitchSpecifierViewCell*)item) showLoading];
	}
	else if([item isKindOfClass:[SnippetCategoryCell class]]){
		[((SnippetCategoryCell*)item) showLoading];
	}
	else [super showLoadingBarItem:item];
}
- (void)revertLoadingBarItem:(id) item{
	if([item isKindOfClass:[TableLoadingButtonCell class]]){
		[((TableLoadingButtonCell*)item) revertLoading];
	}
	else if([item isKindOfClass:[IASKPSThermostatViewCell class]]){
		[((IASKPSThermostatViewCell*)item) revertLoading];
	}
	else if([item isKindOfClass:[IASKPSSliderSpecifierViewCell class]]){
		[((IASKPSSliderSpecifierViewCell*)item) revertLoading];
	}
	else if([item isKindOfClass:[IASKPSTextFieldSpecifierViewCell class]]){
		[((IASKPSTextFieldSpecifierViewCell*)item) revertLoading];
	}
	else if([item isKindOfClass:[IASKPSToggleSwitchSpecifierViewCell class]]){
		[((IASKPSToggleSwitchSpecifierViewCell*)item) revertLoading];
	}
	else if([item isKindOfClass:[SnippetCategoryCell class]]){
		[((SnippetCategoryCell*)item) revertLoading];
	}
	else [super revertLoadingBarItem:item];
}

-(void)armBtnPressed:(id)sender{	
	ActionSheet_Blocks *sheet = [[ActionSheet_Blocks alloc] init];
	[sheet addRedButtonWithTitle:NSLocalizedString(@"Arm",nil) block:^(NSInteger index){
		[_delegate armBtnPressed:sender];
	}];
	[sheet addButtonWithTitle:NSLocalizedString(@"Disarm",nil) block:^(NSInteger index){
		[_delegate disarmBtnPressed:sender];
	}];
	[sheet addCancelButtonWithTitle:NSLocalizedString(@"Cancel",nil)];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) [sheet showFromBarButtonItem:sender viewToBlur:self.splitViewController.view];
	else [sheet showInView:[[self view] window]];
	[sheet release];
}
-(void)doPickImage:(id)sender fromLibrary:(BOOL)fromLibrary{

	if ([[UIDevice currentDevice].systemVersion floatValue] >= 8 && fromLibrary){
		if([PHPhotoLibrary authorizationStatus]==PHAuthorizationStatusDenied && ![UIImagePickerController
																				 isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
			
			[[UIApplication sharedApplication] openURL:[NSURL  URLWithString:UIApplicationOpenSettingsURLString]];
			return;
		}
		if([PHPhotoLibrary authorizationStatus]==PHAuthorizationStatusNotDetermined){
			[PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
				switch (status) {
					case PHAuthorizationStatusAuthorized:
					case PHAuthorizationStatusRestricted:
						dispatch_async(dispatch_get_main_queue(), ^(){ [self doPickImage:sender fromLibrary:fromLibrary];});
						break;
					default:
						break;
				}
			}];
			return;
		}
	}


//	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
	if(!fromLibrary)
	{
		
		DBCameraViewController *cameraController = [DBCameraViewController initWithDelegate:self ];
		[cameraController setForceQuadCrop:YES];
		[cameraController setCameraSegueConfigureBlock:^( DBCameraSegueViewController *segue ) {
			segue.cropMode = YES;
//			[segue reset:YES];
		}];
		
		DBCameraContainerViewController *container = [[DBCameraContainerViewController alloc] initWithDelegate:self cameraSettingsBlock:^(DBCameraView *cameraView, DBCameraContainerViewController *container) {
			[cameraView.photoLibraryButton setHidden:YES]; //Hide Library button
		}];
		[container setCameraViewController:cameraController];
		[container setFullScreenMode];
		
		UINavigationController *nav = [[[UINavigationController alloc] initWithRootViewController:container] autorelease];
		[nav setNavigationBarHidden:YES];
		[self presentViewController:nav animated:YES completion:nil];
		
		
		//[imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
		//imagePicker.modalPresentationStyle =UIModalPresentationFullScreen;
		//imagePicker.cameraDevice=UIImagePickerControllerCameraDeviceRear;
		
//		imagePicker.cameraCaptureMode=UIImagePickerControllerCameraCaptureModePhoto;
	//	imagePicker.mediaTypes=@[(NSString *)kUTTypeImage];
		//imagePicker.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
	}
	else
	{
		UIImagePickerController *imagePicker =[[UIImagePickerController alloc] init];
		imagePicker.modalPresentationStyle = UIModalPresentationCurrentContext;
		imagePicker.allowsEditing=YES;

		if([UIImagePickerController isSourceTypeAvailable:
			UIImagePickerControllerSourceTypeSavedPhotosAlbum])
		{
			[imagePicker setSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
			imagePicker.modalPresentationStyle =UIModalPresentationPopover;
		}
		else if([UIImagePickerController isSourceTypeAvailable:
					UIImagePickerControllerSourceTypePhotoLibrary])
		{
			[imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
			imagePicker.modalPresentationStyle =UIModalPresentationPopover;
		}

		[imagePicker setDelegate:self];
		UIPopoverPresentationController *presentationController = imagePicker.popoverPresentationController;
		
		if([sender isKindOfClass:[UIBarButtonItem class]])
			presentationController.barButtonItem = sender;
		else if([sender isKindOfClass: [UITableViewCell class]]){
			UITableViewCell* cell = sender;
			presentationController.sourceRect = cell.bounds;
			presentationController.sourceView = cell.contentView;
		}
		else if([sender isKindOfClass: [UIView class]]){
			UIView* view = sender;
			presentationController.sourceRect = view.frame;
			presentationController.sourceView = view.superview;
		}
		
		presentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
		
		[self presentViewController:imagePicker animated:YES completion:^{
			//.. done presenting
		}];
		[imagePicker release];

	}


	
/*	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		
		imagePickerPopover = [[UIPopoverController alloc] 
							  initWithContentViewController:imagePicker];
		
		[imagePickerPopover setDelegate:self];
		[imagePickerPopover presentPopoverFromAnything:sender];
	} else {
		//[self presentModalViewController:imagePicker animated:YES];
		[self presentViewController:imagePicker animated:YES completion:nil];
	}*/
	
}
#pragma mark - DBCameraViewControllerDelegate

- (void) camera:(id)cameraViewController didFinishWithImage:(UIImage *)orgimage withMetadata:(NSDictionary *)metadata
{
	[self dismissViewControllerAnimated:YES completion:nil];
	UIImage* image = [orgimage resizedImage:CGSizeMake(DETAIL_WIDTH, DETAIL_HEIGHT) interpolationQuality:kCGInterpolationHigh];
	self.tag.image_md5 = [[ImageStore defaultImageStore]setImage:image forKey:self.tag.uuid];
	[self updateImage:image];
	[_delegate tagImageUpdated:image];
}

- (void) dismissCamera:(id)cameraViewController{
	[self dismissViewControllerAnimated:YES completion:nil];
	[cameraViewController restoreFullScreenMode];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[self dismissViewControllerAnimated:YES completion:nil];
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	[self dismissViewControllerAnimated:YES completion:nil];
	
	/*	if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		[self dismissViewControllerAnimated:YES completion:nil];
	 } else {
		[imagePickerPopover dismissPopoverAnimated:YES];
		[imagePickerPopover autorelease];
		imagePickerPopover = nil;
	 }
	 */
	
	UIImage *orgimage = [info objectForKey:UIImagePickerControllerEditedImage];//UIImagePickerControllerOriginalImage];
	//CGFloat orgwidth = orgimage.size.width;
	//CGFloat newheight = orgwidth*DETAIL_HEIGHT/DETAIL_WIDTH;
	
	UIImage* image = [orgimage resizedImage:CGSizeMake(DETAIL_WIDTH, DETAIL_HEIGHT) interpolationQuality:kCGInterpolationHigh];
	
	//UIImage* image = [[orgimage croppedImage:CGRectMake(0, (orgimage.size.height-newheight)/2, orgwidth, newheight)]
	//				  resizedImage:CGSizeMake(DETAIL_WIDTH, DETAIL_HEIGHT) interpolationQuality:kCGInterpolationMedium];
	
	self.tag.image_md5 = [[ImageStore defaultImageStore]setImage:image forKey:self.tag.uuid];
	[self updateImage:image];
	[_delegate tagImageUpdated:image];
}


-(void)pictureBtnPressed:(id)sender{
	if(_tag.isCam){
		[self openCamDetailView];return;
	}
	ActionSheet_Blocks *sheet = [[ActionSheet_Blocks alloc] init];

	if([ImageStore hasImageForKey:_tag.uuid]){
		[sheet addRedButtonWithTitle:NSLocalizedString(@"Delete picture",nil) block:^(NSInteger index){
			[[ImageStore defaultImageStore] deleteImageForKey:_tag.uuid];
			_tag.image_md5 = @"";
			
			[self.tableView beginUpdates];
			[imageView setImage:nil];
			[self.tableView reloadSectionIndexTitles];
			[self.tableView setNeedsLayout];
			[self.tableView endUpdates];
			//[_delegate tagUpdated];
			[_delegate tagImageDeleted];
		}];
	}
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
		[sheet addButtonWithTitle:[ImageStore hasImageForKey:_tag.uuid]?NSLocalizedString(@"Retake",nil):NSLocalizedString(@"Take Picture",nil) block:^(NSInteger index){
			[self doPickImage:sender fromLibrary:NO];
		}];

	[sheet addButtonWithTitle:NSLocalizedString(@"Choose from Library",nil) block:^(NSInteger index){
		[self doPickImage:sender fromLibrary:YES];
	}];

	[sheet addCancelButtonWithTitle:NSLocalizedString(@"Cancel",nil)];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) [sheet showFromAnything:sender viewToBlur:self.splitViewController.view];
	else [sheet showInView:[[self view] window]];
	[sheet release];
	
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 3;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section==0){
		return moreCell1.expansionStyle==UIExpansionStyleExpanded ? cellArray.count : [cellArray indexOfObject:moreCell1]+1;
		// (reset state or calibrate freq), temperature, thermostat choice (if chosen, thermostat control), (if HTU or cap, cap), motion, beep option, more... (battery, updated, signal strength, at, edit name, comment)
//		return 3 + ((_tag.eventState==Moved||_tag.needFreqCal )?1:0) +  (_tag.hasDS18?1:0)+ (_tag.hasBeeper?1:0) + (_tag.hasMotion?1:0) +
	//	(_tag.cap==0?0:1) + ((_tag.hasThermostat || _tag.thermostatRef!=nil)?1:0) + (moreCell1.expansionStyle==UIExpansionStyleExpanded?6:0);
	}else if(section==2){
		if(_tag.isNest)return _tag.supportsHomeAway?3:2;
		if(_tag.isWeMo || _tag.isCam)return 1;  // only unassociate.
		// light on, light off, more... (temp stats, door stats, reset tag, unassociate)
		return (_tag.hasThermostat?4: 3) + (moreCell2.expansionStyle==UIExpansionStyleExpanded?4:0) + (_tag.hasMotion?1:0);
	}else{
		return (_tag.scripts.count)+1;
	}
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
	return indexPath.section==1;
}
-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
	return indexPath.row==0? UITableViewCellEditingStyleInsert : UITableViewCellEditingStyleDelete;
}
-(BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath{
	return YES;
}
-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath{
	return NO;
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)ip{
	
	if(editingStyle==UITableViewCellEditingStyleDelete)
	{
		[_delegate deleteScriptBtnPressed:(int)(ip.row-1)];
		[_tag.scripts removeObjectAtIndex:ip.row-1];
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:ip] withRowAnimation: UITableViewRowAnimationFade];
	}
	else if(editingStyle==UITableViewCellEditingStyleInsert){
		[_delegate addScriptBtnPressed:addScriptCell];		
	}
}
-(void)openCamDetailView{
	DropcamViewController* camvc = [[[DropcamViewController alloc]initForTag:_tag] autorelease ];
	[self.navigationController pushViewController:camvc animated:YES];
	[camvc reload];
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if(indexPath.section==1 && indexPath.row>0){
		[_delegate reconfigureScriptBtnPressed:(int)(indexPath.row-1)];
		return;
	}
	UITableViewCell* btn = (UITableViewCell*)[tableView cellForRowAtIndexPath:indexPath];

	if([btn isKindOfClass:[IASKPSToggleSwitchSpecifierViewCell class]]){
		[((IASKPSToggleSwitchSpecifierViewCell*)btn) toggleHelp];
		[tableView beginUpdates];
		[tableView endUpdates];
	}
	else if(btn==moreCell1){
		NSInteger base = [cellArray indexOfObject:moreCell1];
		NSMutableArray* ips = [NSMutableArray arrayWithCapacity:8];
		for(NSInteger i=base+1; i<cellArray.count; i++)
			[ips addObject:[NSIndexPath indexPathForRow:i inSection:0]];
		
		if(moreCell1.expansionStyle==UIExpansionStyleCollapsed){
			[self.tableView beginUpdates];
			[moreCell1 setExpansionStyle:UIExpansionStyleExpanded animated:YES];
			[self.tableView insertRowsAtIndexPaths:ips withRowAnimation:UITableViewRowAnimationTop];
			[self.tableView endUpdates];
		}else{
			[self.tableView beginUpdates];
			[moreCell1 setExpansionStyle:UIExpansionStyleCollapsed animated:YES];
			[self.tableView deleteRowsAtIndexPaths:ips withRowAnimation:UITableViewRowAnimationTop];
			[self.tableView endUpdates];
		}
	}else if(btn==moreCell2){
		int base = _tag.hasThermostat?4: 3;
		if(!_tag.hasMotion)base--;
		
		NSMutableArray* ips = [NSMutableArray arrayWithObjects:[NSIndexPath indexPathForRow:base+1 inSection:2],
						[NSIndexPath indexPathForRow:base+2 inSection:2],[NSIndexPath indexPathForRow:base+3 inSection:2],[NSIndexPath indexPathForRow:base+4 inSection:2], nil];
/*		if(_tag.hasMotion)
		   [ips addObject:[NSIndexPath indexPathForRow: base+4 inSection:2]];
	*/
		if(moreCell2.expansionStyle==UIExpansionStyleCollapsed){
			[self.tableView beginUpdates];
			[moreCell2 setExpansionStyle:UIExpansionStyleExpanded animated:YES];
			[self.tableView insertRowsAtIndexPaths:ips withRowAnimation:UITableViewRowAnimationTop];
			[self.tableView endUpdates];
		}else{
			[self.tableView beginUpdates];
			[moreCell2 setExpansionStyle:UIExpansionStyleCollapsed animated:YES];
			[self.tableView deleteRowsAtIndexPaths:ips withRowAnimation:UITableViewRowAnimationTop];
			[self.tableView endUpdates];
		}
	}
	else if(btn==camDetailCell){
		[self openCamDetailView];
	}
	else if(btn==addScriptCell){

		if(!tableView.isEditing){
			if(_tag.scripts.count==0){
				[_delegate addScriptBtnPressed:btn];
			}else{
				[tableView setEditing:YES animated:YES];
				addScriptCell.textLabel.text=NSLocalizedString(@"Done",nil);
				//[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			}
		}else{
			[tableView setEditing:NO animated:YES];
			[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
		}
	}
	else if(btn==thermostatChoiceCell){
		[_delegate thermostatChoiceBtnPressed:btn];
	}
	else if(btn==resetEventCell){
		 [_delegate resetEventBtnPressed:btn];
	}
	else if(btn==motionCell){
		[_delegate msOptionsBtnPressed:btn];
	}
	else if(btn==capCell){
		[_delegate capOptionsBtnPressed:btn];
	}
	else if(btn==lightCell){
		[_delegate lightOptionsBtnPressed:btn];
	}
	else if(btn==updatedCell){
		[_delegate updateBtnPressed:btn];
		//[_delegate oorOptionsBtnPressed:btn];
	}
	else if(btn==temperatureCell){
		[_delegate tempOptionsBtnPressed:btn];
	}
	else if(btn==signalCell){
		[_delegate showMultiStatsForIds:@[[_tag objectForKey:@"slaveId"]] Uuids:@[_tag.uuid] Type:@"signal"];		
	}
	else if(btn==batteryCell){
		
		OptionPicker *picker = [[OptionPicker alloc]initWithOptions:@[NSLocalizedString(@"Low Battery Notifications",nil), NSLocalizedString(@"Historical Graph",nil)]
													    Selected:-1
															   Done:^(NSInteger selected, BOOL now){
																   if(selected==0){
																	   [_delegate lbOptionsBtnPressed:btn];
																   }else{
																	   [_delegate showMultiStatsForIds:@[[_tag objectForKey:@"slaveId"]] Uuids:@[_tag.uuid] Type:@"batteryVolt"];
																   }
															   } ];
		picker.nowOptions=@[@0,@1];
		//picker.helpText = @"Configure auto-update interval to allow tag transmit temperature and other data periodically in order to capture graphs and detect out-of-range/back-in-range events.";
		[_delegate showUpdateOptionPicker:picker From:btn];
		[picker release];

	}
	else if(btn==calibrateRadioCell){
		[_delegate calibrateRadioBtnPressed:btn];
	}
	else if(btn==unassociateCell){
		[_delegate unassociateBtnPressed:btn];
	}
	else if(btn==specialOptionsCell){
		[_delegate specialOptionsBtnPressed:btn];
	}
	else if(btn == resetStatesCell){
		[_delegate resetStatesBtnPressed:btn];
	}
	else if(btn==dimSpeedCell){
		OptionPicker *picker = [[OptionPicker alloc]initWithOptions:self.dim_speed_choices Selected:[self dim_speed_index]
															   Done:^(NSInteger selected, BOOL now){
																   dimSpeedCell.textField.text = [self.dim_speed_choices objectAtIndex:selected];
																   [[NSUserDefaults standardUserDefaults]
																	setInteger:dim_speed_choices_val[selected] forKey:[@"dim_speed_" stringByAppendingString:_tag.uuid]];
																   [[NSUserDefaults standardUserDefaults]synchronize];
															   } ];
		[self presentPicker:picker fromCell:[tableView cellForRowAtIndexPath:indexPath]];
		[picker release];
	}
	else if(btn==beepOptionCell){
		OptionPicker *picker = [[OptionPicker alloc]initWithOptions:self.beep_option_choices Selected:[self beep_option_index]
															   Done:^(NSInteger selected, BOOL now){
																   beepOptionCell.textField.text = [self.beep_option_choices objectAtIndex:selected];
																   _tag.beepDurationDefault = beep_option_choices_val[selected];
																   [_delegate tagUpdated];
															   } ];
		[self presentPicker:picker fromCell:[tableView cellForRowAtIndexPath:indexPath]];
		[picker release];
	}
	else if(btn==lightOnCell)
		[_delegate lightOnBtnPressed:btn];
	else if(btn==lightOffCell){
		
		if(self.tag.isCam && self.tag.beeping){
			[[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"A time lapse is underway.",nil)
										message:NSLocalizedString(@"The time lapse will be automatically stopped if you turn off streaming.",nil)
							   cancelButtonItem:[RIButtonItem itemWithLabel:NSLocalizedString(@"Cancel",nil) action:^{}]
							   otherButtonItems:[RIButtonItem itemWithLabel:NSLocalizedString(@"Stop & Turn off",nil) action:^{

				[AsyncURLConnection request:[WSROOT stringByAppendingString: @"DropCamLink.asmx/StopTimeLapse"]
									jsonObj:@{ @"slaveId": [NSNumber numberWithInt:_tag.slaveId] }
							  completeBlock:^(NSDictionary* data){
								  _tag.beeping=NO;
								  [_delegate lightOffBtnPressed:btn];
								  
							  }errorBlock:^(NSError* err, id* showFrom){
								  *showFrom=btn;
								  return YES;
							  }setMac:nil ];

			}], nil] autorelease ] show];
		}else
			[_delegate lightOffBtnPressed:btn];
	}else if(btn==tempStatsCell)
		[_delegate tempStatsBtnPressed:btn];
	else if(btn==doorStatsCell)
		[_delegate doorStatsBtnPressed:btn];
}
-(void)presentPicker:(OptionPicker*)picker fromCell:(UITableViewCell*) cell{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
		if(beepOptionPopover!=nil){
			[beepOptionPopover dismissPopoverAnimated:YES]; [beepOptionPopover autorelease];
		}
		beepOptionPopover = [[UIPopoverController alloc]
							 initWithContentViewController:picker];
		beepOptionPopover.popoverContentSize = picker.contentSizeForViewInPopover; //CGSizeMake(280, 350);
		picker.dismissUI=^(BOOL animated){
			[beepOptionPopover dismissPopoverAnimated:animated];
			[beepOptionPopover autorelease]; beepOptionPopover=nil;
		};
		[beepOptionPopover presentPopoverFromRect:cell.bounds inView:cell.contentView
						 permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	}else{
		beepOptionPopover=nil;
		picker.dismissUI=^(BOOL animated){
			[self.navigationController popViewControllerAnimated:animated];
		};
		[self.navigationController pushViewController:picker animated:YES];
	}
	
}
-(void)updateCellArray{
	NSMutableArray* cells = [NSMutableArray arrayWithCapacity:15];
	if(_tag.isCam)
	{
		[cells addObject:camDetailCell];
	}
	if(_tag.isWeMo || _tag.isCam){
		
		if(_tag.lit){
			[cells addObject:lightOffCell];
			[cells addObject:lightOnCell];
			
		}else{
			[cells addObject:lightOnCell];
			[cells addObject:lightOffCell];
		}
		if(_tag.isWeMoLED){
			[cells addObject:dimCell];
			[cells addObject:dimSpeedCell];
		}
		[cells addObject:updatedCell];
	}else{
		if(_tag.needFreqCal){
			[cells addObject:calibrateRadioCell];
		}else if(_tag.eventState==Moved || _tag.eventState==DetectedMovement){
			if(!_tag.hasThermostat)
				[cells addObject:resetEventCell];
		}
		
		if(_tag.hasALS)
			[cells addObject:lightCell];
		
		[cells addObject:temperatureCell];
		if(_tag.hasDS18)
		[cells addObject:ds18Cell];
		
		[cells addObject:thermostatChoiceCell];
		if(_tag.hasThermostat || _tag.thermostatRef!=nil){
			[cells addObject:_thermostatCell];
		}
		if([_tag hasCap] || [_tag hasThermocouple]){
			[cells addObject:capCell];
		}
		if(_tag.hasMotion){
			[cells addObject:motionCell];
		}
		[cells addObject:updatedCell];
	}
	[cells addObject:moreCell1];

	if(_tag.slaveId>=0){
		[cells addObject:batteryCell];
		[cells addObject:signalCell];
	}
	if(_tag.hasBeeper){
		[cells addObject:beepOptionCell];
	}
	[cells addObject:managerCell];
	[cells addObject:nameCell];
	[cells addObject:commentCell];
	[cellArray release];
	cellArray = [cells retain];
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	if(section==1)
		return NSLocalizedString(@"KumoApps are scripts/programs that run on the Cloud.",nil);
	else return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section==0){
		return [cellArray objectAtIndex:indexPath.row];
	}
	else if(indexPath.section==2){
		NSInteger row = indexPath.row;
		if(_tag.hasThermostat){
			if(_tag.supportsHomeAway){
				if(row==0)return allowLocalCell;
				row--;
			}
		}
		if(_tag.isWeMo || _tag.isCam){
			return unassociateCell;
		}else{
			NSMutableArray* cellArray2 = [[[NSMutableArray alloc] initWithCapacity:10]autorelease];
			[cellArray2 addObject:tempStatsCell];
			if(_tag.hasMotion)[cellArray2 addObject:doorStatsCell];
			
			if(!_tag.isNest){
				[cellArray2 addObject:_tag.lit?lightOffCell:lightOnCell];
				[cellArray2 addObject:moreCell2];
				[cellArray2 addObject:_tag.lit?lightOnCell:lightOffCell];
			}
			if(_tag.slaveId>=0){
				[cellArray2 addObject:specialOptionsCell];
				[cellArray2 addObject:resetStatesCell];
			}
			[cellArray2 addObject:unassociateCell];
			/*switch (row) {
				case 0: return tempStatsCell;
				case 1: return doorStatsCell;
				case 2: return _tag.isNest?unassociateCell:( _tag.lit ? lightOffCell: lightOnCell);
				case 3: return moreCell2;
				case 4: return _tag.lit ? lightOnCell : lightOffCell;
				case 5: return resetStatesCell;
				case 6: return unassociateCell;
			}*/
			return [cellArray2 objectAtIndex:row];
		}
	}else{
		NSInteger row = indexPath.row;
		if(row==0){
			
			if(tableView.isEditing)
				addScriptCell.textLabel.text = NSLocalizedString(@"Done",nil);
			else
				addScriptCell.textLabel.text = _tag.scripts.count>0? NSLocalizedString(@"Install/Remove Apps...",nil) : NSLocalizedString(@"Install KumoApps...",nil);

			return addScriptCell;
		}
		else{

			NSMutableDictionary* script = [_tag.scripts objectAtIndex:row-1];
			IASKPSToggleSwitchSpecifierViewCell *cell = (IASKPSToggleSwitchSpecifierViewCell *)[script objectForKey:@"_cell"];
			if (!cell) {
				cell = [[IASKPSToggleSwitchSpecifierViewCell newLoadingWithTitle:@"" Progress:nil helpText:nil delegate:self] autorelease];
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				//cell.label.lineBreakMode = NSLineBreakByWordWrapping;
				//cell.label.numberOfLines = 0;
				//cell.label.font = [UIFont systemFontOfSize:12];
				[script setObject:cell forKey:@"_cell"];
			}
			cell.script = script; //[script objectForKey:@"id"];
//			NSString* shortened;
//			if(script.name.length>20)shortened= [script.name substringToIndex:17];
//			else shortened=script.name;
			cell.label.text = script.name;// shortened;
			if(script.lastError.length==0){
				cell.helpText.textColor=[UIColor blackColor];
				if((id)script.lastLog!=[NSNull null]){
					cell.detailText=[NSString stringWithFormat:@"%@ - %@", [script.lastLog objectForKey:@"msg"],[script.lastLog objectForKey:@"time"],nil];
				}
			}
			else{
				cell.helpText.textColor=[UIColor redColor];
				cell.detailText = script.lastError;
			}
			cell.toggleOn = script.running;
			return cell;
		}
	}
	return nil;
}
-(CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
    if(section == 0){
		if(_tag.image_md5.length>0 || _tag.isCam)
			return DETAIL_HEIGHT+10;
	}
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)ip{
	UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:ip];
	if([cell isKindOfClass:[IASKPSThermostatViewCell	class]])
		return 147;
	else if (cell == temperatureCell)return 70;
	else if (cell == lightCell)return 70;
//	else if (cell == capCell)return 90;
	else if (cell == motionCell)return 70;
	else if(ip.section==1 && [cell isKindOfClass:[IASKPSToggleSwitchSpecifierViewCell	class]]){

		/*NSString *cellText = ((IASKPSToggleSwitchSpecifierViewCell*)cell).helpText.text;
		UIFont *cellFont = [UIFont systemFontOfSize:12];
		CGSize constraintSize = CGSizeMake(self.tableView.frame.size.width*14.0/16.0-140.0, MAXFLOAT);
		CGSize labelSize = [cellText sizeWithFont:cellFont constrainedToSize:constraintSize lineBreakMode:NSLineBreakByWordWrapping];
		return labelSize.height + 40;*/
		return [((IASKPSToggleSwitchSpecifierViewCell*)cell) getHeight];
	}
	else if([cell isKindOfClass:[IASKPSToggleSwitchSpecifierViewCell class]]){
		return [((IASKPSToggleSwitchSpecifierViewCell*)cell) getHeight];
	}
	else 	if([cell isKindOfClass:[IASKPSSliderSpecifierViewCell	class]])
		return 86;
	else
		return 44;
}

- (UIView *)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section {
	if(section==0){
		if(_tag.isCam || _tag.image_md5.length>0){
			return headerView;
		}
	}
	return nil;
}
-(void)updateImage:(UIImage*)image
{
	[self.tableView beginUpdates];
	[imageView setImage:[image roundedCornerImage:8*[[UIScreen mainScreen]scale] borderSize:0]];
	[self.tableView reloadSectionIndexTitles];
	[self.tableView setNeedsLayout];
	[self.tableView endUpdates];	
}


- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
/*	if(imagePickerPopover==popoverController){
		[imagePickerPopover autorelease];
		imagePickerPopover = nil;
	}else*/ if(beepOptionPopover == popoverController){
		[beepOptionPopover autorelease];
		beepOptionPopover = nil;
	}
}
-(void)updateHomeAwayLabel{
	
}
-(void)editedTableViewCell:(id)cell{
	if(cell==nameCell){
		_tag.name = nameCell.textField.text;
		[_delegate tagUpdated];
	}
	else if(cell==commentCell){
		_tag.comment = commentCell.textField.text;
		[_delegate tagUpdated];
	}
	else if(cell==dimCell){
		[_delegate dimLED:cell dimTo:dimCell.slider.value speed:[self dim_speed]];
	}
	else if(cell==_thermostatCell){
		[_delegate thermostatSet:_thermostatCell];
	}
	else if(cell == _thermostatCell.hvacOn){
		[_delegate thermostatTurnOnOff:_thermostatCell turnOn:_thermostatCell.hvacOn.on];
	}
	else if(cell == _thermostatCell.fanOn){
		[_delegate thermostatFanOnOff:_thermostatCell fanOn:_thermostatCell.fanOn.on];
	}
	else if(cell == allowLocalCell){
		[_delegate thermostatDisableLocal:cell disable:allowLocalCell.toggle.on];
		
	}
	else if(cell==ds18Cell){
		[_delegate enableDS18:cell enable:ds18Cell.toggle.on];
	}
	else if([cell isKindOfClass:[IASKPSToggleSwitchSpecifierViewCell class]]){
		IASKPSToggleSwitchSpecifierViewCell* c = (IASKPSToggleSwitchSpecifierViewCell*)cell;
		[_delegate enableKumoApp:c.script enable:c.toggle.on from:c];
	}

}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];

	
	//[self.tableView setBackgroundView:nil];
	//
	[self.tableView setBackgroundView:[[[UIView alloc] init] autorelease]];
	
	self.wantsFullScreenLayout=NO;
	self.tableView.allowsSelectionDuringEditing = YES;

	camDetailCell =[IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"Camera",nil) andIcon:@"icon_camera.png"];
	
	beepOptionCell = [IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"Beep Options",nil)];
	nameCell = [IASKPSTextFieldSpecifierViewCell newEditableWithTitle:NSLocalizedString(@"Edit Name",nil) delegate:self]; nameCell.iconImage.image=[UIImage imageNamed:@"icon_tagname.png"];
	commentCell =  [IASKPSTextFieldSpecifierViewCell newEditableWithPlaceholder:NSLocalizedString(@"Click to add comment",nil) isLast:YES delegate:self]; //[IASKPSTextFieldSpecifierViewCell newEditableWithTitle:@"Comment" delegate:self];
	motionCell = [IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"Motion Sensor",nil) andIcon:@"icon_motionsensor.png"];
	
	batteryCell = [IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"Battery",nil) andIcon:@"icon_battery.png"];
	signalCell = [IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"Signal",nil) andIcon:@"icon_signal.png"];
	managerCell = [IASKPSTextFieldSpecifierViewCell newReadonlyWithTitle:NSLocalizedString(@"Type",nil)];
	
	updatedCell = [IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"Updated",nil)];
	temperatureCell = [IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"Temperature",nil) andIcon:@"icon_temperature.png"];

	
	specialOptionsCell =  [[TableLoadingButtonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	specialOptionsCell.textLabel.textColor = [UISwitch appearance].onTintColor;
	specialOptionsCell.textLabel.text = specialOptionsCell.title = NSLocalizedString(@"Special Options",nil);
	specialOptionsCell.textLabel.textAlignment = NSTextAlignmentCenter;
	specialOptionsCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;


	resetStatesCell = [TableLoadingButtonCell newWithTitle:NSLocalizedString(@"Reset States",nil) Progress:NSLocalizedString(@"Resetting...",nil) andIcon:@"icon_reset.png"];
	unassociateCell = [TableLoadingButtonCell newWithTitle:NSLocalizedString(@"Unassociate Tag",nil) Progress:NSLocalizedString(@"Unassociating...",nil) andIcon:@"icon_trash.png"];
	doorStatsCell = [TableLoadingButtonCell newWithTitle:NSLocalizedString(@"Door Stats",nil) Progress:NSLocalizedString(@"Loading...",nil) andIcon:@"icon_logbook.png"];
	resetEventCell =[TableLoadingButtonCell newWithTitle:NSLocalizedString(@"Reset Moved/Detected",nil) Progress:NSLocalizedString(@"Resetting...",nil)];
	calibrateRadioCell =[TableLoadingButtonCell newWithTitle:NSLocalizedString(@"Calibrate Radio",nil) Progress:NSLocalizedString(@"Calibrating...",nil)];
	
	lightOnCell = [TableLoadingButtonCell newWithTitle:NSLocalizedString(@"Light On",nil) Progress:NSLocalizedString(@"Finding...",nil) andIcon:@"icon_light.png"];
	lightOffCell = [TableLoadingButtonCell newWithTitle:NSLocalizedString(@"Light Off",nil) Progress:NSLocalizedString(@"Finding...",nil)];
	dimCell = [IASKPSSliderSpecifierViewCell newWithTitle:NSLocalizedString(@"LED Brightness",nil) Min:0 Max:100 Step:0.5 Unit:@"%" delegate:self];
	dimSpeedCell = [IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"   Transition Speed",nil)];
	
	tempStatsCell =[TableLoadingButtonCell newWithTitle:NSLocalizedString(@"Temperature Graphs",nil) Progress:NSLocalizedString(@"Loading...",nil) andIcon:@"icon_graph.png"];
	
	addScriptCell =[TableLoadingButtonCell newWithTitle:NSLocalizedString(@"Install KumoApps...",nil) Progress:NSLocalizedString(@"Loading Compatible Apps...",nil) andIcon:@"icon_cloud.png"];
	addScriptCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	allowLocalCell =[IASKPSToggleSwitchSpecifierViewCell  newLoadingWithTitle:NSLocalizedString(@"Turn Off Instead of Away",nil) Progress:NSLocalizedString(@"Configuring...",nil) helpText:NSLocalizedString(@"When enabled, the home/away switch will turn off thermostat completely instead of just setting to 'Away'",nil)
																	 delegate:self];
	ds18Cell = [IASKPSToggleSwitchSpecifierViewCell
				newLoadingWithTitle:NSLocalizedString(@"  Use DS18B20 Probe",nil) Progress:NSLocalizedString(@"  Configuring...",nil) helpText:NSLocalizedString(@"After connecting DS18B20 series external water proof probe, use this to switch to it. ",nil)
				delegate:self];
	
	moreCell1 = [GHCollapsingAndSpinningTableViewCell newWithStyle:UIExpansionStyleCollapsed];
	moreCell2 = [GHCollapsingAndSpinningTableViewCell newWithStyle:UIExpansionStyleCollapsed];
	
	_thermostatCell=[IASKPSThermostatViewCell newWithDelegate:self useDegF:self.delegate.useDegF];
	thermostatChoiceCell=[IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"Controls Thermostat",nil) andIcon:@"icon_thermostat.png"]; // if thermostat, this is "Controlled by"
	capCell = [IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"Humidity",nil) andIcon:@"icon_humidity"];
	lightCell = [IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:NSLocalizedString(@"Ambient Light",nil) andIcon:@"icon_brightness"];
	
	[self updateCellArray];
	
//	armBtnCell = [TableLoadingButtonCell newWithTitle:@"Arm" Progress:@"Arming..."];
//	disarmBtnCell = [TableLoadingButtonCell newWithTitle:@"Disarm" Progress:@"Disarming..."];

	imageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"Placeholder.png"]];
	imageView.userInteractionEnabled=YES;
	[imageView addGestureRecognizer:[[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewTapped)] autorelease]];

	imageView.contentMode = UIViewContentModeScaleAspectFit; //UIViewContentModeCenter;
	imageView.frame = CGRectMake(0, -12, DETAIL_WIDTH, DETAIL_HEIGHT);
	imageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;

	headerView = [[UIView alloc] init];
	[headerView addSubview:imageView];

	
	_beepBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"beep.png"] style:UIBarButtonItemStylePlain
												   target:_delegate action:@selector(beepBtnPressed:)];
	_stopBeepBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"mute.png"] style:UIBarButtonItemStylePlain 
												   target:_delegate action:@selector(stopBeepBtnPressed:)];
	_armBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"disarm.png"] style:UIBarButtonItemStylePlain
											  target:self action:@selector(armBtnPressed:)];
	_pingBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
															 target:_delegate action:@selector(updateBtnPressed:)];

	_pingNowBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
															 target:_delegate action:@selector(updateNowBtnPressed:)];
	
	_optionsBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"gear.png"] style:UIBarButtonItemStylePlain 
												  target:_delegate action:@selector(optionsBtnPressed:)];
	
	_pictureBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
																target:self action:@selector(pictureBtnPressed:)];
	spacerItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];

	UITapGestureRecognizer *gestureRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)] autorelease];
	gestureRecognizer.cancelsTouchesInView=NO;
	[self.tableView addGestureRecognizer:gestureRecognizer];
}
- (IBAction)imageViewTapped{
	[self pictureBtnPressed:imageView];
}

-(void)releaseSubViews
{
	self.beepBtn=nil;
	self.stopBeepBtn=nil;
	self.armBtn=nil;
	self.optionsBtn=nil;
	self.pingBtn=nil;
	self.pingNowBtn=nil;
	self.pictureBtn=nil;
	[specialOptionsCell release]; specialOptionsCell=nil;
	[spacerItem release];spacerItem=nil;
	[headerView release]; headerView=nil;
	[imageView release]; imageView=nil;
	[nameCell release];nameCell=nil;
	[commentCell release];commentCell=nil;
	[motionCell release]; motionCell=nil;
	[batteryCell release]; batteryCell=nil;
	[signalCell release]; signalCell=nil;
	[managerCell release]; managerCell=nil;
	[updatedCell release]; updatedCell=nil;
	[temperatureCell release]; temperatureCell=nil;
	[resetStatesCell release];resetStatesCell=nil;
	[unassociateCell release];unassociateCell=nil;
	[doorStatsCell release]; doorStatsCell=nil;
	[resetEventCell release]; resetEventCell=nil;
	[calibrateRadioCell release]; calibrateRadioCell=nil;
	[lightOnCell release]; lightOnCell=nil;
	[lightOffCell release]; lightOffCell=nil;
	[tempStatsCell release]; tempStatsCell=nil;
	[allowLocalCell release]; allowLocalCell=nil;
	[ds18Cell release]; ds18Cell=nil;
	[thermostatChoiceCell release]; thermostatChoiceCell=nil;
	self.thermostatCell=nil;
	[moreCell1 release]; moreCell1=nil;
	[moreCell2 release]; moreCell2=nil;
	[addScriptCell release]; addScriptCell=nil;
	[capCell release]; capCell=nil;
	[lightCell release]; lightCell=nil;
	[dimSpeedCell release]; dimSpeedCell=nil;
	[dimCell release]; dimCell=nil;
}
- (void)dealloc
{
	[_tag release];
	[_masterPopoverController release];
	[self releaseSubViews];
	self.dim_speed_choices=nil;
	self.beep_option_choices=nil;
	[super dealloc];
}
- (void)viewDidUnload
{
	[super viewDidUnload];
	[self releaseSubViews];
}

- (void)viewWillAppear:(BOOL)animated
{
	self.navigationController.toolbarHidden=NO;

	if([self.navigationController.parentViewController isKindOfClass:[UISplitViewController class]]){
		UISplitViewController* spv =(UISplitViewController*)self.navigationController.parentViewController;
		if(spv.delegate!=self){
			spv.delegate = self;
			[spv willRotateToInterfaceOrientation:self.interfaceOrientation duration:0];
		}
	}

	
	[UIView animateWithDuration:0.25f animations:^{
		self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
		[self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObject:[UIColor blackColor] forKey:UITextAttributeTextColor]];
		self.navigationController.navigationBar.tintColor = [UINavigationBar appearance].tintColor;
	} completion:^(BOOL finished) {
	}];

	[super viewWillAppear:animated];
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
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil delegate:(id<DetailViewControllerDelegate>) delegate
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		_delegate = delegate;
	}
	return self;
}
							
#pragma mark - Split view


- (BOOL)splitViewController: (UISplitViewController*)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation  __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_5_0);
{
//	return self.navigationController.topViewController.wantsFullScreenLayout; //[UIApplication sharedApplication].statusBarStyle == UIStatusBarStyleLightContent;
	return NO;
}


- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
	barButtonItem.title = NSLocalizedString(@"Tag List", @"Tag List");
	[self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
	self.masterPopoverController = popoverController;
//	popoverController.popoverContentSize = viewController.contentSizeForViewInPopover;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
	// Called when the view is shown again in the split view, invalidating the button and popover controller.
	[self.navigationItem setLeftBarButtonItem:nil animated:YES];
	self.masterPopoverController = nil;
}

- (IBAction)hideKeyboard{
	[[self view]endEditing:YES];
}
@end
