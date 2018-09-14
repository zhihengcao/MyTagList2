//
//  SpinnerView.h
//  LazyTableImages
//
//  Created by Pei Chang on 1/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SpinnerView : UIView
+(SpinnerView *)loadSpinnerIntoView:(UIView *)superView;
-(void)removeSpinner;
//-(void)addSpinner;

@end
