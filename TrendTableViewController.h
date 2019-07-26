//
//  TrendTableViewController.h
//  WirelessTag
//
//  Created by cao on 3/21/19.
//

#import <UIKit/UIKit.h>
#import "MasterViewController.h"
#import "TrendTableViewCell.h"
#import "Tag.h"
#import "AsyncURLConnection.h"
#import "MultiSelectSegmentedControl.h"

@interface TrendTableViewController : UITableViewController <UISearchDisplayDelegate, UISearchBarDelegate, MultiSelectSegmentedControlDelegate>
{
	BOOL 		reloadPending;
	BOOL			searchWasActive;
	CGPoint			contentOffsetBeforeSearch;
	BOOL   useDegF;
	AsyncSoapURLConnection* comet;
	BOOL should_run_comet;
	MultiSelectSegmentedControl *segmentedControl;
//	int nCellLaied
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil delegate: (id<MasterViewControllerDelegate>) delegate;


@property (nonatomic, retain) UIBarButtonItem* reorderBtn;
@property (nonatomic, retain) UIBarButtonItem* reorderDoneBtn;
@property (nonatomic, assign)TopPagingViewController* topPVC;

@property(nonatomic,assign) id<MasterViewControllerDelegate> delegate;
@property (nonatomic, retain) 	NSString		*savedSearchTerm;

@property (nonatomic, retain) NSMutableDictionary *pb2span;
@property (nonatomic, retain) NSMutableDictionary *uuid2events;

@property (nonatomic, retain) NSMutableArray *trendList;
@property (nonatomic, retain) NSMutableArray *filteredTrendList;

-(void)removeData;

-(void)reload;
@end
