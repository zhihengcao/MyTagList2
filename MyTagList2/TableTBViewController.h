//
//  TableTBViewController.h
//  MyTagList2
//
//  Created by Pei Chang on 2/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ActivityIndicatorItem.h"

@interface TableTBViewController : UITableViewController
{
	UIBarButtonItem* spacerItem;
}
@property(nonatomic, retain)UIBarButtonItem*   staticLeftNavBtn;
@property(nonatomic, retain)NSArray* staticRightNavBtns;

@property(nonatomic, retain) NSArray* staticToolBarItems;

- (void)showLoadingBarItem:(id) item;
- (void)revertLoadingBarItem:(id) item;

@end

@interface TableLoadingButtonCell : UITableViewCell
{
}
@property(nonatomic, retain)NSString* progressTitle, *title;
@property(nonatomic, retain)UIActivityIndicatorView* activityIndicator;
+ (TableLoadingButtonCell*)newWithTitle:(NSString*)title Progress:(NSString*)progressTitle;
+ (TableLoadingButtonCell*)newWithTitle:(NSString*)title Progress:(NSString*)progressTitle andIcon:(NSString*)iconName;
-(void)showLoading;
-(void)revertLoading;

@end
