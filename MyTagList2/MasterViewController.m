#import "MasterViewController.h"
#import "DetailViewController.h"
#import "Tag.h"
#import "ImageStore.h"
//#import "UIImage+Sprite.h"
#import <QuartzCore/CAAnimation.h>
#import "NSTimer+Blocks.h"
#import "EventsViewController.h"
#import "OptionsViewController.h"

@interface UIColor (WhiteAlpha)
+ (UIColor *)colorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue whiteAlpha:(CGFloat)alpha;
@end
@implementation UIColor(WhiteAlpha)

+ (UIColor *)colorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue whiteAlpha:(CGFloat)alpha{
	return [UIColor colorWithRed:1.0-((1.0-red)*alpha) green:1.0-((1.0-green)*alpha) blue:1.0-((1.0-blue)*alpha) alpha:1.0];
}

@end
@implementation TagTableViewCell
@synthesize useDegF=_useDegF, tempDegView=_tempDegView;
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
	if(_tag!=nil){
		if(highlighted){
			[UIView animateWithDuration:0.2f
							 animations:^{
								 self.transform = CGAffineTransformMakeScale(0.95f, 0.95f);
							 }
							 completion:^(BOOL finished) {
							 }];
		}else{
			[UIView animateWithDuration:0.1f
							 animations:^{
								 self.transform = CGAffineTransformIdentity;
							 }
							 completion:^(BOOL finished) {
							 }
			 ];
		}
	}
	[super setHighlighted:highlighted animated:animated];
}
- (void)layoutSubviews
{
	
//	CGRect trueBound = self.bounds;
	[super layoutSubviews];
	
//	self.imageView.frame = CGRectMake( 1, 0, THUMB_WIDTH, THUMB_HEIGHT);
	
	CGRect r;
	
	
	CGRect frame=self.textLabel.frame;
	r = self.detailTextLabel.frame;
/*	if(self.accessoryView!=_tempDegView){
		frame.size.width = self.frame.size.width-frame.origin.x-75; //self.frame.size.width-115-60;
		r.size.width+=20;
	}else{
		//frame.size.width = self.frame.size.width-frame.origin.x-80;
		frame.size.width = self.frame.size.width-frame.origin.x-_tempDegView.text.length*20;
		r.size.width+=75;
	}*/
	frame.size.width = self.frame.size.width-frame.origin.x-_tempDegView.text.length*9-30;
	r.size.width+=75;

	self.textLabel.frame = frame;
	self.detailTextLabel.frame =r;
//	self.textLabel.font = [UIFont boldSystemFontOfSize:15.5];
//	self.detailTextLabel.font = [UIFont systemFontOfSize:13.0];
	
	//self.backgroundView.frame = self.bounds;
	gradient.frame = self.bounds; //CGRectInset(self.bounds, 1, 1);
	
	//self.accessoryView.backgroundColor = [UIColor redColor];
	if(self.accessoryView!=_tempDegView){
		UIImageView* signalBars =(UIImageView*)self.accessoryView;
		//r = signalBars.frame;
		CGPoint sbCenter = signalBars.center;
		sbCenter.y =self.textLabel.center.y;
		sbCenter.x += 4;
		signalBars.center = sbCenter;
		//r=signalBars.frame;
		sbCenter.x-= (signalBars.frame.size.width/2 + _tempDegView.frame.size.width/2 + 2);
		
		_tempDegView.hidden=self.editing;
		if(!self.editing)
			_tempDegView.center = sbCenter;
	}else{
		CGPoint accessoryViewCenter = _tempDegView.center;
		accessoryViewCenter.y-=5;
		accessoryViewCenter.x+=8;
		_tempDegView.center = accessoryViewCenter;
	}
}

+(UIColor*)fgColorForSwatch:(NSString*)color andAlpha:(float)alpha{
	if(color==nil)return [UIColor blackColor];
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
		[colors retain];
	}
	return [[colors objectForKey:color] colorWithAlphaComponent:alpha];
}

