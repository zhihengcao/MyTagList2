//
//  UICollapsingTableViewCell.m
//  iGithub
//
//  Created by me on 04.04.11.
//  Copyright 2011 Home. All rights reserved.
//

#import "GHCollapsingAndSpinningTableViewCell.h"


@implementation GHCollapsingAndSpinningTableViewCell

@synthesize disclosureIndicatorImageView=_disclosureIndicatorImageView, expansionStyle=_expansionStyle;

-(void)dealloc{
	self.disclosureIndicatorImageView=nil;
	[super dealloc];
}
+ (GHCollapsingAndSpinningTableViewCell*)newWithStyle:(UIExpansionStyle)style {
	GHCollapsingAndSpinningTableViewCell* cell =  [[GHCollapsingAndSpinningTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"GHCollapsingAndSpinningTableViewCell"];
	[cell setExpansionStyle:style animated:NO];
	return cell;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        // Initialization code
		self.textLabel.textAlignment = NSTextAlignmentCenter;
		self.textLabel.font = [UIFont systemFontOfSize:17];
        self.disclosureIndicatorImageView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"UITableViewCellAccessoryDisclosureIndicator.PNG"]] autorelease];
    }
    return self;
}

#pragma mark - super implementation

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    if (selected) {
        self.disclosureIndicatorImageView.image = [UIImage imageNamed:@"UITableViewCellAccessoryDisclosureIndicatorSelected.PNG"];
    } else {
        self.disclosureIndicatorImageView.image = [UIImage imageNamed:@"UITableViewCellAccessoryDisclosureIndicator.PNG"];
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    
    if (highlighted) {
        self.disclosureIndicatorImageView.image = [UIImage imageNamed:@"UITableViewCellAccessoryDisclosureIndicatorSelected.PNG"];
    } else {
        self.disclosureIndicatorImageView.image = [UIImage imageNamed:@"UITableViewCellAccessoryDisclosureIndicator.PNG"];
    }
}
/*
- (void)layoutSubviews {
    [super layoutSubviews];
    self.accessoryView.center = CGPointMake(15.0, 22.0);
    self.textLabel.frame = CGRectMake(27.0, 0.0, self.contentView.bounds.size.width-27.0, 44.0);
}*/

- (void)setExpansionStyle:(UIExpansionStyle)style animated:(BOOL)animated
{
	_expansionStyle = style;
    void(^animationBlock)(void) = ^(void) {
        self.accessoryView = self.disclosureIndicatorImageView;
        switch (style) {
            case UIExpansionStyleExpanded:
				self.textLabel.text=NSLocalizedString(@"Less",nil);
                self.accessoryView.transform = CGAffineTransformIdentity;
                break;
            case UIExpansionStyleCollapsed:
				self.textLabel.text=NSLocalizedString(@"More...",nil);
                self.accessoryView.transform = CGAffineTransformMakeRotation(M_PI-0.00001);
                break;
                
            default:
                break;
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:0.25f animations:animationBlock];
    } else {
        animationBlock();
    }
}

@end
