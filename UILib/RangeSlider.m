//
//  RangeSlider.m
//  RangeSlider
//
//  Created by Mal Curtis on 5/08/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RangeSlider.h"

@interface RangeSlider (PrivateMethods)
-(float)xForValue:(float)value;
-(float)valueForX:(float)x;
-(void)updateTrackHighlight;
@end

@implementation RangeSlider

@synthesize minimumValue=_minimumValue, maximumValue=_maximumValue, minimumRange=_minimumRange, selectedMinimumValue=_selectedMinimumValue, selectedMaximumValue=_selectedMaximumValue, currentValue=_currentValue, forceInRange=_forceInRange;
@synthesize stepSize;

-(void)setMaximumValue:(float)v{
	_maximumValue = v;
	if(_forceInRange){
		if(_selectedMaximumValue>_maximumValue)_selectedMaximumValue=_maximumValue;
		if(_selectedMinimumValue>_maximumValue)_selectedMinimumValue=_maximumValue;
		if(_selectedMaximumValue<_minimumValue)_selectedMaximumValue=_minimumValue;
		if(_selectedMinimumValue<_minimumValue)_selectedMinimumValue=_minimumValue;
	}
}
// do not allow user to select values outside of_minimumValue and_maximumValue
-(void)setMinimumValue:(float)v{
	_minimumValue=v;
	if(_forceInRange){
		if(_selectedMaximumValue>_maximumValue)_selectedMaximumValue=_maximumValue;
		if(_selectedMinimumValue>_maximumValue)_selectedMinimumValue=_maximumValue;
		if(_selectedMaximumValue<_minimumValue)_selectedMaximumValue=_minimumValue;
		if(_selectedMinimumValue<_minimumValue)_selectedMinimumValue=_minimumValue;
	}
}
-(void)setCurrentValue:(float)currentValue{
	_currentValue = currentValue;
	[self updateTrackHighlight];
}
-(void)setMinimumRange:(float)minimumRange{
	_minimumRange=minimumRange;
	if(_selectedMinimumValue>_selectedMaximumValue-_minimumRange){
		if(_selectedMinimumValue+_minimumRange>_maximumValue)
			_selectedMinimumValue=_selectedMaximumValue-_minimumRange;
		else
			_selectedMaximumValue=_selectedMinimumValue+_minimumRange;
	}
}
-(float)findValueMatchingStepSizeFor:(float)rawValue{
	return round((rawValue-_minimumValue)/stepSize)*stepSize+_minimumValue;
}
-(void)setSelectedMaximumValue:(float)rawValue{
	
	if(_forceInRange){
		_selectedMaximumValue = [self findValueMatchingStepSizeFor:rawValue];
		if(_selectedMinimumValue>_selectedMaximumValue-_minimumRange)_selectedMaximumValue=_selectedMinimumValue+_minimumRange;
	}else{
		_selectedMaximumValue = rawValue;
	}
}
-(void)setSelectedMinimumValue:(float)rawValue{
	
	if(_forceInRange){
		_selectedMinimumValue =  [self findValueMatchingStepSizeFor:rawValue];
		if(_selectedMinimumValue>_selectedMaximumValue-_minimumRange)_selectedMinimumValue=_selectedMaximumValue-_minimumRange;
	}else
		_selectedMinimumValue = rawValue;
}
-(void)customInit{
	_forceInRange=YES;
	_minThumbOn = false;
	_maxThumbOn = false;
	_padding = 16;
	
	_trackBackground = [[ [UIImageView alloc] initWithImage:
						 [[UIImage imageNamed:@"bar-background.png"] stretchableImageWithLeftCapWidth:40 topCapHeight:11]] autorelease];
	[self addSubview:_trackBackground];
	_trackBackground.autoresizingMask=UIViewAutoresizingFlexibleWidth;
	
	_track = [[[UIImageView alloc] initWithImage:
			   [[UIImage imageNamed:@"bar-highlight.png"]stretchableImageWithLeftCapWidth:40 topCapHeight:11]] autorelease];
	[self addSubview:_track];
	
	_minThumb = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"handle_left.png"] /*highlightedImage:[UIImage imageNamed:@"handle-hover.png"]*/] autorelease];
	_minThumb.contentMode = UIViewContentModeCenter;
	[self addSubview:_minThumb];
	
	_maxThumb = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"handle_right.png"] /*highlightedImage:[UIImage imageNamed:@"handle-hover.png"]*/] autorelease];
	_maxThumb.contentMode = UIViewContentModeCenter;
	[self addSubview:_maxThumb];
	
	_minThumb.frame = CGRectMake(0,0, self.frame.size.height,self.frame.size.height);
	_maxThumb.frame = CGRectMake(0,0, self.frame.size.height,self.frame.size.height);
}
-(void)awakeFromNib
{
	[self customInit];
	NSLog(@"awakeFromNib frame=%f,%f,%f,%f, center=%f,%f", self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height, 
		  self.center.x, self.center.y);
}
/*
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
		NSLog(@"initWithCoder frame=%@, center=%@", self.frame, self.center);
		[self customInit];
    }    
    return self;
}
*/
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		[self customInit];
    }
    
    return self;
}

