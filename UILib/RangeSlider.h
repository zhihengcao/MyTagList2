//
//  RangeSlider.h
//  RangeSlider
//
//  Created by Mal Curtis on 5/08/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RangeSlider : UIControl{
    float distanceFromCenter;

    float _padding;
    
    BOOL _maxThumbOn;
    BOOL _minThumbOn;
    
    UIImageView * _minThumb;
    UIImageView * _maxThumb;
    UIImageView * _track;
    UIImageView * _trackBackground;
}

- (void)updateHandleImages;
@property(nonatomic) float currentValue;
@property(nonatomic) BOOL forceInRange;
@property(nonatomic) float minimumValue;
@property(nonatomic) float maximumValue;
@property(nonatomic) float stepSize;
@property(nonatomic) float minimumRange;
@property(nonatomic) float selectedMinimumValue;
@property(nonatomic) float selectedMaximumValue;

@end
