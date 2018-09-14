//
//  ActivityIndicatorItem.m
//  newsyc
//
//  Created by Grant Paul on 4/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ActivityIndicatorItem.h"

@implementation ActivityIndicatorItem
@synthesize spinner;

+ (ActivityIndicatorItem*)new{

	UIActivityIndicatorView* spinner = [[[UIActivityIndicatorView alloc] init] autorelease];
	[spinner setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
	[spinner setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
    ActivityIndicatorItem* ai  = [[ActivityIndicatorItem alloc] initWithCustomView:spinner];
	[spinner startAnimating];
	[spinner sizeToFit];
    return ai;
}

// XXX: this cannot be named -init because -init is called by UIKit itself inside -initWithCustomView:
/*- (id)initWithSize:(CGSize)size {

    UIView *container_ = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)] autorelease];

    if ((self = [super initWithCustomView:container_])) {
        spinner = [[UIActivityIndicatorView alloc] init];
        [spinner setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
        [spinner setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
		
		container = [container_ retain];
        [container addSubview:spinner];
		[spinner setCenter:CGPointMake((size.width-spinner.bounds.size.width)/2, (size.height-spinner.bounds.size.height)/2)];
		[spinner startAnimating];
//        [spinner sizeToFit];
        
    }
	return self;
}
- (void)dealloc {
    [container release];
    [spinner release];
    
    [super dealloc];
}
*/
@end