+(UIColor*)bgColorForSwatch:(NSString*)color andAlpha:(float)alpha{
	if(color==nil)return [UIColor clearColor];
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
		[colors retain];
	}
	return [[colors objectForKey:color] colorWithAlphaComponent:alpha] ;
}
-(void)setGradient:(NSDictionary*) tag animated:(BOOL)animated
{    
	
	float alpha=tag.OutOfRange ? 0.7 : 1.0;
	float fgAlpha=tag.OutOfRange? 0.7: 1.0;
	UIColor* color=nil, *fgColor; //=[UIColor blackColor];
	
	
	if(tag.isWeMo){
		if(tag.lit){
			color = [TagTableViewCell bgColorForSwatch:@"f" andAlpha:alpha];
			fgColor = [TagTableViewCell fgColorForSwatch:@"f" andAlpha:fgAlpha];
		}else{
			color = [TagTableViewCell bgColorForSwatch:@"c" andAlpha:alpha];
			fgColor= [TagTableViewCell fgColorForSwatch:@"c" andAlpha:fgAlpha];
		}
	}else if(tag.isCam){
		if(tag.lit){
			color = [TagTableViewCell bgColorForSwatch:@"t" andAlpha:alpha];
			fgColor = [TagTableViewCell fgColorForSwatch:@"t" andAlpha:fgAlpha];
		}else{
			color = [TagTableViewCell bgColorForSwatch:@"c" andAlpha:alpha];
			fgColor = [TagTableViewCell fgColorForSwatch:@"c" andAlpha:fgAlpha];
		}
		
	}/*else if(tag.needFreqCal){
		color = [TagTableViewCell bgColorForSwatch:@"e" andAlpha:alpha];
		self.textLabel.textColor = [TagTableViewCell fgColorForSwatch:@"e" andAlpha:fgAlpha];
	}*/
	else if(tag.isNest){
		if(tag.thermostat.turnOff){
			color = [TagTableViewCell bgColorForSwatch:@"a" andAlpha:alpha];
			fgColor = [TagTableViewCell fgColorForSwatch:@"a" andAlpha:fgAlpha];
		}else{
			NSString* swatch = tag.tempEventStateSwatch;
			if(swatch==nil)swatch=@"t";
			color = [TagTableViewCell bgColorForSwatch:swatch andAlpha:alpha];
			fgColor = [TagTableViewCell fgColorForSwatch:swatch andAlpha:fgAlpha];
		}
	}
	else
	{
		
		NSString* swatch=nil;
		if(tag.hasALS){
			swatch = tag.lightEventStateSwatch;
		}
		if(swatch==nil)swatch = tag.tempEventStateSwatch;
		if(swatch==nil)swatch=tag.capEventStateSwatch;
		if(swatch==nil)swatch=tag.eventStateSwatch;
		
		color = [TagTableViewCell bgColorForSwatch:swatch andAlpha:alpha];
		fgColor = [TagTableViewCell fgColorForSwatch:swatch andAlpha:fgAlpha];
	}

	//self.textLabel.backgroundColor=self.backgroundColor = color;
	

	if(animated){
		[CATransaction begin];
		[CATransaction setAnimationDuration:1.4f];
	}

/*
	CGFloat hue, sat, brightness, a;
	[color getHue:&hue saturation:&sat brightness:&brightness alpha:&a];

	gradient.colors = @[(id)[[UIColor colorWithHue:hue saturation:sat brightness:brightness*0.9f alpha:alpha] CGColor],
						(id)[[UIColor colorWithHue:hue saturation:sat brightness:brightness*1.15f alpha:alpha] CGColor],
						(id)[[UIColor colorWithHue:hue saturation:sat brightness:brightness*1.6f alpha:alpha] CGColor],
						(id)[UIColor whiteColor].CGColor]; */
	gradient.backgroundColor = [color CGColor];

	UIColor *tagNameColor = tag.batteryVolt<=tag.LBTh ? [UIColor redColor]: fgColor;
	
	
	if(animated){
/*		[UIView transitionWithView:self.textLabel duration:2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
			self.textLabel.textColor = fgColor;
		} completion:nil];
		
		
		[UIView transitionWithView:self.detailTextLabel duration:2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
			self.detailTextLabel.textColor = fgColor;
		} completion:nil];
*/
		self.textLabel.textColor = tagNameColor;
		self.detailTextLabel.textColor = fgColor;
		[CATransaction commit];
	}else{
		self.textLabel.textColor = tagNameColor;
		self.detailTextLabel.textColor = fgColor;
	}
/*	CATransition *animation = [CATransition animation];
	[animation setType:kCATransitionFade];
	[[self layer] addAnimation:animation forKey:nil];
*/
}
-(void)initShared{
	_tempDegView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 48, 48)];
	_tempDegView.backgroundColor = [UIColor clearColor];
	_tempDegView.textAlignment = NSTextAlignmentRight;
	
	//UIView *bgview = [[[UIView alloc] initWithFrame:self.bounds] autorelease];
	
	gradient = [CALayer layer];
	
	//gradient = [CAGradientLayer layer];
	//gradient.startPoint=CGPointMake(1.0f, 1.0f);
	//gradient.endPoint=CGPointMake(0.0f, 1.0f);

	[self.layer insertSublayer:gradient atIndex:0];

	//self.backgroundView=bgview;
	//self.textLabel.backgroundColor=[UIColor clearColor];
	//self.detailTextLabel.backgroundColor=[UIColor clearColor];
	
	self.imageView.contentMode = UIViewContentModeScaleAspectFit; //UIViewContentModeCenter;

	/*
	UITapGestureRecognizer *gestureRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewTapped)] autorelease];
	[self.imageView addGestureRecognizer:gestureRecognizer];
	[self.imageView setUserInteractionEnabled:YES];
	*/

	UITapGestureRecognizer *gestureRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tempDegViewTapped)] autorelease];
	[self.tempDegView addGestureRecognizer:gestureRecognizer];
	[self.tempDegView setUserInteractionEnabled:YES];

	self.textLabel.font = [UIFont boldSystemFontOfSize:15.5];
	self.detailTextLabel.font = [UIFont systemFontOfSize:13.0];
}
-(IBAction)tempDegViewTapped{
	self.mvc.currentDisplayMode = (self.mvc.currentDisplayMode+1)%(self.mvc.anyLightSensor?4:3);
}

-(id)initForShotEntryWithID:(NSString*)ID{
	self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ID];
	if(self){
		signalBarsImages=nil;
		[self initShared];
		//_tempDegView.font = [UIFont boldSystemFontOfSize:12];
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		self.selectionStyle = UITableViewCellSelectionStyleGray;
		self.imageView.contentMode = UIViewContentModeScaleAspectFit;
	}
	return self;
}

-(id)initForEventEntryWithID:(NSString*)ID{
	self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ID];
	if(self){
		signalBarsImages=nil;
		[self initShared];
		//_tempDegView.font = [UIFont boldSystemFontOfSize:12];
		self.accessoryView = _tempDegView;
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		self.imageView.contentMode = UIViewContentModeScaleAspectFit;
	}
	return self;
}
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
		signalBarsImages = @[[UIImage imageNamed:@"signal0.png"], [UIImage imageNamed:@"signal1.png"],[UIImage imageNamed:@"signal2.png"],
							 [UIImage imageNamed:@"signal3.png"],[UIImage imageNamed:@"signal4.png"],[UIImage imageNamed:@"signal5.png"]];
		[signalBarsImages retain];
		//[[[UIImage imageNamed:@"signalbars.png"] spritesWithSpriteSkipX: NO] retain];
		self.accessoryView = [[[UIImageView alloc] init] autorelease];
		
		[self initShared];
		_tempDegView.font = [UIFont boldSystemFontOfSize:14];
		[self addSubview:_tempDegView];
	}
	return self;
}

-(void)dealloc{
	[signalBarsImages release]; signalBarsImages=nil;
	self.tempDegView=nil;
	[super dealloc];
}
+(int) dBmToBars:(float)dBm {
	if (dBm <= -115) return 0;
	else if (dBm < -90) return 1;
	else if (dBm < -83) return 2;
	else if (dBm < -76) return 3;
	else if (dBm < -69) return 4;
	else return 5;
}
/*static NSString* timeFromString(NSDate* date){
	static NSDateFormatter *dateFormatter;
	if (!dateFormatter) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"hh:mm:ss a"];
	}
	return [dateFormatter stringFromDate:date];
}*/

+(NSMutableDictionary*)shotsCache
{
	static dispatch_once_t pred;
	static NSMutableDictionary *sharedInstance = nil;
	dispatch_once(&pred, ^{
		sharedInstance = [[NSMutableDictionary alloc] init];
	});
	return sharedInstance;
}

