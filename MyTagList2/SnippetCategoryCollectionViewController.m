//
//  SnippetCategoryCollectionViewController.m
//  MyTagList2
//
//  Created by cao on 4/5/16.
//
//

#import "SnippetCategoryCollectionViewController.h"

@implementation SnippetCategoryCell
@synthesize imageView=_imageView, titleView=_titleView, activityIndicator=_activityIndicator;
- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		self.backgroundColor = [UIColor clearColor];
		self.activityIndicator = [[[UIActivityIndicatorView alloc]initWithFrame:self.bounds] autorelease];
		self.activityIndicator.hidden=YES;
		
		if(self.bounds.size.width > self.bounds.size.height){
			self.titleView = [[[UILabel alloc]initWithFrame:self.bounds] autorelease];
		}else{
			self.imageView = [[[UIImageView alloc] initWithFrame:CGRectMake(0,0,self.bounds.size.width, self.bounds.size.width-40)] autorelease];
			_imageView.contentMode = UIViewContentModeScaleAspectFit;
			_imageView.alpha = 0.75f;
			_imageView.bounds = CGRectInset(_imageView.frame, 25, 5);
			
			_imageView.layer.shadowColor = [UIColor blackColor].CGColor;
			_imageView.layer.shadowRadius = 3.0f;
			_imageView.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
			_imageView.layer.shadowOpacity = 0.5f;
			
			_imageView.clipsToBounds = NO;
			[self.contentView addSubview:self.imageView];
			
			self.titleView = [[[UILabel alloc]initWithFrame:CGRectMake(0, self.bounds.size.width-38, self.bounds.size.width, self.bounds.size.height-self.bounds.size.width+38)] autorelease];
		}
		//_titleView.textColor = [UIColor colorWithRed:(float)0x30/255.0 green:(float)0xa7/255.0 blue:(float)0xfc/255.0 alpha:1.0];
		_titleView.font = [UIFont systemFontOfSize:13];
		_titleView.textAlignment = NSTextAlignmentCenter;
		_titleView.lineBreakMode =NSLineBreakByWordWrapping;
		_titleView.numberOfLines = 0;
		[self.contentView addSubview:_titleView];
		
		[self.contentView addSubview:_activityIndicator];
	}
	
	return self;
}
-(void)showLoading{
	self.contentView.alpha = 0.439216f;
	self.userInteractionEnabled =  NO;
	_activityIndicator.hidden=NO;
	[_activityIndicator startAnimating];
}
-(void)revertLoading{

	self.contentView.alpha =1;
	self.userInteractionEnabled =  YES;
	[_activityIndicator stopAnimating];
	_activityIndicator.hidden=YES;
}
-(void)dealloc{
	self.activityIndicator=nil;
	self.imageView=nil;
	self.titleView=nil;
	[super dealloc];
}
@end
@implementation SnippetCategoryCollectionViewController
@synthesize categoryIcons=_categoryIcons, titleTexts=_titleTexts, done=_done;

static NSString * const reuseIdentifier = @"CategoryCell";

-(id)initWithDoneBlock:(categoryPickerDoneBlock_t)done{
	/*UICollectionViewFlowLayout *aFlowLayout = [[[UICollectionViewFlowLayout alloc] init] autorelease];
	[aFlowLayout setItemSize:CGSizeMake(100, 130)];
	[aFlowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
	self = [super initWithCollectionViewLayout:aFlowLayout];*/
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
		self=[super initWithNibName:@"SnippetCategoryCollectionViewController" bundle:nil];
	else
		self=[super initWithNibName:@"SnippetCategoryCollectionViewController_iPad" bundle:nil];
	
	if(self){
		self.done=done;
	}
	return self;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{

	CGSize defaultSize = [(UICollectionViewFlowLayout*)collectionViewLayout itemSize];

	if(indexPath.row==9){
		return CGSizeMake(self.collectionView.bounds.size.width- ((UICollectionViewFlowLayout*)collectionViewLayout).minimumInteritemSpacing*2, 40);
	}else{
		return defaultSize;
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = @"What do you want to do?";
	
	self.collectionView.backgroundColor= [UIColor whiteColor]; //[UIColor groupTableViewBackgroundColor];
	[self.collectionView registerClass:[SnippetCategoryCell class] forCellWithReuseIdentifier:reuseIdentifier];
	
	self.categoryIcons = [NSArray arrayWithObjects:
						  [UIImage imageNamed:@"ka_location.png"],
						  [UIImage imageNamed:@"ka_users.png"],
						  [UIImage imageNamed:@"ka_leaf.png"],
						  [UIImage imageNamed:@"ka_temperature.png"],
						  [UIImage imageNamed:@"ka_scheduling.png"],
						  [UIImage imageNamed:@"ka_dropcam.png"],
						  [UIImage imageNamed:@"ka_log.png"],
						  [UIImage imageNamed:@"ka_bell.png"],
						  [UIImage imageNamed:@"ka_wemo.png"],nil];
	
	self.titleTexts = @[@"Save energy using your iPhone location",
						@"Arm/disarm if someone’s at home",
						@"Save energy using motion sensors",
						@"Optimize room temperature using tag/sensor",
						@"Advanced scheduling",
						@"Control your Dropcam using tag events",
						@"Log & download advanced tag/sensor data",
						@"Special ways of getting notified of events",
						@"Be the master of lights...",
						@"Search all apps..."
						];
	
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
}
- (void)viewDidUnload
{
	[super viewDidUnload];
	self.categoryIcons=nil;
}
-(void)viewWillAppear:(BOOL)animated{
	[UIView animateWithDuration:0.25f animations:^{
		self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:(float)0x6a/(float)0xff green:(float)0xba/(float)0xff
																				blue:(float)0x2f/(float)0xff alpha:1];
		[self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:UITextAttributeTextColor]];
		self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
	} completion:^(BOOL finished) {
	}];
	
	[super viewWillAppear:animated];
}
-(void)viewDidAppear:(BOOL)animated{
	[super viewDidAppear:animated];
	self.navigationController.toolbarHidden=YES;
	
}
-(void)dealloc{
	self.categoryIcons=nil;
	self.done=nil;
	self.titleTexts=nil;
	[super dealloc];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark <UICollectionViewDataSource>

/*- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}*/

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 10;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	SnippetCategoryCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];

	if(indexPath.row < _categoryIcons.count)
		cell.imageView.image = [_categoryIcons objectAtIndex:indexPath.row];
	else
		cell.imageView.image=nil;
	
	cell.titleView.text = [_titleTexts objectAtIndex:indexPath.row];
    return cell;
}

#pragma mark <UICollectionViewDelegate>

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	self.done( indexPath.row==9? 0: 10*(indexPath.row+1),[_titleTexts objectAtIndex:indexPath.row]
			  , (SnippetCategoryCell*)[self.collectionView cellForItemAtIndexPath:indexPath]);
}

// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

@end
