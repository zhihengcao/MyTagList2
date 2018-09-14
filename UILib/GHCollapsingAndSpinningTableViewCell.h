//
//  UICollapsingTableViewCell.h
//  iGithub
//
//  Created by me on 04.04.11.
//  Copyright 2011 Home. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    UIExpansionStyleCollapsed = 0,
    UIExpansionStyleExpanded
} UIExpansionStyle;


@interface GHCollapsingAndSpinningTableViewCell : UITableViewCell {
    
    UIImageView *_disclosureIndicatorImageView;
}

+ (GHCollapsingAndSpinningTableViewCell*)newWithStyle:(UIExpansionStyle)style;

- (void)setExpansionStyle:(UIExpansionStyle)style animated:(BOOL)animated;
@property (nonatomic, readonly) UIExpansionStyle expansionStyle;
@property (nonatomic, retain) UIImageView *disclosureIndicatorImageView;

@end
