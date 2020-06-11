#import <UIKit/UIKit.h>
#import "MasterViewController.h"
#import "TrendTableViewController.h"

extern int64_t getfiletime();
#include <sys/time.h>
#define EPOCH_DIFF 11644473600LL

@class EventsViewController;
typedef void (^downloadEventsBlock_t)(EventsViewController* ui, int64_t olderThan, int topN);
typedef void (^downloadNewEventsBlock_t)(EventsViewController* ui, int64_t newerThan);

@interface EventsViewController : UITableViewController<UISearchResultsUpdating, UISearchBarDelegate>{
	
	NSMutableArray* _events;
	NSMutableArray* _filteredEvents;
	NSMutableArray* _dates;  // section headers
	
	BOOL			runLoader;
//	BOOL			searchWasActive;
//	CGPoint			contentOffsetBeforeSearch;
	int64_t			olderThan;
}
@property (nonatomic, assign) TopPagingViewController* topPVC;
@property (nonatomic, retain) 	NSString		*savedSearchTerm;

@property (nonatomic, copy) downloadEventsBlock_t loader;
@property (nonatomic, copy) downloadNewEventsBlock_t newLoader;
@property (nonatomic, retain) NSMutableDictionary *uuid2events;

- (id)initWithLoader:(downloadEventsBlock_t) loader andNewLoader:(downloadNewEventsBlock_t)newLoader;
-(void) appendEvents:(NSArray*)events1D;
-(void)prependEvents:(NSArray *)events1D;
-(void)reload;
-(void)refresh;
-(void)removeEvents;
@end

@interface HeaderLabel: UILabel
@end

@interface TopPagingViewController : UIPageViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate>
{
	BOOL swipingToTVC;
}
-(void)restorePreviousPage;
//-(void)openMvcNoAnimation;
-(id)initWithMvc:(MasterViewController*)mvc andEvc:(EventsViewController*)evc andTvc:(TrendTableViewController*)tvc;
@property(nonatomic) 	NSInteger     savedSearchScopeEvc;
@property(nonatomic) 	NSInteger     savedSearchScopeMvc;
@property (nonatomic, retain) UIPageControl* pcDots;
@property (nonatomic, retain) MasterViewController* mvc;
@property (nonatomic, retain)	 EventsViewController* evc;
@property (nonatomic, retain) TrendTableViewController* tvc;
@property (nonatomic, retain) UIBarButtonItem* mvc_left, *mvc_right, *evc_left, *evc_right, *tvc_left, *tvc_right;
@property (nonatomic, readonly)BOOL isTagManagerChoiceVisible;
@property (nonatomic, readonly)BOOL isMVCVisible;

@property (strong, nonatomic) UISearchController *searchController;

@end

