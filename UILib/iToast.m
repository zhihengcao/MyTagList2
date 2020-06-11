//
//  iToast.m
//  iToast
//
//  Created by Diallo Mamadou Bobo on 2/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "iToast.h"
#import <QuartzCore/QuartzCore.h>

static iToastSettings *sharedSettings = nil;

@interface iToast(private)

- (iToast *) settings;

@end


@implementation iToast
@synthesize mac, slaveid, popoverController=_popoverController;

- (id) initWithText:(NSString *) tex andDetail:(NSString*)detai{
	if (self = [super init]) {
		text = [tex copy];
		detail = [detai copy];
		offsetTop=-50;
	}
	
	return self;
}
- (void) show{
	[self showFrom:nil];
}
-(void)showFrom:(id)sender {


	iToastSettings *theSettings = _settings;
	
	if (!theSettings) {
		theSettings = [iToastSettings getSharedSettings];
	}
	
	showInPopover=([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) && sender!=nil;
	
	UIWindow* window;
	//window = [[[UIApplication sharedApplication] windows] objectAtIndex:0];
    //window = [UIApplication sharedApplication].keyWindow;
    //if (!window) {
	if([UIApplication sharedApplication].windows.count==0)
		window =[UIApplication sharedApplication].keyWindow;
	else
        window = [[UIApplication sharedApplication].windows objectAtIndex:0];			
    //}
	if(window==nil)return;
	
	CGFloat windowWidth =window.frame.size.width;
	CGFloat screenwidth = showInPopover?480:windowWidth;
	if(screenwidth>480)screenwidth=480;
	CGFloat screenheight = 	window.frame.size.height;
	
	BOOL info = (theSettings.toastType==iToastTypeInfo);
	
	UIFont *font = [UIFont boldSystemFontOfSize:info? 20: 15];
	CGSize textSize = [text sizeWithFont:font  forWidth:screenwidth-20 lineBreakMode:NSLineBreakByWordWrapping];
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, textSize.width, textSize.height)];
	label.backgroundColor = [UIColor clearColor];
	label.textColor = info?[UIColor whiteColor]: [UIColor blackColor];//[UIColor colorWithRed:3.0/15 green:3.0/15 blue:3.0/15 alpha:1];
	label.font = font;
	label.text = text;
	label.lineBreakMode =NSLineBreakByWordWrapping;//  NSLineBreakModeWordWrap;
	label.numberOfLines = 0;
	[label sizeToFit];
//	label.shadowColor=[UIColor whiteColor];
//	label.shadowOffset=CGSizeMake(1, 0);

	UIButton *v = [UIButton buttonWithType:UIButtonTypeCustom];
	
	if(detail.length>0){
		UIFont *font2 = [UIFont boldSystemFontOfSize:12];
		CGSize textSize2 = [detail sizeWithFont:font2 forWidth:screenwidth-20 lineBreakMode:NSLineBreakByWordWrapping];
		UILabel *label2 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0,  textSize2.width, textSize2.height)];
		label2.backgroundColor = [UIColor clearColor];
		label2.textColor = [UIColor blackColor];//[UIColor colorWithRed:3.0/15 green:3.0/15 blue:3.0/15 alpha:1];
		label2.font = font2;
		label2.text = detail;
		label2.lineBreakMode = NSLineBreakByWordWrapping; //UILineBreakModeWordWrap;
		label2.numberOfLines = 0;
		[label2 sizeToFit];
		v.frame = CGRectMake(0, 0, screenwidth, label.frame.size.height + label2.frame.size.height + 50);
		label2.center = CGPointMake(v.frame.size.width / 2, label.frame.size.height+32+label2.frame.size.height/2);
		[v addSubview:label2];
		[label2 release];
	}else{
		if(info)
			v.frame = CGRectMake(0, 0, label.frame.size.width+80, label.frame.size.height+50);
		else
			v.frame = CGRectMake(0, 0, screenwidth, label.frame.size.height + 50);

	}
	label.center = CGPointMake(v.frame.size.width / 2, label.frame.size.height/2+25);
	[v addSubview:label];
	[label release];
	
	//(float)0xfc/(float)0xff green:(float)0xed/(float)0xff blue:(float)0xa7/(float)0xff
