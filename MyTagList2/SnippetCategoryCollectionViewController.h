//
//  SnippetCategoryCollectionViewController.h
//  MyTagList2
//
//  Created by cao on 4/5/16.
//
//

#import <UIKit/UIKit.h>


@interface SnippetCategoryCell : UICollectionViewCell
@property (nonatomic, strong, readwrite) UIImageView *imageView;
@property(nonatomic,retain)UILabel* titleView;
@property(nonatomic,retain)UIActivityIndicatorView* activityIndicator;
-(void)showLoading;
-(void)revertLoading;

@end

typedef void (^categoryPickerDoneBlock_t)(NSInteger selected, NSString* name, SnippetCategoryCell* sender);

@interface SnippetCategoryCollectionViewController : UICollectionViewController<UICollectionViewDelegateFlowLayout>
@property (nonatomic, retain) NSArray* categoryIcons, *titleTexts;
@property(nonatomic,copy)categoryPickerDoneBlock_t done;

- (id)initWithDoneBlock:(categoryPickerDoneBlock_t) done;

@end