-(void)setShotEntry:(NSString*) entry forTag:(NSMutableDictionary*)tag{
	self.textLabel.text =  [NSDateFormatter localizedStringFromDate:[entry nsdate] dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterLongStyle]; //timeFromString([entry nsdate]);
	UIImage* image = [[TagTableViewCell shotsCache] objectForKey:entry];
	if(image!=nil)
		[self imageView].image = image;
	else{
		[WebImageOperations processImageDataWithURLString:[NSString stringWithFormat:@"%@webcams/%@/%@s.jpg",WSROOT,
														   tag.uuid, entry]
												 andBlock:^(NSData *d) {
													 
													 UIImage* image = [[[UIImage alloc]initWithData:d] autorelease];
													 if(image!=nil){
														 self.imageView.image= image;
														 [self setNeedsLayout];
														 [[TagTableViewCell shotsCache] setObject:image forKey:entry];
													 }
												 }];
	}
}
-(void)setEventEntry:(NSDictionary*) entry{
	self.textLabel.text = [entry objectForKey:@"tagName"];
	self.detailTextLabel.text = [entry objectForKey:@"eventText"];
	long duration = [[entry objectForKey:@"durationSec"] longValue];
	if(duration>0){
		NSString* durationStr = @"";
		int days = floorf(duration / 60 / 60 / 24);
		if (days >= 1) {
			durationStr = [durationStr stringByAppendingFormat:NSLocalizedString(@"%d days ",nil), days];
			duration-=days*60*60*24;
		}
		int hours = floorf(duration / 60 / 60);
		if (hours >= 1) {
			durationStr = [durationStr stringByAppendingFormat:NSLocalizedString(@"%d hours ",nil), hours];
			duration-=hours*60*60;
		}
		int minutes = floorf(duration / 60);
		if (minutes >= 1) {
			durationStr = [durationStr stringByAppendingFormat:NSLocalizedString(@"%d minutes ",nil), minutes];
			duration-=minutes*60;
		}
		durationStr = [durationStr stringByAppendingFormat:NSLocalizedString(@"%ld seconds ",nil), duration];
		self.detailTextLabel.text = [self.detailTextLabel.text stringByAppendingFormat:NSLocalizedString(@"(duration: %@)",nil), durationStr ];
	}

	NSString* picture = [entry objectForKey:@"picture"];
	NSRange dot = [picture rangeOfString:@"."];
	
	if([[picture substringFromIndex:dot.location] isEqualToString:@".jpg"])
		[self imageView].image =
		[[ImageStore defaultImageStore] thumbnailForKey:[picture substringToIndex:dot.location] placeHolderNamed:nil loadFromFile:YES] ;
	else
		[self imageView].image = [ImageStore placeholderImageNamed:picture];
	
	NSString* swatch = [entry objectForKey:@"color"];
	self.backgroundColor =[TagTableViewCell bgColorForSwatch:swatch andAlpha:0.6];
	self.detailTextLabel.textColor = _tempDegView.textColor = self.textLabel.textColor = [TagTableViewCell fgColorForSwatch:swatch andAlpha:0.85];
	
	_tempDegView.text = [NSDateFormatter localizedStringFromDate:[entry objectForKey:@"nsdate"] dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
	[_tempDegView sizeToFit];
}
- (void) setData:(NSMutableDictionary*) tag loadImage: (BOOL)loadImage animated:(BOOL)animated
{
	_tag= tag;
	[self setGradient:tag animated:animated];

	if(tag.disabled){
		[[self textLabel] setTextColorFixed:tag.name];
		self.alpha=0.43;
		self.userInteractionEnabled=NO;		
	}else{
		//NSString *detail = tag.eventTypeString;
		[[self textLabel] setTextColorFixed:tag.name];
		self.alpha=1;
		self.userInteractionEnabled=YES;

		NSString* tempData = [NSString stringWithFormat:tag.hasHighResTemp?@"%.1f°%@ ":@"%.0f°%@ ",
							  _useDegF?tag.temperatureDegC*9.0/5.0+32.0: tag.temperatureDegC,
							  _useDegF?@"F":@"C"];
		NSString* luxData;
		if(tag.hasALS){
			luxData=[NSString stringWithFormat:tag.lux>100?@"%.0f lx ":@"%.1f lx ", tag.lux];
		}else
			luxData=nil;
		
		NSString* updatedAgoData = tag.lastComm==0? NSLocalizedString(@"(Never)",nil) : [NSString stringWithFormat:NSLocalizedString(@"%@ ago",nil), [tag UserFriendlyTimeSpanString:YES]];
		
		NSString* capData;
		if(tag.hasCap){
			if(dewPointMode && tag.has13bit && !tag.hasProtimeter){
				float dp = dewPoint(tag.cap, tag.temperatureDegC);
				capData = [NSString stringWithFormat:@"💦%.0f°%@",_useDegF?dp*9.0/5.0+32.0: dp,_useDegF?@"F":@"C"];
			}else
				capData=[NSString stringWithFormat:@"💦%.0f%% ", tag.cap];
		}else if(tag.isWeMo){
			capData = [NSString stringWithFormat:@"💡%.0f%% ", tag.cap];
		}else if(tag.hasThermocouple && !tag.shorted){
			capData = [NSString stringWithFormat:@"%.1f°%@ (Ambient)",	 _useDegF?tag.cap*9.0/5.0+32.0: tag.cap,	 _useDegF?@"F":@"C"];
		}else
			capData=nil;
		
/*		if(tag.hasALS){
			detail=[detail stringByAppendingFormat:tag.has13bit?@" 🌡%.1f°%@ ":@" 🌡%.0f°%@ ",
					_useDegF?tag.temperatureDegC*9.0/5.0+32.0: tag.temperatureDegC,
					_useDegF?@"F":@"C"];
			
		}
		
		if(tag.cap!=0){
			if(tag.isWeMo){
				detail=[detail stringByAppendingFormat:@" \ue10f%.0f%% ", tag.cap];
			}else if(tag.hasCap){				
				if(dewPointMode && tag.has13bit){
					float dp = dewPoint(tag.cap, tag.temperatureDegC);
					detail = [detail stringByAppendingFormat:@" \ue331%.0f°%@",_useDegF?dp*9.0/5.0+32.0: dp,_useDegF?@"F":@"C"];
				}else
					detail=[detail stringByAppendingFormat:@" \ue331%.0f%% ", tag.cap];
			}
		}

		detail =  tag.lastComm==0? @"(Never updated)" : [detail stringByAppendingFormat:@" \ue213%@ ago", [tag UserFriendlyTimeSpanString:YES]];
		*/
		
		/*
		if(tag.signaldBm>-110 && !tag.OutOfRange){
			detail = [detail stringByAppendingFormat:@" \ue213%@ ago \ue20b%.0fdBm",
					  [tag UserFriendlyTimeSpanString:YES],tag.signaldBm ];
			
			if(tag.mirrors.count>0){
				detail=[detail stringByAppendingFormat:@"@%@", tag.managerName];
			}
		}
		else
			detail = [detail stringByAppendingFormat:@" \ue213%@ ago \ue20bNo signal",
										   [tag UserFriendlyTimeSpanString:YES]];
		*/
		TagCellDisplayMode displayMode = (self.mvc.currentDisplayMode==DisplayModeLux && luxData==nil? DisplayModeTemperature: self.mvc.currentDisplayMode);
		if(displayMode==DisplayModeTemperature){
			_tempDegView.text = tempData;
			if(tag.isWeMo)
				self.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@ 🆙 %@", tag.eventTypeString, capData, updatedAgoData];
			else if(luxData)
				self.detailTextLabel.text = [NSString stringWithFormat:@"%@ ☀️%@ %@ 🆙 %@", tag.eventTypeString, luxData, capData, updatedAgoData];
			else if(capData)
				self.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@ 🆙 %@", tag.eventTypeString, capData, updatedAgoData];
			else
				self.detailTextLabel.text = [NSString stringWithFormat:@"%@ 🆙 %@", tag.eventTypeString, updatedAgoData];
		}
		else if(displayMode ==DisplayModeHumidity){
			_tempDegView.text = capData;
			if(tag.hasTemperatureSensor){
				if(luxData){
					self.detailTextLabel.text = [NSString stringWithFormat:@"%@ ☀️%@ 🌡%@ 🆙 %@", tag.eventTypeString, luxData, tempData, updatedAgoData];
				}else{
					self.detailTextLabel.text = [NSString stringWithFormat:@"%@ 🌡%@ 🆙 %@", tag.eventTypeString, tempData, updatedAgoData];
				}
			}else{
				self.detailTextLabel.text = [NSString stringWithFormat:@"%@ 🆙 %@", tag.eventTypeString, updatedAgoData];
			}
		}else if(displayMode==DisplayModeUpdatedAgo){
			_tempDegView.text=updatedAgoData;
			if(tag.hasTemperatureSensor){
				if(capData){
					if(luxData){
						self.detailTextLabel.text = [NSString stringWithFormat:@"%@ ☀️%@ 🌡%@ %@", tag.eventTypeString, luxData, tempData, capData];
					}else{
						self.detailTextLabel.text = [NSString stringWithFormat:@"%@ 🌡%@ %@", tag.eventTypeString, tempData, capData];
					}
				}else{
					self.detailTextLabel.text = [NSString stringWithFormat:@"%@ 🌡%@", tag.eventTypeString, tempData];
				}
			}else if(tag.isWeMo){
				self.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", tag.eventTypeString, capData];
			}else{
				self.detailTextLabel.text = tag.eventTypeString;
			}
		}else if(displayMode==DisplayModeLux){
			_tempDegView.text=luxData;
			self.detailTextLabel.text = [NSString stringWithFormat:@"%@ 🌡%@ %@ 🆙 %@", tag.eventTypeString, tempData, capData, updatedAgoData];
		}
		
		[self imageView].image = [[ImageStore defaultImageStore] thumbnailForKey:tag.uuid placeHolderNamed:tag.placeHolderImageName loadFromFile:loadImage];

		if(tag.image_md5.length>0 && ![tag.image_md5 isEqualToString:[[ImageStore defaultImageStore] base64MD5ForKey:tag.uuid]]){

			[[ImageStore defaultImageStore] loadImageFromServerAsyncForKey:tag.uuid placeHolderNamed:tag.placeHolderImageName ToView:self.imageView];
		}
		
		((UIImageView*)self.accessoryView).image = [signalBarsImages objectAtIndex:[TagTableViewCell dBmToBars:tag.signaldBm]];
		[self.accessoryView sizeToFit];

		_tempDegView.textColor=self.detailTextLabel.textColor;
		[_tempDegView sizeToFit];

		//<##>
		/*if(tag.hasALS){
			_tempDegView.text = [NSString stringWithFormat:tag.lux>100?@"%.0f lx ":@"%.1f lx ", tag.lux];
			_tempDegView.textColor=self.textLabel.textColor;
			[_tempDegView sizeToFit];

		}else{
			if(tag.hasTemperatureSensor){
				_tempDegView.text = [NSString stringWithFormat:tag.has13bit?@"%.1f°%@ ":@"%.0f°%@ ",
									 _useDegF?tag.temperatureDegC*9.0/5.0+32.0: tag.temperatureDegC,
									 _useDegF?@"F":@"C"];
				_tempDegView.textColor=self.textLabel.textColor;
				[_tempDegView sizeToFit];
			}
			else{
				_tempDegView.text=@"";
			}
		}*/
		
/*		if(tag.tempEventState==TooHigh)
			tempView.textColor = [UIColor orangeColor];
		else if(tag.tempEventState==TooLow)
			tempView.textColor=[UIColor blueColor];
		else
	*/
		
		
	}
}

@end


@implementation UINavigationController (RotationIn_IOS6)
-(BOOL)shouldAutorotate
{
	return [[self.viewControllers lastObject] shouldAutorotate];
}
-(NSUInteger)supportedInterfaceOrientations
{
	return [[self.viewControllers lastObject] supportedInterfaceOrientations];
}
@end

NSString * const TagDisplayModePrefKey = @"TagDisplayModePrefKey";

@implementation MasterViewController
{
}
@synthesize topPVC;
//@synthesize stopBeepAllBtn = _stopBeepAllBtn;
@synthesize armAllBtn = _armAllBtn, helpBtn = _helpBtn;
@synthesize updateAllBtn = _updateAllBtn;
@synthesize multiStatsBtn  = _multiStatsBtn;
@synthesize wirelessConfigBtn = _wirelessConfigBtn;
//@synthesize associateTagBtn = _associateTagBtn;
@synthesize associateBtnCell = _associateBtnCell;
@synthesize delegate = _delegate;
@synthesize tagList=_tagList;

-(void) setTagList:(NSMutableArray *)tagList{
	[_tagList autorelease];
	_tagList = [tagList retain];
	if(_tagList){
		_anyLightSensor=NO;
		for(NSDictionary* tag in tagList){
			if(tag.hasALS){
				_anyLightSensor=YES; break;
			}
		}
		
		[[self tableView] reloadData];		
		CGSize reqsz =  self.tableView.contentSize;
		self.topPVC.navigationController.preferredContentSize = CGSizeMake(480, reqsz.height>800?800:reqsz.height);
	}

	/*
	if(_tagList.count==0){
		self.searchController.searchBar.hidden=YES;
		[[self tableView] setContentOffset:CGPointMake(0, 48)];
	}
	else{
		self.searchController.searchBar.hidden=NO;
		[[self tableView] setContentOffset:CGPointMake(0, 0)];
	}
	 */
}

-(void) addNewTag:(NSMutableDictionary*)tag{	
//	if(_tagList.count>0){
	self.topPVC.searchController.active=NO;
	
		[self.tableView beginUpdates];
	
	[_tagList insertObject:tag atIndex:0];
//	[self.tableView reloadData];
	
		[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
		[self.tableView endUpdates];
/*	}else{
		[_tagList insertObject:tag atIndex:0];
		[self.tableView reloadData];
	}*/
	//self.searchController.searchBar.hidden=NO;
	[[self tableView] setContentOffset:CGPointMake(0, 0)];
//	[self.tableView reloadData];
}
-(void) deleteTagWithSlaveId:(int)slaveId{
	self.topPVC.searchController.active=NO;

	for(int i=0;i<_tagList.count;i++){
		NSMutableDictionary* tag = [_tagList objectAtIndex:i];
		if(tag.slaveId == slaveId){
			[[ImageStore defaultImageStore] deleteImageForKey:tag.uuid];
			[_tagList removeObjectAtIndex:i];
//			if(_tagList.count>0)
				[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:i inSection:0]]
								  withRowAnimation:UITableViewRowAnimationFade];
/*			else
				[self.tableView reloadData];
*/
			break;
		}
	}
}

