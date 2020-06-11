//
//  TodayViewController.m
//  TempRH
//
//  Created by cao on 10/29/15.
//
//

#import "TodayViewController.h"
#import "Tag.h"

@interface UIColor (WhiteAlpha)
+ (UIColor *)colorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue whiteAlpha:(CGFloat)alpha;
@end
@implementation UIColor(WhiteAlpha)

+ (UIColor *)colorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue whiteAlpha:(CGFloat)alpha{
	return [UIColor colorWithRed:1.0-((1.0-red)*alpha) green:1.0-((1.0-green)*alpha) blue:1.0-((1.0-blue)*alpha) alpha:1.0];
}
@end
@interface UILabel(EllipsisFix)
-(void)setTextColorFixed:(NSString *)text;
@end
@implementation UILabel(EllipsisFix)
-(void)setTextColorFixed:(NSString *)text{
	self.attributedText = [[NSAttributedString alloc] initWithString:text attributes:@{ NSForegroundColorAttributeName : self.textColor }];
}
@end

@interface TodayViewController () <NCWidgetProviding>
{
	NSMutableArray* _tagList;
	BOOL _useDegF;
	AsyncSoapURLConnection* comet;
	CGSize lastContentSize;
	BOOL loadingFromWeb;
}
@end

@implementation TodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	self.updateCallback=nil;
	maxFreqOffset=10000000;
	self.currentAuxMode = [[[NSUserDefaults standardUserDefaults] objectForKey:@"AuxMode"] intValue];
	loadingFromWeb=NO;
	self.configBtn = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
	_configBtn.textLabel.textColor=[UIColor darkGrayColor];
	_configBtn.textLabel.font =[UIFont systemFontOfSize:13.0];
	_configBtn.textLabel.textAlignment=NSTextAlignmentCenter;
	_configBtn.textLabel.text=NSLocalizedString(@"Choose which tags to display...",nil);
	
	if([self.extensionContext respondsToSelector:@selector(setWidgetLargestAvailableDisplayMode:)])
		[self.extensionContext setWidgetLargestAvailableDisplayMode:NCWidgetDisplayModeExpanded];
	
    // Do any additional setup after loading the view from its nib.
}

