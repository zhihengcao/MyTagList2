//
//  SnippetListViewController.h
//  MyTagList2
//
//  Created by cao on 9/24/13.
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#import "IASKPSTextFieldSpecifierViewCell.h"
#import "TableTBViewController.h"
#import "Tag.h"

typedef void (^scriptConfigDoneBlock_t)(NSString* name, NSArray* tagAssignments, NSArray* scheduleAssignments, NSArray* regions, NSArray* literals, NSArray* phones);
//typedef void (^dismissUIBlock_t)();
typedef void (^snippetChoiceDoneBlock_t)(NSDictionary* selectedSnippet);
typedef void (^downloadScriptLogBlock_t)(TableLoadingButtonCell* btn);

@interface SnippetListViewController : UITableViewController<UISearchResultsUpdating, UISearchBarDelegate>{
	NSArray* _snippets;
	NSMutableArray* _filteredSnippets;
	snippetChoiceDoneBlock_t _done;

/*	NSString		*savedSearchTerm;
	BOOL			searchWasActive;
	CGPoint			contentOffsetBeforeSearch;*/
}
@property (nonatomic, retain) NSArray *snippets;
//@property (nonatomic, copy) dismissUIBlock_t dismissUI;

- (id)initWithSnippets:(NSArray*) snippets Done:(snippetChoiceDoneBlock_t) done;
@property (strong, nonatomic) UISearchController *searchController;

@end

@protocol ScriptConfigViewControllerDelegate <NSObject>
@required
- (NSDictionary*)findTagFromUuid:(NSString*)uuid;
-(NSMutableArray*)listTagsWithTypes:(NSArray*) types excludingUuids:(NSArray*)uuids;
-(NSString*)listOnlyUuidOfTagWithTypes:(NSArray*) types; // returns nil if there is more than 1.
@end

@interface ScriptLogEntry : NSObject
{}
@property (nonatomic, retain) NSString* msg;
@property (nonatomic, retain) NSDate* time;
@property(nonatomic, assign) int type;
@end

@interface ScriptConfigViewController : UITableViewController <IEditableTableViewCellDelegate>{
	scriptConfigDoneBlock_t _done;
	downloadScriptLogBlock_t _downloadLog;
	IASKPSTextViewSpecifierViewCell* nameCell;
	TableLoadingButtonCell* downloadLogCell;
	NSUInteger currentEditSection;
	NSArray* day_of_week;
	NSDateFormatter* tod_f;
	CLGeocoder* geocoder;
	NSUInteger pCount, sCount, rCount, lCount;
}
@property (nonatomic, retain) NSArray *logs;

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSArray *placeHolders;
@property (nonatomic, retain) NSArray *schedules;
@property (nonatomic, retain) NSArray *regions;
@property (nonatomic, retain) NSArray *literals;
@property (nonatomic, retain) NSMutableArray *literalsCells;
@property (nonatomic, retain) NSArray *phones;   //
@property(nonatomic,assign) id<ScriptConfigViewControllerDelegate> delegate;

- (id)initWithName: (NSString*)name andLogs:(NSArray*)logs andPlaceHolders:(NSArray*) placeHolders andSchedules:(NSArray*) schedules
		andRegions:(NSArray*) regions andLiterals:(NSArray*)literals andPhones:(NSArray*)phones andDelegate:(id<ScriptConfigViewControllerDelegate>) delegate Done:(scriptConfigDoneBlock_t) done DonwloadLog:(downloadScriptLogBlock_t) downloadLog;

@end