-(void) deleteTagWithUuid:(NSString*)uuid{
	self.topPVC.searchController.active=NO;

	for(int i=0;i<_tagList.count;i++){
		NSMutableDictionary* tag = [_tagList objectAtIndex:i];
		if([[tag uuid] isEqualToString: uuid]){
			[[ImageStore defaultImageStore] deleteImageForKey:tag.uuid];
			[_tagList removeObjectAtIndex:i];
//			if(_tagList.count>0)
				[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:i inSection:0]]
														   withRowAnimation:UITableViewRowAnimationFade];
/*			else
				[self.tableView reloadData];
*/
			break;
		}
	}
}
-(NSDictionary*) findTagByUuid:(NSString*) uuid{
	for(int i=0;i<_tagList.count;i++){
		NSDictionary* oldTag = [_tagList objectAtIndex:i];
		if([[oldTag uuid] isEqualToString: uuid]){
			return oldTag;
		}
	}
	return nil;
}
-(int) updateTag:(NSMutableDictionary *)tag inList:(NSMutableArray*)list{
	for(int i=0;i<list.count;i++){
		NSDictionary* oldTag = [list objectAtIndex:i];
		if([[oldTag uuid] isEqualToString: [tag uuid]]){
			
			if(tag.scripts==nil && oldTag.scripts!=nil)
				tag.scripts = oldTag.scripts;
			
			/*if(loadimage){
				if(tag.image_md5!=nil && [tag.image_md5 isEqualToString:oldTag.image_md5])
				{
			 [[ImageStore defaultImageStore] loadImageFromServerAsyncForKey:tag.uuid ToView:self.imageView];
			 
				}
			 }*/
			
			if(oldTag.mirrors != nil && tag.mirrors==nil){
				//	if([oldTag.mac isEqualToString: tag.mac]){
				tag.mirrors = oldTag.mirrors;
				/*	}else{
					// swap manager from mirror back to main
					NSMutableArray* newMirrors = [[oldTag.mirrors mutableCopy] autorelease];
					for(int i=0;i<newMirrors.count;i++)
				 if([((NSDictionary*)[newMirrors objectAtIndex:i]).mac compare: tag.mac]==NSOrderedSame){
				 [newMirrors removeObjectAtIndex:i];
				 break;
				 }
				 
					NSDictionary* mirror = [NSDictionary dictionaryWithObjectsAndKeys:oldTag.mac,@"mac",
				 oldTag.managerName,@"managerName",
				 [oldTag objectForKey:@"alive"],@"alive",
				 [oldTag objectForKey:@"OutOfRange"],@"OutOfRange",
				 oldTag.notificationJS,@"notificationJS",
				 [oldTag objectForKey:@"signaldBm" ],@"signaldBm",
				 [oldTag objectForKey:@"lastComm"],@"lastComm", nil];
					
					[newMirrors addObject:mirror];
					tag.mirrors = newMirrors;
				 }
				 */
			}
			[list replaceObjectAtIndex:i withObject:tag];
			return i;
		}
	}
	return -1;
}
-(void) updateTag:(NSMutableDictionary*)tag loadImage:(BOOL)loadimage{
	
	int i = [self updateTag:tag inList:_tagList];
	int ifiltered = [self updateTag:tag inList:_filteredTagList];
	//int i =[self.topPVC.searchController isActive]?ifiltered:iall;*/
	
	if(i==-1){
		if(tag!=nil && ([tag.mac compare: [tagManagerMacList objectAtIndex:currentTagManagerIndex]]==NSOrderedSame ||
						[[NSUserDefaults standardUserDefaults] boolForKey:TagManagerChooseAllPrefKey])){
			[self addNewTag:[[tag mutableCopy] autorelease]];
		}
	}else{
		int displayed_index = self.topPVC.searchController.active ? ifiltered : i;
		if(displayed_index != -1){
		TagTableViewCell* cell = (TagTableViewCell*)[self.tableView
													 cellForRowAtIndexPath:[NSIndexPath indexPathForRow:displayed_index inSection:0]];
			if(cell){
				//[cell setData:tag loadImage:loadimage animated:YES];  // already done in cellForRowAtIndexPath
				/*if(self.topPVC.searchController.active){
				 [self.tableView reloadData];
				 }else*/
				{
					[self.tableView beginUpdates];
					[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:displayed_index inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
					[self.tableView endUpdates];
				}
			}
		}
	}
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil delegate: (id<MasterViewControllerDelegate>) delegate
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
    if (self) {
		
		//savedSearchTerm=nil;
		_tagList = [[NSMutableArray arrayWithObject:[NSDictionary
						dictionaryWithObjectsAndKeys:NSLocalizedString(@"Loading...",nil) ,@"name", [NSNumber numberWithBool:YES], @"disabled",nil]] retain];

		[self setDelegate:delegate];
				
//		UIBarButtonItem* dropDown = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"downarrow.png"] style:UIBarButtonItemStylePlain target:_delegate action:@selector(tagManagerDropdownPressed:)] autorelease];

		
		UIBarButtonItem *_logoutBtn = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Logout",nil) style:UIBarButtonItemStyleBordered
														 target:_delegate action:@selector(logoutBtnPressed:)] autorelease];
		[self.navigationItem setLeftBarButtonItem:_logoutBtn];
		
		//_associateTagBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:_delegate action:@selector(associateTagBtnPressed:)];
		_associateBtnCell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier:nil];
		_associateBtnCell.accessoryView = [[[UIImageView alloc]initWithImage:[UIImage imageNamed:@"iOS_addbutton"]] autorelease];