-(void)getNextUpdate{
	if(comet!=nil){
		[comet cancel]; comet=nil;
	}
	NSString* url, *soapAction, *xml;
	url=@"ethComet.asmx?op=GetNextUpdateWidget";
	soapAction = @"http://mytaglist.com/ethComet/GetNextUpdateWidget" ;
	xml = @"<?xml version=\"1.0\" encoding=\"utf-8\"?><soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\"><soap:Body><GetNextUpdateWidget xmlns=\"http://mytaglist.com/ethComet\" /></soap:Body></soap:Envelope>";

	comet = [AsyncSoapURLConnection soapRequest: [WSROOT stringByAppendingString: url]
									  soapAction: soapAction
											 xml: xml
								   completeBlock:^(id retval){
									   NSLog(@"GetNextUpdateWidget returns");
									   for(NSMutableDictionary* tag in (NSArray*)retval){
										   for(int i=0;i<_tagList.count;i++){
											   NSDictionary* oldTag = [_tagList objectAtIndex:i];
											   if([[oldTag uuid] isEqualToString: [tag uuid]]){
												   [_tagList replaceObjectAtIndex:i withObject:tag];
												   [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
											   }
										   }
									   }
									   [self getNextUpdate];
								   }errorBlock:^(NSError* e, id* showFrom){
									   NSLog([e description]);
									   comet=nil;

									   [NSTimer scheduledTimerWithTimeInterval:1.0 block:^{
										   [self getNextUpdate];
									   } repeats:NO];

									   return NO;
								   }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets{
	return UIEdgeInsetsMake(0, 10, -2, 0); //UIEdgeInsetsZero;
}
//-(void)viewDidAppear:(BOOL)animated{
//	[self widgetPerformUpdateWithCompletionHandler:nil];
//	[super viewDidAppear:animated];
//}
-(void)viewWillAppear:(BOOL)animated{
	[self widgetPerformUpdateWithCompletionHandler:nil];
	[super viewWillAppear:animated];
}

- (void)widgetActiveDisplayModeDidChange:(NCWidgetDisplayMode)activeDisplayMode withMaximumSize:(CGSize)maxSize{
	if (activeDisplayMode == NCWidgetDisplayModeCompact) {
		self.preferredContentSize = maxSize;
	}
	else
		self.preferredContentSize = self.tableView.contentSize; // CGSizeMake(0, 400);
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
	if(completionHandler!=nil)
		self.updateCallback=completionHandler;
	
	if(loadingFromWeb)return;
	
	loadingFromWeb=YES;
	
	WSROOT= [[NSUserDefaults standardUserDefaults] stringForKey:WsRootPrefKey];
	if(WSROOT==nil)WSROOT=@"https://www.mytaglist.com/";
	
	_useDegF = [[[[NSUserDefaults alloc]initWithSuiteName:TagListGroupName] objectForKey:UseDegFPrefKey]boolValue];
	
	[AsyncURLConnection request:[WSROOT stringByAppendingString:
								 @"ethClient.asmx/GetTagListWidget"]
					 jsonString:nil completeBlock:^(NSDictionary* retval){
						 _tagList = [retval objectForKey:@"d"];
						 
						 if(_tagList){
							 [[self tableView] reloadData];
							 if(lastContentSize.height != self.tableView.contentSize.height)
								 [self setPreferredContentSize:lastContentSize = self.tableView.contentSize];
					
						 }
						 loadingFromWeb=NO;
						 if(self.updateCallback)
							 self.updateCallback(_tagList.count>0?NCUpdateResultNewData:NCUpdateResultNoData);
						 self.updateCallback=nil;
						 
						 [self getNextUpdate];			// restart getting comet using the new mac (all).

						 if(self.updateTimer==nil)
							 self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 block:^()
											 {
												 [self.tableView reloadData];
											 } repeats:YES];

					 }errorBlock:^(NSError* err, id* showFrom){
						 loadingFromWeb=NO;
						 if(self.updateCallback)
							 self.updateCallback(NCUpdateResultFailed);
						 self.updateCallback=nil;
						 
						 return NO;
					 } setMac:nil];

    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData
}

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if(section==0)
		return [_tagList count];
	else return 1;
}
-(void)tagAuxTapped:(id)sender{
	_currentAuxMode=(_currentAuxMode+1)%3;
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:_currentAuxMode] forKey:@"AuxMode"];
	
	for (NSIndexPath *path in [self.tableView indexPathsForVisibleRows]) {
		if(path.section==0)
		[((WidgetCell*)[self.tableView cellForRowAtIndexPath:path]) setData:[_tagList objectAtIndex:[path row]] forMode:_currentAuxMode];
	}
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section==1)return _configBtn;
	
	WidgetCell *cell = (WidgetCell *)[tableView
												  dequeueReusableCellWithIdentifier:@"WidgetCell"];
	
	if (!cell) {
		cell = [[WidgetCell alloc] init];
		[cell.tagAux addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tagAuxTapped:)]];
	}
	cell.useDegF = _useDegF;
	
	[cell setData:[_tagList objectAtIndex:[indexPath row]] forMode:self.currentAuxMode];
	
	return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if(indexPath.section==1)
		[self.extensionContext openURL:[NSURL URLWithString:@"wtg://widgetConfig/"] completionHandler:nil];
	else{
		NSDictionary *tag;
		tag = [_tagList objectAtIndex:[indexPath row]];
		
		[self.extensionContext openURL:[NSURL URLWithString:[@"wtg://detail/" stringByAppendingString:tag.uuid]] completionHandler:nil];
	}
}


@end

@implementation WidgetCell
@synthesize tagAux=_tagAux;

- (id)init
{
	self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"WidgetCell"];
	
	if (self) {
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		
		self.accessoryView = self.tagAux = [[UILabel alloc]init];
		_tagAux.layer.masksToBounds=YES;
		_tagAux.layer.cornerRadius=4;
		_tagAux.userInteractionEnabled=YES;
		_tagAux.textAlignment = NSTextAlignmentCenter;
		
		self.detailTextLabel.textAlignment =NSTextAlignmentRight;
		
		BOOL isOS10 = ([[UIDevice currentDevice].systemVersion floatValue] >= 10);
		
		self.detailTextLabel.textColor = self.textLabel.textColor = isOS10?[UIColor blackColor] : [UIColor whiteColor];
		  //isOS10?[UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1.0]: [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
	
		self.textLabel.font = [UIFont systemFontOfSize:15.0];
		self.detailTextLabel.font = [UIFont systemFontOfSize:15.0];
		
	}
	return self;
}
+(UIColor*)fgColorForSwatch:(NSString*)color andAlpha:(float)alpha{
	static NSDictionary* colors;
	if(!colors){
		colors = @{
				   @"a":[UIColor colorWithRed:1 green:1 blue:1 whiteAlpha:alpha],
				   @"b":[UIColor colorWithRed:1 green:1 blue:1 whiteAlpha:alpha],
				   @"c":[UIColor colorWithRed:0 green:0 blue:0 whiteAlpha:alpha],
				   @"d":[UIColor colorWithRed:0 green:0 blue:0 whiteAlpha:alpha],
				   @"e":[UIColor colorWithRed:0 green:0 blue:0 whiteAlpha:alpha],
				   @"f":[UIColor colorWithRed:1 green:1 blue:1 whiteAlpha:alpha],
				   @"p":[UIColor colorWithRed:1 green:1 blue:1 whiteAlpha:alpha],
				   @"r":[UIColor colorWithRed:1 green:1 blue:1 whiteAlpha:alpha],
				   @"t":[UIColor colorWithRed:1 green:1 blue:1 whiteAlpha:alpha]
				   };
	}
	return [[colors objectForKey:color] colorWithAlphaComponent:alpha];
}

