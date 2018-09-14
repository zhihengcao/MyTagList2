//
//  ActionSheet+Blocks.m
//  MyTagList2
//
//  Created by Pei Chang on 2/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ActionSheet+Blocks.h"

Class object_setClass(id obj, Class cls);

@interface UIBlurEffect (Protected)
@property (nonatomic, readonly) id effectSettings;
@end


@implementation MyBlurEffect

+ (instancetype)effectWithStyle:(UIBlurEffectStyle)style
{
	id result = [super effectWithStyle:style];
	object_setClass(result, self);
	
	return result;
}

- (id)effectSettings
{
	id settings = [super effectSettings];
	[settings setValue:@4 forKey:@"blurRadius"];
	return settings;
}

- (id)copyWithZone:(NSZone*)zone
{
	id result = [super copyWithZone:zone];
	object_setClass(result, [self class]);
	return result;
}

@end
@implementation ActionSheet_Blocks
-(id)init
{
	self = [super init];
	if(self){
		handler_blocks = [[NSMutableArray alloc] init];
		self.delegate = self;
		bluredEffectView=nil;
	}
	return self;
}
-(void)dealloc{
	[handler_blocks release];
	[super dealloc];
}

-(void)addRedButtonWithTitle:(NSString*) title block:(void (^)(NSInteger index))handler{
	[super setDestructiveButtonIndex:[self addButtonWithTitle:title block:handler]];
}
-(void)addCancelButtonWithTitle:(NSString*) title{
	[super setCancelButtonIndex:[self addButtonWithTitle:title]];
}

-(NSInteger)addButtonWithTitle:(NSString*) title block:(void (^)(NSInteger index))handler{
	NSInteger index = [super addButtonWithTitle:title];
	[handler_blocks addObject:[[handler copy] autorelease]];
	return index;
}
- (void)showFromBarButtonItem:(UIBarButtonItem *)item viewToBlur:(UIView*)view{
	[self blurView:view];

	[super showFromBarButtonItem:item animated:YES];
}

-(void)showInView:(UIView *)view{
	if(view!=nil){
		[self blurView:view];
	}
	[super showInView:view];
}
-(void)unBlur{
/*	if([[UIDevice currentDevice].systemVersion floatValue] >= 8){
		[UIView animateWithDuration:0.2f animations:^{
			bluredEffectView.effect=nil;
		} completion:^(BOOL finished) {
			[bluredEffectView removeFromSuperview];
			bluredEffectView=nil;
		}];
	}
*/
	
}
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
//- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
	[self unBlur];
	if(handler_blocks.count > buttonIndex){
		void (^handler)(NSInteger index) = (void (^)(NSInteger index))[handler_blocks objectAtIndex:buttonIndex];
		handler(buttonIndex);
	}
}
-(void)blurView:(UIView*)view{
/*	if([[UIDevice currentDevice].systemVersion floatValue] >= 8){
		
		//		if([view isKindOfClass:[UIWindow class]])view =((UIWindow*)view).rootViewController.view;
		
		//UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
		bluredEffectView = [[[UIVisualEffectView alloc]init]autorelease];  //[[[UIVisualEffectView alloc] initWithEffect:blurEffect] autorelease];
		[bluredEffectView setFrame:view.bounds];
		[view addSubview:bluredEffectView];
		//bluredEffectView.alpha=0.1;
		[UIView animateWithDuration:0.3f animations:^{
			bluredEffectView.effect=[MyBlurEffect effectWithStyle:UIBlurEffectStyleLight];
			//bluredEffectView.alpha=0.5f;
		}];
	}
*/
	
}

-(void)showFromAnything:(id)sender viewToBlur:(UIView *)view{
	[self blurView:view];

	if([sender isKindOfClass:[UIBarButtonItem class]])
	   [self showFromBarButtonItem:sender animated:YES];
	else if([sender isKindOfClass: [UITableViewCell class]]){
		UITableViewCell* cell = sender;
		[self showFromRect:cell.bounds inView:cell.contentView animated:YES];
	}else if([sender isKindOfClass: [UIView class]]){
		UIView* view = sender;
		[self showFromRect:view.frame inView:view.superview animated:YES];
	}
}
@end

@interface LambdaAlert () <UIAlertViewDelegate>
@property(strong) UIAlertView *alert;
@property(strong) NSMutableArray *blocks;
@property(strong) id keepInMemory;
@end

@implementation LambdaAlert
@synthesize alert, blocks, dismissAction, keepInMemory;

- (id) initWithTitle: (NSString*) title message: (NSString*) message
{
    self = [super init];
    alert = [[UIAlertView alloc] initWithTitle:title message:message
									  delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
    blocks = [[NSMutableArray alloc] init];
    return self;
}
-(void)dealloc{
	[blocks release];
	[alert release];
	self.dismissAction=nil;
	[super dealloc];
}
- (void) show
{
    [alert show];
    [self setKeepInMemory:self];
}

- (void) dismissAnimated: (BOOL) animated
{
    [alert dismissWithClickedButtonIndex:0 animated:animated];
}

- (void) addButtonWithTitle: (NSString*) title block: (dispatch_block_t) block
{
    if (!block) block = ^{};
    [alert addButtonWithTitle:title];
    [blocks addObject:[[block copy] autorelease]];
}

- (void) alertView: (UIAlertView*) alertView didDismissWithButtonIndex: (NSInteger) buttonIndex
{
    if (buttonIndex >= 0 && buttonIndex < [blocks count]) {
        dispatch_block_t block = [blocks objectAtIndex:buttonIndex];
        block();
    }
    if (dismissAction != NULL) {
        dismissAction();
    }
    [self setKeepInMemory:nil];
}

@end