//		_associateBtnCell.imageView.image =[UIImage imageNamed:@"iOS_addbutton"];
		_associateBtnCell.textLabel.text=@"Associate New ...";
		_associateBtnCell.textLabel.textAlignment = NSTextAlignmentCenter;
		
		if ([[UIDevice currentDevice].systemVersion floatValue] >= 7){
			self.automaticallyAdjustsScrollViewInsets = true;
			//[self.navigationItem setRightBarButtonItem:_associateTagBtn];
			
		}else{
			searchBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
																	  target:self action:@selector(searchButtonPressed)];
			[self.navigationItem setRightBarButtonItem:searchBtn];
		}
		
		
		if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		    self.clearsSelectionOnViewWillAppear = NO;
		    self.preferredContentSize = CGSizeMake(320.0, 600.0);
		}		
    }
    return self;
}

/*- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return (![[[touch view] class] isSubclassOfClass:[UIControl class]]);
}*/
- (void)navigationBarDoubleTap:(UIGestureRecognizer*)recognizer {
	CGPoint touchPoint = [recognizer locationOfTouch:0 inView:recognizer.view];
	NSLog(@"%f",recognizer.view.frame.size.width);
	if(touchPoint.x > 100 && touchPoint.x < recognizer.view.frame.size.width-100 && touchPoint.y<32){
		if(self.topPVC.isTagManagerChoiceVisible)
//			[_delegate tagManagerDropdownPressed:self.navigationController.navigationBar];
			[_delegate tagManagerDropdownPressed:recognizer.view];
	}
}
/*-(void)showDropdown{
	if(dropDownBtn==nil)
		dropDownBtn = [[[UIBarButtonItem alloc]  initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:_delegate action:@selector(tagManagerDropdownPressed:)] autorelease];
	
	[self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:searchBtn,dropDownBtn,nil]];
}
-(void)hideDropdown{
	[self.navigationItem setRightBarButtonItem:searchBtn];
}
 */