+(UIColor*)bgColorForSwatch:(NSString*)color andAlpha:(float)alpha{
	static NSDictionary* colors;
	if(!colors){
		colors = @{
				   @"a":[UIColor colorWithRed:(float)0x55/(float)0xff green:(float)0x55/(float)0xff blue:(float)0x55/(float)0xff whiteAlpha:alpha],
				   @"b":[UIColor colorWithRed:(float)0x5f/(float)0xff green:(float)0x9c/(float)0xff blue:(float)0xc5/(float)0xff whiteAlpha:alpha],
				   @"c":[UIColor colorWithRed:(float)0xfd/(float)0xff green:(float)0xfd/(float)0xff blue:(float)0xfd/(float)0xff whiteAlpha:alpha],
				   @"d":[UIColor colorWithRed:1 green:1 blue:1 whiteAlpha:alpha],
				   @"e":[UIColor colorWithRed:(float)0xfc/(float)0xff green:(float)0xed/(float)0xff blue:(float)0xa7/(float)0xff whiteAlpha:alpha],
				   @"f":[UIColor colorWithRed:(float)0x6a/(float)0xff green:(float)0xba/(float)0xff blue:(float)0x2f/(float)0xff whiteAlpha:alpha],
				   @"p":[UIColor colorWithRed:(float)0xff/(float)0xff green:(float)0x6b/(float)0xff blue:(float)0x5f/(float)0xff whiteAlpha:alpha],
				   @"r":[UIColor colorWithRed:(float)0xc2/(float)0xff green:(float)0x2f/(float)0xff blue:(float)0x1b/(float)0xff whiteAlpha:alpha],
				   @"t":[UIColor colorWithRed:(float)0x33/(float)0xff green:(float)0xcc/(float)0xff blue:(float)0xff/(float)0xff whiteAlpha:alpha]
				   };
	}
	return [[colors objectForKey:color] colorWithAlphaComponent:alpha] ;
}
-(void)setGradient:(NSDictionary*) tag
{
	
	float alpha=tag.OutOfRange ? 0.7 : 0.9;
	float fgAlpha=tag.OutOfRange? 0.7: 0.9;
	
	if(tag.isWeMo){
		if(tag.lit){
			self.tagAux.backgroundColor=  [WidgetCell bgColorForSwatch:@"f" andAlpha:alpha];
			self.tagAux.textColor = [WidgetCell fgColorForSwatch:@"f" andAlpha:fgAlpha];
		}else{
			self.tagAux.backgroundColor= [WidgetCell bgColorForSwatch:@"c" andAlpha:alpha];
			self.tagAux.textColor = [WidgetCell fgColorForSwatch:@"c" andAlpha:fgAlpha];
		}
	}else if(tag.isCam){
		if(tag.lit){
			self.tagAux.backgroundColor= [WidgetCell bgColorForSwatch:@"t" andAlpha:alpha];
			self.tagAux.textColor = [WidgetCell fgColorForSwatch:@"t" andAlpha:fgAlpha];
		}else{
			self.tagAux.backgroundColor= [WidgetCell bgColorForSwatch:@"c" andAlpha:alpha];
			self.tagAux.textColor = [WidgetCell fgColorForSwatch:@"c" andAlpha:fgAlpha];
		}
		
	}else{
		switch (tag.eventState) {
			case Armed:
			case TimedOut:
			case Closed:
				self.tagAux.backgroundColor= [WidgetCell bgColorForSwatch:@"a" andAlpha:alpha];
				self.tagAux.textColor = [WidgetCell fgColorForSwatch:@"a" andAlpha:fgAlpha];
				break;
			case Disarmed:
				self.tagAux.backgroundColor=[WidgetCell bgColorForSwatch:@"c" andAlpha:alpha];
				self.tagAux.textColor = [WidgetCell fgColorForSwatch:@"c" andAlpha:fgAlpha];
				break;
			case Moved:
			case Opened:
				self.tagAux.backgroundColor=[WidgetCell bgColorForSwatch:@"e" andAlpha:alpha];
				self.tagAux.textColor = [WidgetCell fgColorForSwatch:@"e" andAlpha:fgAlpha];
				break;
			default:
				self.tagAux.backgroundColor= [UIColor clearColor];
				self.tagAux.textColor = [UIColor blackColor];
				break;
		}
		switch (tag.capEventState) {
			case TooDry:
				self.tagAux.backgroundColor=[WidgetCell bgColorForSwatch:@"r" andAlpha:alpha];
				self.tagAux.textColor = [WidgetCell fgColorForSwatch:@"r" andAlpha:fgAlpha];
				break;
			case TooWet:
				self.tagAux.backgroundColor=[WidgetCell bgColorForSwatch:@"f" andAlpha:alpha];
				self.tagAux.textColor = [WidgetCell fgColorForSwatch:@"f" andAlpha:fgAlpha];
			default:
				break;
		}
		
		if(tag.isNest){
			if(tag.thermostat.turnOff){
				self.tagAux.backgroundColor= [WidgetCell bgColorForSwatch:@"a" andAlpha:alpha];
				self.tagAux.textColor = [WidgetCell fgColorForSwatch:@"a" andAlpha:fgAlpha];
			}else{
				self.tagAux.backgroundColor= [WidgetCell bgColorForSwatch:@"t" andAlpha:alpha];
				self.tagAux.textColor = [WidgetCell fgColorForSwatch:@"t" andAlpha:fgAlpha];
			}
		}
		
		switch(tag.tempEventState){
			case TooLow:
				self.tagAux.backgroundColor=[WidgetCell bgColorForSwatch:@"b" andAlpha:alpha];
				self.tagAux.textColor = [WidgetCell fgColorForSwatch:@"b" andAlpha:fgAlpha];
				break;
			case TooHigh:
				self.tagAux.backgroundColor=[WidgetCell bgColorForSwatch:@"p" andAlpha:alpha];
				self.tagAux.textColor = [WidgetCell fgColorForSwatch:@"p" andAlpha:fgAlpha];
				break;
			default:
				break;
		}
	}
	
	self.detailTextLabel.textColor = self.textLabel.textColor;
}

