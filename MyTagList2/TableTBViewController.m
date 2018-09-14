//
//  TableTBViewController.m
//  MyTagList2
//
//  Created by Pei Chang on 2/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TableTBViewController.h"

@implementation TableTBViewController
@synthesize staticToolBarItems, staticLeftNavBtn, staticRightNavBtns;

-(void) viewDidAppear:(BOOL)animated{
	if([self respondsToSelector:@selector(setPreferredContentSize:)])
		self.preferredContentSize=self.tableView.contentSize;
	[super viewDidAppear:animated];
}
-(void)dealloc
{
	[staticToolBarItems release]; staticToolBarItems=nil;
	self.staticLeftNavBtn=nil;
	self.staticRightNavBtns=nil;
	[super dealloc];
}
-(void)viewDidUnload
{
	[staticToolBarItems release]; staticToolBarItems=nil;
	[super viewDidUnload];
}
- (void) showLoadingBarItem:(id) item 
{
	ActivityIndicatorItem* ai = [[ActivityIndicatorItem new] autorelease];
	if(item == [[self navigationItem] leftBarButtonItem]){
		self.staticLeftNavBtn=item;
		[[self navigationItem] setLeftBarButtonItem:ai];
	}
	else{
		NSMutableArray* newItems;
		NSInteger i;
		if( self.navigationItem.rightBarButtonItems.count>1){
			for(i=0;i<self.navigationItem.rightBarButtonItems.count;i++){
				if([self.navigationItem.rightBarButtonItems objectAtIndex:i] == item){
					self.staticRightNavBtns = [[self.navigationItem.rightBarButtonItems copy] autorelease];
					newItems = [self.navigationItem.rightBarButtonItems.mutableCopy autorelease];
					[newItems replaceObjectAtIndex:i withObject:ai];
					self.navigationItem.rightBarButtonItems=newItems;
					return;
				}
			}
		}else{
			if(item == [[self navigationItem] rightBarButtonItem]){
				self.staticRightNavBtns = [NSArray arrayWithObject:self.navigationItem.rightBarButtonItem];
				[[self navigationItem] setRightBarButtonItem:ai];
			}
		}
		for (i=0; i<self.toolbarItems.count; i++) {
			if([self.toolbarItems objectAtIndex:i] == item){
				newItems = [self.toolbarItems.mutableCopy autorelease];
				[newItems replaceObjectAtIndex:i withObject:ai];
				[self setToolbarItems:newItems];
				
				return;
			}
		}
	}
}
- (void)revertLoadingBarItem:(id) item 
{
	if(self.staticLeftNavBtn==item){
		[[self navigationItem] setLeftBarButtonItem:item];
	}
	else
	{
		NSMutableArray* newItems;
		NSInteger i;
		if( self.navigationItem.rightBarButtonItems.count>1){
			for(i=0;i<self.navigationItem.rightBarButtonItems.count;i++){
				if([self.staticRightNavBtns objectAtIndex:i] == item){
					newItems = [self.navigationItem.rightBarButtonItems.mutableCopy autorelease];
					[newItems replaceObjectAtIndex:i withObject:item];
					self.navigationItem.rightBarButtonItems=newItems;
					return;
				}
			}
		}else{
			if([self.staticRightNavBtns objectAtIndex:0] == item){
				self.navigationItem.rightBarButtonItem = item;
			}
		}
		for (i=0; i<staticToolBarItems.count; i++) {
			if([staticToolBarItems objectAtIndex:i] == item){
				newItems = [self.toolbarItems.mutableCopy autorelease];
				[newItems replaceObjectAtIndex:i withObject:item];
				[self setToolbarItems:newItems];
				return;
			}
		}
		//[newItems replaceObjectAtIndex:index withObject:[staticToolBarItems objectAtIndex:index]];
	}
}

@end

@implementation TableLoadingButtonCell
@synthesize progressTitle, title=_title, activityIndicator;
-(void)setTitle:(NSString *)title{
	self.textLabel.text=title;
	[_title autorelease];
	_title = [title retain];
}
-(void)dealloc{
	self.accessoryView=nil;
	self.progressTitle=nil;
	self.title=nil;
	self.activityIndicator=nil;
	[super dealloc];
}
+ (TableLoadingButtonCell*)newWithTitle:(NSString*)title Progress:(NSString*)progressTitle andIcon:(NSString *)iconName{
	TableLoadingButtonCell* cell = [TableLoadingButtonCell newWithTitle:title Progress:progressTitle];
	cell.imageView.image = [UIImage imageNamed:iconName];
	return cell;
}
+ (TableLoadingButtonCell*)newWithTitle:(NSString*)title Progress:(NSString*)progressTitle {
	TableLoadingButtonCell* cell =  [[TableLoadingButtonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TableLoadingButtonCell"];
	cell.progressTitle= progressTitle;
	cell.textLabel.textColor = [UISwitch appearance].onTintColor;
	cell.textLabel.text = cell.title = title;
	cell.textLabel.textAlignment = NSTextAlignmentCenter;
	cell.activityIndicator =[[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
	//cell.accessoryView =cell.activityIndicator;
	return cell;
}
-(void)showLoading{
	self.textLabel.text=self.progressTitle;
	self.textLabel.alpha = 0.439216f;
	self.userInteractionEnabled =  NO;
	self.accessoryView = self.activityIndicator;
	[(UIActivityIndicatorView*)self.accessoryView startAnimating];
}
-(void)revertLoading{
	self.textLabel.text=self.title;
	self.textLabel.alpha =1;
	self.userInteractionEnabled =  YES;
	[(UIActivityIndicatorView*)self.accessoryView stopAnimating];
	self.accessoryView=nil;
}

@end