-(void)releaseViews{
//	[dropDownBtn release]; dropDownBtn=nil;
	[searchBtn release]; searchBtn=nil;
	[reorderDoneBtn release]; reorderDoneBtn=nil;
	
	[_filteredTagList release]; _filteredTagList = nil;	
//	[self setStopBeepAllBtn:nil];
	[self setArmAllBtn:nil];
	[self setUpdateAllBtn:nil];
	[self setWirelessConfigBtn:nil];
	[spacerItem release];spacerItem=nil;
	self.staticToolBarItems=nil;
	self.toolbarItems=nil;
}
- (void)dealloc
{	
	[self releaseViews];
//	[self setAssociateTagBtn:nil];

	self.tagList = nil;
	//[savedSearchTerm release];
    [super dealloc];
}
- (void)viewDidUnload {
	[self releaseViews];
	[super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle
-(void)searchButtonPressed{
//	[self.tableView setContentOffset:CGPointMake(0,0) animated:NO];
//	[self.searchDisplayController.searchBar becomeFirstResponder];
//	[self.searchDisplayController setActive:YES];
	[self.topPVC.searchController setActive:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	return  THUMB_HEIGHT;
}

-(void)setToolbarItems:(NSArray *)toolbarItems{
	[self.topPVC setToolbarItems:toolbarItems];
}
-(void)setToolbarItems:(NSArray *)toolbarItems animated:(BOOL)animated{
	[self.topPVC setToolbarItems:toolbarItems animated:animated];
}
-(NSArray*)toolbarItems{
	return [self.topPVC toolbarItems];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	_currentDisplayMode = [[NSUserDefaults standardUserDefaults] integerForKey:TagDisplayModePrefKey];
	
//	self.tableView.separatorColor = [UIColor clearColor];
	self.wantsFullScreenLayout=NO;
	// Do any additional setup after loading the view, typically from a nib.

	self.title = @"Wireless Tags";
		
	// create a filtered list that will contain products for the search results table.
	_filteredTagList = [[NSMutableArray arrayWithCapacity:[_tagList count]] retain];
	
	// restore search settings if they were saved in didReceiveMemoryWarning.
    /*if (savedSearchTerm)
	{
        [self.searchController setActive:searchWasActive];
        [self.searchController.searchBar setSelectedScopeButtonIndex:savedScopeButtonIndex];
        [self.searchController.searchBar setText:savedSearchTerm];
        savedSearchTerm = nil;
	}else{
		self.tableView.contentOffset = CGPointMake(0,  self.searchDisplayController.searchBar.frame.size.height - self.tableView.contentOffset.y);
	}*/

	
//	_stopBeepAllBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"mute.png"] style:UIBarButtonItemStylePlain
//													  target:_delegate action:@selector(stopBeepAllBtnPressed:)];
    _armAllBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"disarm.png"] style:UIBarButtonItemStylePlain
												 target:_delegate action:@selector(armAllBtnPressed:)];
	
	_helpBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"question.png"] style:UIBarButtonItemStylePlain
												 target:_delegate action:@selector(helpBtnPressed:)];
	
    _updateAllBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
																  target:_delegate action:@selector(updateAllBtnPressed:)];
	_multiStatsBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"statistics.png"] style:UIBarButtonItemStylePlain
														 target:_delegate action:@selector(multiStatsBtnPressed:)];
	_wirelessConfigBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"gear.png"] style:UIBarButtonItemStylePlain
														 target:_delegate action:@selector(wirelessConfigBtnPressed:)];

	
    spacerItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
	
	if ([[UIDevice currentDevice].systemVersion floatValue] >= 7){
//		self.staticToolBarItems = [NSArray arrayWithObjects:_stopBeepAllBtn, spacerItem, _armAllBtn, spacerItem, _updateAllBtn, spacerItem, _multiStatsBtn, spacerItem,_wirelessConfigBtn, nil];
		self.staticToolBarItems = [NSArray arrayWithObjects:_multiStatsBtn, spacerItem, _armAllBtn, spacerItem, _updateAllBtn, spacerItem, _wirelessConfigBtn, spacerItem, _helpBtn, nil];
	}else{
//		self.staticToolBarItems = [NSArray arrayWithObjects:_stopBeepAllBtn, spacerItem, _armAllBtn, spacerItem, _updateAllBtn, spacerItem, _multiStatsBtn, spacerItem,_wirelessConfigBtn, spacerItem, _associateTagBtn, nil];
		self.staticToolBarItems = [NSArray arrayWithObjects:_multiStatsBtn, spacerItem, _armAllBtn, spacerItem, _updateAllBtn, spacerItem, _wirelessConfigBtn, nil];
	}