- (void) setData:(NSDictionary*) tag forMode:(WidgetCellAuxMode)mode
{
	[self setGradient:tag];
	
	[[self textLabel] setTextColorFixed:tag.name];
	if(tag.hasTemperatureSensor){
		self.detailTextLabel.text = [NSString stringWithFormat:tag.has13bit?@"%.1f°%@ ":@"%.0f°%@ ",
							 _useDegF?tag.temperatureDegC*9.0/5.0+32.0: tag.temperatureDegC,
							 _useDegF?@"F":@"C"];
		[self.detailTextLabel sizeToFit];
	}
	else{
		self.detailTextLabel.text=@"";
	}

	if(mode==AuxModeEventString){
		self.tagAux.text = tag.eventTypeString;
	}else if(mode==AuxModeHumidity){
		if(tag.cap!=0){
			if(tag.isWeMo){
				self.tagAux.text=[NSString stringWithFormat:@"\ue10f%.0f%% ", tag.cap];
			}else{
				self.tagAux.text=[NSString stringWithFormat:@"\ue331%.0f%% ", tag.cap];
			}
		}else{
			_tagAux.text=@"-";
		}
	}else{
		self.tagAux.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ago",nil), [tag UserFriendlyTimeSpanString:YES]];
	}
	
	[_tagAux sizeToFit];
	CGRect f = _tagAux.frame;
	f.origin.x-=1; f.origin.y-=4;
	f.size.width+=10; f.size.height+=6;
	_tagAux.frame=f;
}



- (void)layoutSubviews
{
	[super layoutSubviews];

//	CGRect tagName =self.textLabel.frame;
	CGRect tagTemp = self.detailTextLabel.frame;
	tagTemp.origin.x -= 15;
	tagTemp.size.width+=10;
	self.detailTextLabel.frame=tagTemp;
}


@end
