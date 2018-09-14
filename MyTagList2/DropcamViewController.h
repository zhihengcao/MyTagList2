//
//  DropcamViewController.h
//  MyTagList2
//
//  Created by cao on 10/31/14.
//
//

#import <UIKit/UIKit.h>
#import "TableTBViewController.h"
#import "EventsViewController.h"
#import "AsyncURLConnection.h"
#import "ActionSheet+Blocks.h"
#import "WebImageOperations.h"
#import "iToast.h"
#import <MediaPlayer/MediaPlayer.h>

@interface NSString (Shots)
-(int64_t) filetime;
-(NSDate*)nsdate;
@end

@class DropcamViewController;
//typedef void (^downloadShotsBlock_t)(DropcamViewController* ui, int64_t olderThan, int topN);
//typedef void (^downloadNewShotsBlock_t)(DropcamViewController* ui, int64_t newerThan);

// right button: record video
// section 0: install kumoapp, stream on, stream off, make time lapse, snapshot, unassociate
@interface DropcamViewController : TableTBViewController<UISearchDisplayDelegate, UISearchBarDelegate>{
	
	NSMutableArray* _shots;
	NSMutableArray* _dates;  // section headers
	TableLoadingButtonCell* snapshotCell, *recordVideoCell, *timeLapseCell;

	BOOL			_runLoader;
	int64_t			_olderThan;
}
-(NSString*)xSetMac;

@property(nonatomic, retain)NSString* timeLapseFn;
@property (nonatomic, retain) NSMutableDictionary* tag;
//@property (nonatomic, copy) downloadShotsBlock_t loader;
//@property (nonatomic, copy) downloadNewShotsBlock_t newLoader;

//- (id)initForTag:(NSMutableDictionary*) tag withLoader:(downloadShotsBlock_t) loader andNewLoader:(downloadNewShotsBlock_t)newLoader;
- (id)initForTag:(NSMutableDictionary*) tag;
-(void) append:(NSArray*)snapshots;
-(void)prepend:(NSArray *)snapshots;
-(void)reload;
-(void)updateTag:(NSMutableDictionary*)tag;
@end