//	self.staticToolBarItems = [NSArray arrayWithObjects:_stopBeepAllBtn, spacerItem, _armAllBtn, spacerItem, _updateAllBtn, spacerItem, _associateTagBtn, nil];
	
	self.toolbarItems=self.staticToolBarItems;
	
	UITapGestureRecognizer* titleTapRecog = [[UITapGestureRecognizer alloc]
										initWithTarget:self action:@selector(navigationBarDoubleTap:)];
	titleTapRecog.cancelsTouchesInView=NO;
	titleTapRecog.delegate = self;
    titleTapRecog.numberOfTapsRequired = 1;

	
	UIView* navTitle=self.topPVC.navigationController.navigationBar;
/*	if ([[UIDevice currentDevice].systemVersion floatValue] >= 7){
		NSArray* svs = self.topPVC.navigationController.navigationBar.subviews;
		for(NSInteger i=0;i<svs.count;i++){
			if([[[svs objectAtIndex:i] description] rangeOfString:@"UINavigationItemView"].length>0){
				navTitle=[svs objectAtIndex:i]; break;
			}
			if([[[svs objectAtIndex:i] description] rangeOfString:@"_UINavigationBarContentView"].length>0){
				navTitle=[svs objectAtIndex:i]; break;
			}
		}
	}else{
		navTitle= [self.topPVC.navigationController.navigationBar.subviews objectAtIndex:1];
	}*/
	[navTitle setUserInteractionEnabled:YES];
    [navTitle addGestureRecognizer:titleTapRecog];
	[titleTapRecog release];
	
}
-(void)viewWillDisappear:(BOOL)animated{
	self.topPVC.pcDots.alpha=0;
	[super viewWillDisappear:animated];
}
- (void)viewWillAppear:(BOOL)animated
{
	[UIView animateWithDuration:0.25f animations:^{
		self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
		[self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObject:[UIColor blackColor] forKey:UITextAttributeTextColor]];
		self.navigationController.navigationBar.tintColor = [UINavigationBar appearance].tintColor;
	} completion:^(BOOL finished) {
	}];

	[super viewWillAppear:animated];

	if(@available(iOS 11.0,*))
		self.topPVC.navigationItem.hidesSearchBarWhenScrolling = NO;

	self.topPVC.pcDots.alpha=1;
	[self.navigationController setToolbarHidden:NO animated:YES];

/*	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
		NSLog(@" is %f",self.searchDisplayController.searchBar.frame.size.height);
		[self.tableView setContentOffset:CGPointMake(0,-44)];
	}*/
    [[self tableView] reloadData];
}
-(BOOL)anyV1Tags{
	for(NSDictionary* tag in self.tagList){
		if(tag.version1==1)return YES;
	}
	return NO;
}
-(BOOL)anyV2Tags{
	for(NSDictionary* tag in self.tagList){
		if(tag.version1>=2)return YES;
	}
	return NO;
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
	NSString *searchString = searchController.searchBar.text;
	[self filterTagBySearchText:searchString scope:searchController.searchBar.selectedScopeButtonIndex];
	[self.tableView reloadData];
}
- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
	self.topPVC.savedSearchScopeMvc = selectedScope;
	[self updateSearchResultsForSearchController:self.topPVC.searchController];
}