-(void)layoutSubviews
{
	[super layoutSubviews];
//	NSLog(@"layoutSubviews frame=%f,%f,%f,%f, center=%f,%f", self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height,
//		  self.center.x, self.center.y);
	
	CGPoint center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height-_trackBackground.bounds.size.height);
	_trackBackground.center = center;
	_track.center = center;
	
    _minThumb.center = CGPointMake([self xForValue:_selectedMinimumValue]-_minThumb.bounds.size.width/2.9, self.bounds.size.height-_minThumb.bounds.size.height/2.4);
    _maxThumb.center = CGPointMake([self xForValue:_selectedMaximumValue]+_maxThumb.bounds.size.width/2.9, self.bounds.size.height-_maxThumb.bounds.size.height/2.4);
        
    NSLog(@"Tapable size %f", _minThumb.bounds.size.width); 
    [self updateTrackHighlight];
}

-(float)xForValue:(float)value{
    float ret= (_trackBackground.bounds.size.width-(_padding*2))*((value - _minimumValue) / (_maximumValue - _minimumValue))+_padding+_trackBackground.frame.origin.x;
	if(ret<_padding+_trackBackground.frame.origin.x)return _padding+_trackBackground.frame.origin.x;
	if(ret>_trackBackground.bounds.size.width-_padding+_trackBackground.frame.origin.x) return _trackBackground.bounds.size.width-_padding+_trackBackground.frame.origin.x;
	return ret;
}

-(float) valueForX:(float)x{
    return _minimumValue + (x-_padding-_trackBackground
						   .frame.origin.x) / (_trackBackground.bounds.size.width-(_padding*2)) * (_maximumValue - _minimumValue);
}
- (void)updateHandleImages
{
    _minThumb.highlighted = _minThumbOn;
	_maxThumb.highlighted=_maxThumbOn;
}
/*-(void)setSelectedMaximumValue:(float)value{
	selectedMaximumValue = value;
	[self layoutSubviews];
}
-(void)setSelectedMinimumValue:(float)value{
	selectedMinimumValue = value;
	[self layoutSubviews];
}
*/
-(BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event{
    if(!_minThumbOn && !_maxThumbOn){
        return YES;
    }
    
    CGPoint touchPoint = [touch locationInView:self];
    if(_minThumbOn){
		double rawValue =[self valueForX:MAX([self xForValue:_minimumValue], touchPoint.x - distanceFromCenter)];
		self.selectedMinimumValue= [self findValueMatchingStepSizeFor:rawValue]; //rawValue;
		_minThumb.center = CGPointMake([self xForValue:_selectedMinimumValue]-_minThumb.bounds.size.width/2.9, _minThumb.center.y);
        
    }
    if(_maxThumbOn){

		double rawValue =[self valueForX:MIN([self xForValue:_maximumValue], touchPoint.x - distanceFromCenter)];
		self.selectedMaximumValue =  [self findValueMatchingStepSizeFor:rawValue]; //rawValue;
		_maxThumb.center = CGPointMake([self xForValue:_selectedMaximumValue]+_maxThumb.bounds.size.width/2.9, _maxThumb.center.y);

    }
//    [self updateTrackHighlight];
//    [self setNeedsLayout];
    
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    return YES;
}

-(BOOL) beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event{
    CGPoint touchPoint = [touch locationInView:self];
	
	BOOL onMax =CGRectContainsPoint(_maxThumb.frame, touchPoint), onMin =CGRectContainsPoint(_minThumb.frame, touchPoint);
	BOOL closerToMax = fabs(touchPoint.x - _maxThumb.center.x)< fabs(touchPoint.x - _minThumb.center.x);
	
    if(onMax && closerToMax){
        _maxThumbOn = true;
        distanceFromCenter = touchPoint.x - _maxThumb.center.x +_maxThumb.bounds.size.width/2.9;
        
    }
	else if(onMin && !closerToMax){
		_minThumbOn = true;
		distanceFromCenter = touchPoint.x - _minThumb.center.x -_minThumb.bounds.size.width/2.9;
	}
    [self updateHandleImages];
    return YES;
}

-(void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event{
    _minThumbOn = false;
    _maxThumbOn = false;
	[self updateHandleImages];

}

-(void)updateTrackHighlight{
	_track.frame = CGRectMake(
                              0, //_minThumb.center.x,
                              _track.center.y - (_track.frame.size.height/2),
							[self xForValue:_currentValue], //_maxThumb.center.x - _minThumb.center.x,
                              _track.frame.size.height
                              );
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

@end
