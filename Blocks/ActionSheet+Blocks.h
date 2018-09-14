//
//  ActionSheet+Blocks.h
//  MyTagList2
//
//  Created by Pei Chang on 2/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MyBlurEffect : UIBlurEffect
@end

@interface ActionSheet_Blocks : UIActionSheet <UIActionSheetDelegate>{
	NSMutableArray* handler_blocks;
	UIVisualEffectView *bluredEffectView;
}

-(void)addRedButtonWithTitle:(NSString*) title block:(void (^)(NSInteger index))handler;
-(void)addCancelButtonWithTitle:(NSString*) title;
-(NSInteger)addButtonWithTitle:(NSString*) title block:(void (^)(NSInteger index))handler;
-(void)showFromAnything:(id)sender viewToBlur:(UIView*)view;
-(void)showInView:(UIView *)view;
- (void)showFromBarButtonItem:(UIBarButtonItem *)item viewToBlur:(UIView*)view;

@end

@interface LambdaAlert : NSObject

@property(copy) dispatch_block_t dismissAction;

- (id) initWithTitle: (NSString*) title message: (NSString*) message;
- (void) addButtonWithTitle: (NSString*) title block: (dispatch_block_t) block;

- (void) show;
- (void) dismissAnimated: (BOOL) animated;

@end
