#import "OptionPicker.h"

@implementation OptionPicker

@synthesize selected, selectedMulti=_selectedMult;
@synthesize nowOption=_nowOption, dismissUI=_dismissUI, doneBtn=_doneBtn, options=_options, nowOptions=_nowOptions;

- (id)initWithOptions:(NSArray*) options Selected:(NSInteger) s Now:(NSString*) now Done:(doneBlock_t)done
{
	self=[self initWithOptions:options Selected:s Done:done];
	self.nowOption = now;
	return self;
}
- (id)initWithOptions:(NSArray*) options Selected:(NSInteger) s Now:(NSString*) now Done:(doneBlock_t)done helpText:(NSString *)helpText
{
    self=[self initWithOptions:options Selected:s Done:done helpText:helpText];
    self.nowOption = now;
    return self;
}

- (id)initWithOptions:(NSArray*) options Selected:(NSInteger) s Now:(NSString*) now nowOptions:(NSArray*) nowOptions Done:(doneBlock_t)done
{
	self=[self initWithOptions:options Selected:s Done:done];
	self.nowOption = now;
	self.nowOptions = nowOptions;
	return self;
}
- (id)initWithOptions:(NSArray*) options Selected:(NSInteger) s Now:(NSString*) now nowOptions:(NSArray*) nowOptions Done:(doneBlock_t)done helpText:(NSString *)helpText
{
    self=[self initWithOptions:options Selected:s Done:done helpText:helpText];
    self.nowOption = now;
    self.nowOptions = nowOptions;
    return self;
}


- (id)initWithOptionGen:(generateChoicesBlock_t) optionGen Selected:(NSInteger) s Done:(doneBlock_t)done
{
	self = [super initWithStyle:UITableViewStyleGrouped];
	if(self){
		_done=[done copy];
		_doneMulti=nil;
		_options=nil; _optionGen = [optionGen copy];
		_selected = s;
		self.selectedMulti=nil;
		self.doneBtn=nil;
		self.helpText=nil;
	}
	return self;
}
- (id)initWithOptionGen:(generateChoicesBlock_t) optionGen Selected:(NSInteger) s Done:(doneBlock_t)done helpText:(NSString *)helpText
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if(self){
        _done=[done copy];
        _doneMulti=nil;
        _options=nil; _optionGen = [optionGen copy];
        _selected = s;
        self.selectedMulti=nil;
        self.doneBtn=nil;
        self.helpText=helpText;
    }
    return self;
}


- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
	return self.helpText;
}

- (id)initWithOptions:(NSArray*) options selectedMulti:(NSMutableSet*) s doneMulti:(doneBlockMulti_t)done
{
	self = [super initWithStyle:UITableViewStyleGrouped];
	if(self){
		_doneMulti=[done copy];
		_done=nil;
		self.selectedMulti = s;
		_options=options; [_options retain];
	}
	return self;
}
- (id)initWithOptions:(NSArray*) options selectedMulti:(NSMutableSet*) s doneMulti:(doneBlockMulti_t)done helpText:(NSString *)helpText
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if(self){
        _doneMulti=[done copy];
        _done=nil;
        self.selectedMulti = s;
        _options=options; [_options retain];
        self.helpText=helpText;
    }
    return self;
}
- (id)initWithOptions:(NSArray*) options Selected:(NSInteger) s Done:(doneBlock_t)done
{
	self = [super initWithStyle:UITableViewStylePlain];
	if(self){
		_done=[done copy];
		_selected = s;
		_options=options; [_options retain];
		_helpText=nil;
	}
	return self;
}

- (id)initWithOptions:(NSArray*) options Selected:(NSInteger) s Done:(doneBlock_t)done helpText:(NSString*)helpText
{
	self = [super initWithStyle:UITableViewStyleGrouped];
	if(self){
		_done=[done copy];
		_selected = s;
		_options=options; [_options retain];
		self.helpText=helpText;
	}
	
	return self;
}
- (void)dealloc
{
	[_done release];
	[_doneMulti release];
	[_nowOption release];
    [_options release];
	[_nowOptions release];
	[_selectedMult release];
	[_doneBtn release];
	self.dismissUI=nil;
	self.helpText=nil;
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	// Return YES for supported orientations
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
	} else {
		return YES;
	}
}

-(void) setOptions:(NSArray *)options{
	[_options autorelease];
	_options = options;
	[_options retain];
	[[self tableView] reloadData];
}
-(NSArray*) options{
	return _options;
}

-(void)viewDidLoad{
	[super viewDidLoad];

	if(_selectedMult!=nil){
		_doneBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneBtnPressed:)];
		self.navigationItem.rightBarButtonItem = _doneBtn;
		if(_selectedMult.count==0)_doneBtn.enabled=NO;
	}
	[self.tableView reloadData];
	CGFloat height = [super tableView:self.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]*_options.count;
	self.preferredContentSize = CGSizeMake(350, height>600?600:height);
}
- (void)doneBtnPressed:(id)sender{
	//_dismissUI();
	_doneMulti(_selectedMult, self);
}
-(void)viewWillAppear:(BOOL)animated{
	if(_optionGen!=nil){
		self.options = _optionGen();
	}
	[self.tableView reloadData];
	[super viewWillAppear:animated];
}
- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	self.navigationController.toolbarHidden=YES;
}

- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section
{
    return [_options count] + (_nowOption?1:0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)ip
{    
    UITableViewCell *cell = 
    [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                       reuseIdentifier:@"UITableViewCell"] 
                autorelease];
    }

	NSInteger optionIndex=[ip row];
	if(_nowOption){
		optionIndex--;
		if([ip row]==0)
			[[cell textLabel] setText:_nowOption];
		else
			[[cell textLabel] setText:[[_options objectAtIndex:optionIndex] description]];
	}else	
		[[cell textLabel] setText:[[_options objectAtIndex:optionIndex] description]];
    
	if(_selectedMult==nil){
		if ((optionIndex==0 && _optionGen!=nil) || (_optionGen==nil && optionIndex == _selected)) {
			[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
		} else {
			[cell setAccessoryType:UITableViewCellAccessoryNone];
		}
    }else{
		NSNumber* ipv =[NSNumber numberWithInt:(int)[ip row]];
		if([_selectedMult containsObject:ipv])
			[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
		else
			[cell setAccessoryType:UITableViewCellAccessoryNone];
	}
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)ip
{
	NSInteger optionIndex = [ip row];
    if(_nowOption){
		optionIndex--;
		if(optionIndex==-1){
			_done(-1, YES);
			_dismissUI(YES);
			return;
		}
	}
	if(_nowOptions){
		for(NSNumber* now in _nowOptions){
			if([now intValue]==optionIndex){
				_dismissUI(NO);
				_done(optionIndex,NO);
				return;
			}
		}
	}
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:ip];
	if(_selectedMult==nil){
		[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
		_selected=[ip row];
		_dismissUI(YES);
		_done(optionIndex,NO);
	}else{
		[tableView deselectRowAtIndexPath:ip animated:YES];

		NSNumber* ipv =[NSNumber numberWithInt:(int)[ip row]];
		if([_selectedMult containsObject:ipv]){
			[_selectedMult removeObject:ipv];
			[cell setAccessoryType:UITableViewCellAccessoryNone];
			if(_selectedMult.count==0)_doneBtn.enabled=NO;

		}else{
			[_selectedMult addObject:ipv];
			[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
			_doneBtn.enabled=YES;
		}
	}
}
@end