- (void)viewDidDisappear:(BOOL)animated
{
    // save the state of the search UI so that it can be restored if the view is re-created
	/*searchWasActive = self.searchController.active;
	savedSearchTerm = self.searchController.searchBar.text;
    savedScopeButtonIndex = [self.searchController.searchBar selectedScopeButtonIndex];
	*/
	[super viewDidDisappear:animated];
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

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section 
{
	if (self.topPVC.searchController.active)
	{
        return [_filteredTagList count]+1;
    }
	else{
		/*NSInteger count =_tagList.count;
		return count==0?1:count;*/
		return _tagList.count+1;
	}
}
-(UITableViewCell*)cellForTag:(NSMutableDictionary *)t1{

	if(_tagList==nil || _tagList.count==0)return nil;
	
	UITableView *tableView = self.tableView; // Or however you get your table view
	for(NSIndexPath* ip in [tableView indexPathsForVisibleRows]){
		NSDictionary *tag;
		if ([self.topPVC.searchController isActive])
		{
			if(ip.row >= _filteredTagList.count)continue;
			tag = [_filteredTagList objectAtIndex:ip.row];
		}else{
			if(ip.row >= _tagList.count)continue;
			tag = [_tagList objectAtIndex:ip.row];
		}
		if([tag.uuid isEqualToString:t1.uuid])return [tableView cellForRowAtIndexPath:ip];
	}
	return nil;
}
-(void)setCurrentDisplayMode:(TagCellDisplayMode)currentDisplayMode{
	_currentDisplayMode = currentDisplayMode;
	[[NSUserDefaults standardUserDefaults]setInteger:_currentDisplayMode forKey:TagDisplayModePrefKey];
	[self.tableView reloadData];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if(indexPath.row == [self tableView:tableView numberOfRowsInSection:0]-1 ){
		return _associateBtnCell;
	}
/*	if(_tagList.count==0){
		UITableViewCell* cell0 = [[[UITableViewCell alloc]init] autorelease];
		cell0.textLabel.text = @"Tap the '+' button on the upper right corner to add your first tag.";
		cell0.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
		cell0.textLabel.numberOfLines=0; cell0.textLabel.textAlignment=NSTextAlignmentCenter;
		return cell0;
	}*/
    TagTableViewCell *cell = (TagTableViewCell *)[tableView
												  dequeueReusableCellWithIdentifier:@"Tag"];
	
    if (!cell) {
		cell = [[[TagTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Tag"] autorelease];
		//cell.delegate = self.delegate;
		cell.mvc = self;
		[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
		
		//cell.detailTextLabel.textAlignment = UITextAlignmentCenter;
		//cell.selectionStyle = UITableViewCellSelectionStyleNone;

        /*if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }*/
    }
    cell.useDegF = self.delegate.useDegF;
	
	NSMutableDictionary *tag;
	if (self.topPVC.searchController.active)
	{
		if(indexPath.row >= _filteredTagList.count)return cell;
		tag = [_filteredTagList objectAtIndex:indexPath.row];
    }else{
		if(indexPath.row >= _tagList.count)return cell;
		tag = [_tagList objectAtIndex:[indexPath row]];
	}
	
	if([tag isKindOfClass:[NSMutableDictionary class]])
		[cell setData:tag loadImage:YES animated:NO]; //(self.tableView.dragging == NO && self.tableView.decelerating == NO)];
	
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*- (void)loadImagesForOnscreenRows
{
    if ([_tagList count] > 0)
    {
        NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *indexPath in visiblePaths)
        {
            NSDictionary* tag = [_tagList objectAtIndex:indexPath.row];            
			if(![[ImageStore defaultImageStore] thumbnailLoadedForKey:tag.uuid]){
				
				UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
				[cell imageView].image = [[ImageStore defaultImageStore] thumbnailForKey:tag.uuid loadFromFile:YES];
			}
        }
    }
}
// Load images for all onscreen rows when scrolling is finished
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)[self loadImagesForOnscreenRows];
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self loadImagesForOnscreenRows];
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.row == [self tableView:tableView numberOfRowsInSection:0]-1 ){
		[_delegate associateTagBtnPressed:_associateBtnCell];
		return;
	}

	NSDictionary *tag;
	if ( self.topPVC.searchController.active)
	{
		if(indexPath.row >= _filteredTagList.count)return;
        tag = [_filteredTagList objectAtIndex:indexPath.row];
    }else{
		if(indexPath.row >= _tagList.count)return;
		tag = [_tagList objectAtIndex:[indexPath row]];
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	[_delegate tagSelected:tag.uuid fromCell:[tableView cellForRowAtIndexPath:indexPath]];
/*	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		self.topPVC.pcDots.alpha=0;
	}*/
}

// scope=0: all, 1: toohot, 2: normal, 3: toocold, 4: off
- (void)filterTagBySearchText:(NSString*)searchText scope:(NSInteger)scope
{
	[_filteredTagList removeAllObjects]; // First clear the filtered array.
	NSString* trimmedSearchText;
	if(searchText.length>1 && [searchText characterAtIndex:0]==' ')
		trimmedSearchText = [searchText substringFromIndex:1];
	else
		trimmedSearchText = searchText;
	
	for (NSDictionary *tag in _tagList)
	{
		if([searchText isEqualToString:@""] || NSNotFound != [tag.name rangeOfString:trimmedSearchText options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch) ].location)
		{
			if(scope>0){
				if(scope==1 && tag.tempEventState!=TooHigh)continue;
				else if(scope==2 && tag.tempEventState!=Normal)continue;
				else if(scope==3 && tag.tempEventState!=TooLow)continue;
				else if(scope==4 && tag.tempEventState!=TempDisarmed)continue;
			}
			[_filteredTagList addObject:tag];
		}
	}
}

-(void)reorderDoneButtonPressed{
	[self setEditing:NO animated:YES];
	
	[self.navigationItem setRightBarButtonItem:self.reorderDoneReplacingBtn];
	self.topPVC.mvc_right =self.reorderDoneReplacingBtn;
	self.reorderDoneReplacingBtn=nil;
}
-(void)startReordering{
	reorderDoneBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
															  target:self action:@selector(reorderDoneButtonPressed)];

	self.reorderDoneReplacingBtn = self.navigationItem.rightBarButtonItem;
	[self.navigationItem setRightBarButtonItem:reorderDoneBtn];
	self.topPVC.mvc_right = reorderDoneBtn;
	[self setEditing:YES animated:YES];
}
-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
	if(indexPath.row == [self tableView:tableView numberOfRowsInSection:0]-1 ){
		return NO;
	}
	return YES;
}
-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
	return UITableViewCellEditingStyleNone;
}
-(BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath{
	return NO;
}
-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath{
	if(indexPath.row > _tagList.count-1){
		return NO;
	}
	return YES;
}
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath{
	//NSLog(@"moved from %d to %d", sourceIndexPath.row, destinationIndexPath.row);
	if(sourceIndexPath.row>_tagList.count-1 || destinationIndexPath.row>_tagList.count-1)return;
	
	NSDictionary* tag1 = [[_tagList objectAtIndex:sourceIndexPath.row] retain];
	NSString* tag_prev = destinationIndexPath.row==0? nil : ((NSDictionary*)[_tagList objectAtIndex:destinationIndexPath.row-1]).uuid;
	NSString* tag_next = destinationIndexPath.row == _tagList.count-1? nil : ((NSDictionary*)[_tagList objectAtIndex:destinationIndexPath.row]).uuid;
	[_delegate swapOrderOf:tag1.uuid between:tag_prev and:tag_next];
	//[_tagList exchangeObjectAtIndex:sourceIndexPath.row withObjectAtIndex:destinationIndexPath.row];
	[_tagList removeObjectAtIndex:sourceIndexPath.row];
	[_tagList insertObject:tag1 atIndex:destinationIndexPath.row];
	[tag1 release];
}


#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods
/*- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterTagBySearchText:searchString scope:
	 [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    [self filterTagBySearchText:[self.searchDisplayController.searchBar text] scope:
	 [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}
- (void) searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller{
    self.topPVC.navigationController.navigationBarHidden=YES;
	self.searchDisplayController.searchBar.text=@" ";
}
- (void) searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller{
	contentOffsetBeforeSearch = [self.tableView contentOffset];
}
- (void) searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller{
	[self.tableView setContentOffset:contentOffsetBeforeSearch animated:YES];
    self.topPVC.navigationController.navigationBarHidden=NO;
}
*/

@end
@implementation UILabel(EllipsisFix)

-(void)setTextColorFixed:(NSString *)text{
	self.attributedText = [[[NSAttributedString alloc] initWithString:text attributes:@{ NSForegroundColorAttributeName : self.textColor }] autorelease];
}

@end

@implementation UIViewController (Additions)
- (BOOL)isVisible {
	return [self isViewLoaded] && self.view.window;
}
@end