//	v.backgroundColor = [UIColor colorWithRed:(float)0xfa/(float)0xff green:(float)0xdb/(float)0xff blue:(float)0x4e/(float)0xff alpha:0.75];

	
	//v.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.75];
	
	if(windowWidth>480)
		v.layer.cornerRadius = 16;
	//v.layer.borderWidth=1;
	/*if(!showInPopover)*/{
	
		if(info)
		{
			[v.layer setBackgroundColor:[[UIColor colorWithWhite:0.3 alpha:0.7] CGColor]];
			v.layer.cornerRadius=10;
		}
		else
		{
			CAGradientLayer* gradient = [CAGradientLayer layer];
			gradient.frame = v.bounds;
			gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor whiteColor] CGColor], (id)[[UIColor colorWithRed:(float)0xfa/(float)0xff green:(float)0xeb/(float)0xff blue:(float)0x9e/(float)0xff alpha:1] CGColor], nil];
			if(windowWidth>480)
				gradient.cornerRadius=12;
			//gradient.borderColor=[[UIColor colorWithRed:(float)0xf7/(float)0xff green:(float)0xc9/(float)0xff blue:(float)0x42/(float)0xff alpha:1] CGColor];
			gradient.borderWidth=0;
			[v.layer insertSublayer:gradient atIndex:0];
			v.layer.masksToBounds = NO;
		}
		v.layer.shadowColor = [UIColor blackColor].CGColor;
		v.layer.shadowOpacity = 0.8;
		v.layer.shadowRadius = 8;
		v.layer.shadowOffset = CGSizeMake(8.0f, 8.0f);
	}
	//v.layer.zPosition=10000;
    //parentView = [[firstSubview subviews] objectAtIndex:0];
	

	if(!showInPopover){
		if (theSettings.gravity == iToastGravityTop) {
			v.center = CGPointMake(windowWidth / 2, v.frame.size.height/2);
		}else if (theSettings.gravity == iToastGravityBottom) {
			v.center = CGPointMake(windowWidth / 2, screenheight - v.frame.size.height/2);
		}else if (theSettings.gravity == iToastGravityCenter) {
			v.center = CGPointMake(windowWidth/2, screenheight/2 );
		}else{
			v.center = theSettings.postition;
		}
	}
	timer = [[NSTimer timerWithTimeInterval:((float)theSettings.duration)/1000
									 target:self selector:@selector(hideToast:)
								   userInfo:nil repeats:NO] retain];
	[[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
	
	if (!showInPopover){
		UIView *parentView = [[window subviews] objectAtIndex:0];
		//[window addSubview:v];
		[parentView addSubview:v];
		
	}else{
		UIViewController* popoverContent = [[[UIViewController alloc]init] autorelease];
		popoverContent.view = v;
		if([popoverContent respondsToSelector:@selector(setPreferredContentSize:)])
			popoverContent.preferredContentSize=v.frame.size;
		
		
		if([[UIDevice currentDevice].systemVersion floatValue] >= 8){
			popoverContent.modalPresentationStyle=UIModalPresentationPopover;
			if([sender isKindOfClass:[UITableViewCell class]]){
				UITableViewCell* cell = sender;
				popoverContent.popoverPresentationController.sourceView=sender;
				popoverContent.popoverPresentationController.sourceRect=CGRectMake( cell.bounds.size.width/2, ((UITableViewCell*)sender).bounds.size.height-8,
																				   v.frame.size.width,v.frame.size.height);
			}else
				popoverContent.popoverPresentationController.barButtonItem=sender;
			
			[iToast.topMostController presentViewController:popoverContent animated:YES completion:nil];

		}else{
			popoverContent.preferredContentSize = v.frame.size;
			self.popoverController = [[[UIPopoverController alloc] initWithContentViewController:popoverContent] autorelease];
			if ([_popoverController respondsToSelector:@selector(setBackgroundColor:)]) {   // Check to avoid app crash prior to iOS 7
				_popoverController.backgroundColor =[UIColor colorWithRed:1 green:1 blue:(float)0xd1/(float)0xff alpha:0.95];
				
				if([sender isKindOfClass:[UITableViewCell class]]){
					UITableViewCell* cell = sender;
					[_popoverController presentPopoverFromRect:cell.bounds inView:cell.contentView
									  permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
				}else{
					[_popoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
				}
			}else{
				self.popoverController=nil;
				UIView *parentView = [[window subviews] objectAtIndex:0];
				[parentView addSubview:v];
			}
		}
	}

	view = [v retain];

//	[v addTarget:self action:@selector(hideToast:) forControlEvents:UIControlEventTouchDown];
//	[v addTarget:self action:@selector(openToast:) forControlEvents:UIControlEventTouchDownRepeat];
	[v addTarget:self action:@selector(openToast:) forControlEvents:UIControlEventTouchDown];
}
+ (UIViewController*) topMostController
{
	UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
	
	while (topController.presentedViewController) {
		topController = topController.presentedViewController;
	}
	
	return topController;
}

- (void) hideToast:(id)o{
	if(timer!=nil){
		[timer invalidate];
		[timer release];
		timer=nil;
	}
	if(showInPopover){
		if([[UIDevice currentDevice].systemVersion floatValue] >= 8){
			[iToast.topMostController dismissViewControllerAnimated:YES completion:^{}];
		}else{
			if(_popoverController){
				[_popoverController dismissPopoverAnimated:YES];
				self.popoverController=nil;
			}else{
				[[[UIApplication sharedApplication].windows objectAtIndex:0].rootViewController dismissViewControllerAnimated:YES completion:nil];
			}
		}
	}else{
		[UIView animateWithDuration:0.3 animations:^{
			view.alpha = 0;
		}];
		
		//[UIView beginAnimations:nil context:NULL];
		//view.alpha = 0;
		//[UIView commitAnimations];
		
		NSTimer *timer2 = [NSTimer timerWithTimeInterval:500
												  target:self selector:@selector(removeToast:)
												userInfo:nil repeats:NO];
		[[NSRunLoop mainRunLoop] addTimer:timer2 forMode:NSDefaultRunLoopMode];
	}
}

- (void) removeToast:(NSTimer*)theTimer{
	[view removeFromSuperview];
}


static NSString* lastToast = nil;

+ (iToast *) makeText:(NSString *) _text{
	if([_text isEqualToString:lastToast])return nil;
	
	lastToast=_text;
	[NSTimer scheduledTimerWithTimeInterval:5 block:^{
		lastToast=nil;
	} repeats:NO];
	
	iToast *toast = [[[iToast alloc] initWithText:_text andDetail:@""] autorelease];
	return toast;
}


+ (iToast *) makeText:(NSString *) _text andDetail:(NSString*)_detail{
	iToast *toast = [[[iToast alloc] initWithText:_text andDetail:_detail] autorelease];	
	return toast;
}


- (iToast *) setDuration:(NSInteger ) duration{
	[self theSettings].duration = duration;
	return self;
}

-(void)dealloc{
	[openAction release]; openAction=nil;
	[view release]; view=nil;
	self.popoverController=nil;
	self.mac=nil;
	[super dealloc];
}
- (iToast *) setOpenAction:(dispatch_block_t) block{
	[openAction autorelease];
	openAction = [block copy];
	return self;
}
- (void) openToast:(id)o{
	if(openAction!=nil)openAction();
	[self hideToast:o];
}

- (iToast *) setGravity:(iToastGravity) gravity 
			 offsetLeft:(NSInteger) left
			  offsetTop:(NSInteger) top{
	[self theSettings].gravity = gravity;
	offsetLeft = left;
	offsetTop = top;
	return self;
}

- (iToast *) setGravity:(iToastGravity) gravity{
	[self theSettings].gravity = gravity;
	return self;
}

- (iToast *) setPostion:(CGPoint) _position{
	[self theSettings].postition = CGPointMake(_position.x, _position.y);
	
	return self;
}

-(iToastSettings *) theSettings{
	if (!_settings) {
		_settings = [[iToastSettings getSharedSettings] copy];
	}
	
	return _settings;
}

@end


@implementation iToastSettings
@synthesize duration;
@synthesize gravity;
@synthesize postition, toastType;
@synthesize images;

- (void) setImage:(UIImage *) img forType:(iToastType) type{
	if (!images) {
		images = [[NSMutableDictionary alloc] initWithCapacity:4];
	}
	
	if (img) {
		NSString *key = [NSString stringWithFormat:@"%i", type];
		[images setValue:img forKey:key];
	}
}


+ (iToastSettings *) getSharedSettings{
	if (!sharedSettings) {
		sharedSettings = [iToastSettings new];
		sharedSettings.gravity = iToastGravityCenter;
		sharedSettings.duration = iToastDurationNormal;
		sharedSettings.toastType = iToastTypeNotice;
	}
	
	return sharedSettings;
	
}

- (id) copyWithZone:(NSZone *)zone{
	iToastSettings *copy = [iToastSettings new];
	copy.gravity = self.gravity;
	copy.duration = self.duration;
	copy.postition = self.postition;
	
	NSArray *keys = [self.images allKeys];
	
	for (NSString *key in keys){
		[copy setImage:[images valueForKey:key] forType:[key intValue]];
	}
	
	return copy;
}

@end
