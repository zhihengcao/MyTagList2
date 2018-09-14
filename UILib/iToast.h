//
//  iToast.h
//  iToast
//
//  Created by Diallo Mamadou Bobo on 2/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NSTimer+Blocks.h"

typedef enum iToastGravity {
	iToastGravityTop = 1000001,
	iToastGravityBottom,
	iToastGravityCenter
}iToastGravity;

typedef enum iToastDuration {
	iToastDurationLong = 6000,
	iToastDurationShort = 1000,
	iToastDurationNormal = 4000
}iToastDuration;

typedef enum iToastType {
	iToastTypeInfo = -100000,
	iToastTypeNotice,
	iToastTypeWarning,
	iToastTypeError
}iToastType;


@interface iToastSettings : NSObject<NSCopying>{
	NSInteger duration;
	iToastGravity gravity;
	CGPoint postition;
	iToastType toastType;
	
	NSDictionary *images;
	
	BOOL positionIsSet;
}


@property(assign) NSInteger duration;
@property(assign) iToastGravity gravity;
@property(assign) CGPoint postition;
@property(readonly) NSDictionary *images;
@property(assign)iToastType toastType;

- (void) setImage:(UIImage *)img forType:(iToastType) type;
+ (iToastSettings *) getSharedSettings;

@end


@interface iToast : NSObject {
	iToastSettings *_settings;
	NSInteger offsetLeft;
	NSInteger offsetTop;
	dispatch_block_t  openAction;
	
	NSTimer *timer;
	BOOL showInPopover;
	UIView *view;
	NSString *text;
	NSString *detail;
}
@property (retain, nonatomic) UIPopoverController* popoverController;

+ (UIViewController*) topMostController;

- (void) show;
-(void)showFrom:(id)sender ;

- (id) initWithText:(NSString *) tex andDetail:(NSString*)detai;
- (iToast *) setDuration:(NSInteger ) duration;
- (iToast *) setGravity:(iToastGravity) gravity 
			 offsetLeft:(NSInteger) left
			 offsetTop:(NSInteger) top;
- (iToast *) setGravity:(iToastGravity) gravity;
- (iToast *) setPostion:(CGPoint) position;
- (iToast *) setOpenAction:(dispatch_block_t) block;

+ (iToast *) makeText:(NSString *) _text andDetail:(NSString*)_detail;
+ (iToast *) makeText:(NSString *) _text;

-(iToastSettings *) theSettings;

@property(nonatomic, retain) NSString* mac;
@property(nonatomic) int slaveid;

@end


