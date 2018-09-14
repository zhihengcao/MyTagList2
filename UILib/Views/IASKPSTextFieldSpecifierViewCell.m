//
//  IASKPSTextFieldSpecifierViewCell.m
//  http://www.inappsettingskit.com
//
//  Copyright (c) 2009-2010:
//  Luc Vandal, Edovia Inc., http://www.edovia.com
//  Ortwin Gentz, FutureTap GmbH, http://www.futuretap.com
//  All rights reserved.
// 
//  It is appreciated but not required that you give credit to Luc Vandal and Ortwin Gentz, 
//  as the original authors of this code. You can give credit in a blog post, a tweet or on 
//  a info page of your app. Also, the original authors appreciate letting them know if you use this code.
//
//  This code is licensed under the BSD license that is available at: http://www.opensource.org/licenses/bsd-license.php
//

#import "IASKPSTextFieldSpecifierViewCell.h"
#import "IASKTextField.h"
#import "MasterViewController.h"

@interface UIPlaceHolderTextView ()

@property (nonatomic, retain) UILabel *placeHolderLabel;

@end

@implementation UIPlaceHolderTextView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#if __has_feature(objc_arc)
#else
    [_placeHolderLabel release]; _placeHolderLabel = nil;
    [_placeholderColor release]; _placeholderColor = nil;
    [_placeholder release]; _placeholder = nil;
    [super dealloc];
#endif
}

- (void)awakeFromNib
{
    [super awakeFromNib];
	
    // Use Interface Builder User Defined Runtime Attributes to set
    // placeholder and placeholderColor in Interface Builder.
    if (!self.placeholder) {
        [self setPlaceholder:@""];
    }
	
    if (!self.placeholderColor) {
        [self setPlaceholderColor:[UIColor lightGrayColor]];
    }
	
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextViewTextDidChangeNotification object:nil];
}

- (id)initWithFrame:(CGRect)frame
{
    if( (self = [super initWithFrame:frame]) )
    {
        [self setPlaceholder:@""];
        [self setPlaceholderColor:[UIColor lightGrayColor]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextViewTextDidChangeNotification object:nil];
    }
    return self;
}

- (void)textChanged:(NSNotification *)notification
{
    if([[self placeholder] length] == 0)
    {
        return;
    }
	
    if([[self text] length] == 0)
    {
        [[self viewWithTag:999] setAlpha:1];
    }
    else
    {
        [[self viewWithTag:999] setAlpha:0];
    }
}

- (void)setText:(NSString *)text {
    [super setText:text];
    [self textChanged:nil];
}

- (void)drawRect:(CGRect)rect
{
    if( [[self placeholder] length] > 0 )
    {
        if (_placeHolderLabel == nil )
        {
            _placeHolderLabel = [[UILabel alloc] initWithFrame:CGRectMake(8,8,self.bounds.size.width - 16,0)];
            _placeHolderLabel.lineBreakMode = NSLineBreakByWordWrapping;
            _placeHolderLabel.numberOfLines = 0;
            _placeHolderLabel.font = self.font;
            _placeHolderLabel.backgroundColor = [UIColor clearColor];
            _placeHolderLabel.textColor = self.placeholderColor;
            _placeHolderLabel.alpha = 0;
            _placeHolderLabel.tag = 999;
            [self addSubview:_placeHolderLabel];
        }
		
        _placeHolderLabel.text = self.placeholder;
        [_placeHolderLabel sizeToFit];
        [self sendSubviewToBack:_placeHolderLabel];
    }
	
    if( [[self text] length] == 0 && [[self placeholder] length] > 0 )
    {
        [[self viewWithTag:999] setAlpha:1];
    }
	
    [super drawRect:rect];
}

@end

@implementation IASKPSTextViewSpecifierViewCell

+ (IASKPSTextViewSpecifierViewCell*) newEditableWithText:(NSString*)value delegate:(id<IEditableTableViewCellDelegate>)delegate{
	IASKPSTextViewSpecifierViewCell* cell =
	(IASKPSTextViewSpecifierViewCell*) [[[NSBundle mainBundle] loadNibNamed:@"IASKPSTextViewSpecifierViewCell" owner:delegate
																	options:nil] objectAtIndex:0];
	cell.textField.text=value;
	cell.textField.textColor = [UIColor blackColor];
	cell.delegate=delegate;
	return [cell retain];
}

+ (IASKPSTextViewSpecifierViewCell*) newEditableWithPlaceholder:(NSString*)title delegate:(id<IEditableTableViewCellDelegate>)delegate{
	IASKPSTextViewSpecifierViewCell* cell =
	(IASKPSTextViewSpecifierViewCell*) [[[NSBundle mainBundle] loadNibNamed:@"IASKPSTextViewSpecifierViewCell" owner:delegate
																	 options:nil] objectAtIndex:0];
	cell.textField.placeholder = title;
	cell.textField.textColor = [UIColor blackColor];
	cell.delegate=delegate;
	return [cell retain];	
}

- (void)textViewDidChange:(UITextView *)textView{
	if(_delegate!=nil && [_delegate respondsToSelector:@selector(editedTableViewCell:)])
		[_delegate editedTableViewCell:self];
}

@end

@implementation IASKPSTextFieldSpecifierViewCell
//@synthesize rightImageView = _rightImageView;

@synthesize label=_label, textField=_textField, delegate=_delegate;

NSString* name = @"IASKPSTextFieldSpecifierViewCell";
NSString* name2 = @"IASKPSTextFieldSpecifierViewCell2";

+ (IASKPSTextFieldSpecifierViewCell*)newReadonlyWithTitle:(NSString*)title{
	return [IASKPSTextFieldSpecifierViewCell newReadonlyWithTitle:title andIcon:nil];
}
+ (IASKPSTextFieldSpecifierViewCell*)newReadonlyWithTitle:(NSString*)title andIcon:(NSString *)iconName
{	
	IASKPSTextFieldSpecifierViewCell* cell =  
		(IASKPSTextFieldSpecifierViewCell*) [[[NSBundle mainBundle] loadNibNamed:name
																		   owner:nil
																		 options:nil] objectAtIndex:0];
	cell.textField.userInteractionEnabled = NO;
	cell.textField.textColor=[UIColor darkGrayColor];
	cell.label.text = title;
	cell.accessoryType = UITableViewCellAccessoryNone;
	if(iconName) cell.iconImage.image = [UIImage imageNamed:iconName];
	return [cell retain];
}

+ (IASKPSTextFieldSpecifierViewCell*) newMultipleChoiceWithTitle:(NSString*)title{
	return [IASKPSTextFieldSpecifierViewCell newMultipleChoiceWithTitle:title andIcon:nil];
}
+ (IASKPSTextFieldSpecifierViewCell*) newMultipleChoiceWithTitle:(NSString*)title andIcon:(NSString*)iconName
{	
	IASKPSTextFieldSpecifierViewCell* cell=	(IASKPSTextFieldSpecifierViewCell*) [[[NSBundle mainBundle] loadNibNamed:name owner:nil
																		 options:nil] objectAtIndex:0];
	cell.textField.userInteractionEnabled = NO;
	cell.label.text = title;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	if(iconName) cell.iconImage.image = [UIImage imageNamed:iconName];
	return [cell retain];
}

-(void)addSwatch:(NSString*)swatch animated:(BOOL)animated{
	if(swatch==nil){
		self.gradient.hidden=YES;
		self.textField.textColor= 		[UIColor colorWithRed:(float)0x30/255.0 green:(float)0xa7/255.0 blue:(float)0xfc/255.0 alpha:1.0];
		return;
	};
	if(self.gradient==nil){
		//UIView *bgview = [[[UIView alloc] initWithFrame:self.bounds] autorelease];
		self.gradient = [CAGradientLayer layer];
		//self.gradient.frame = self.bounds;
		self.gradient.startPoint=CGPointMake(1.0f, 1.0f);
		self.gradient.endPoint=CGPointMake(0.2f, 1.0f);
		[self.layer insertSublayer:self.gradient atIndex:0];
		//self.gradient.locations=@[];
		//self.backgroundView=bgview;
	}
	self.gradient.hidden=NO;
	CGFloat hue, sat, brightness, alpha;
	[[TagTableViewCell bgColorForSwatch:swatch andAlpha:1.0f] getHue:&hue saturation:&sat brightness:&brightness alpha:&alpha];
	
	if(animated){
		[CATransaction begin];
		[CATransaction setAnimationDuration:1.4f];
	}
	self.gradient.colors = @[(id)[[UIColor colorWithHue:hue saturation:sat brightness:brightness alpha:alpha] CGColor],
							 (id)[[UIColor colorWithHue:hue saturation:sat brightness:brightness*1.2f alpha:alpha] CGColor],
							 (id)[[UIColor colorWithHue:hue saturation:sat brightness:brightness*1.6f alpha:alpha] CGColor],
							 (id)[UIColor whiteColor].CGColor];
	if(animated){

/*		[UIView transitionWithView:self.textField duration:2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
			self.textField.textColor = [TagTableViewCell fgColorForSwatch:swatch andAlpha:1.0f];
		} completion:^(BOOL finished) {
		}];
*/
		self.textField.textColor = [TagTableViewCell fgColorForSwatch:swatch andAlpha:1.0f];
		[CATransaction commit];
	}else{
		self.textField.textColor = [TagTableViewCell fgColorForSwatch:swatch andAlpha:1.0f];
	}
}
-(void)showLoading{
//	self.label.alpha = self.textLabel.alpha = 0.439216f;
	self.userInteractionEnabled =  NO;
	self.accessoryView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
	[(UIActivityIndicatorView*)self.accessoryView startAnimating];
}
-(void)revertLoading{
//	self.label.alpha = self.textLabel.alpha =1;
	self.userInteractionEnabled =  YES;
	[(UIActivityIndicatorView*)self.accessoryView stopAnimating];
	self.accessoryView = nil;
	self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

+ (IASKPSTextFieldSpecifierViewCell*) newEditableWithPlaceholder:(NSString*)title isLast:(BOOL)isLast delegate:(id<IEditableTableViewCellDelegate>)delegate
{
	IASKPSTextFieldSpecifierViewCell* cell =  
	(IASKPSTextFieldSpecifierViewCell*) [[[NSBundle mainBundle] loadNibNamed:name2 owner:delegate 
																	 options:nil] objectAtIndex:0];
	cell.textField.placeholder = title;
	cell.textField.textColor = [UISwitch appearance].onTintColor; //[UIColor blackColor];
	cell.textField.returnKeyType = isLast ? UIReturnKeyDone : UIReturnKeyNext;
	cell.textField.autoresizingMask=0; //UIViewAutoresizingFlexibleWidth;
	cell.delegate=delegate;
	return [cell retain];
}

+ (IASKPSTextFieldSpecifierViewCell*) newEditableWithTitle:(NSString*)title delegate:(id<IEditableTableViewCellDelegate>)delegate
{	
	IASKPSTextFieldSpecifierViewCell* cell =  
	(IASKPSTextFieldSpecifierViewCell*) [[[NSBundle mainBundle] loadNibNamed:name owner:delegate 
																	 options:nil] objectAtIndex:0];
	cell.label.text = title;
	cell.textField.textColor =  [UISwitch appearance].onTintColor; //[UIColor blackColor];
	cell.textField.returnKeyType = UIReturnKeyDone;
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.delegate=delegate;
	return [cell retain];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	self.gradient.frame=self.bounds;

	if(self.iconImage!=nil && self.iconImage.image==nil){
		CGRect f = _label.frame; f.origin.x=13;  _label.frame=f;
	}

	CGSize labelSize = [_label sizeThatFits:CGSizeZero];
	labelSize.width = MIN(labelSize.width, _label.bounds.size.width);

	CGRect textFieldFrame = _textField.frame;
	textFieldFrame.origin.x = _label.frame.origin.x + MAX(kIASKMinLabelWidth, labelSize.width) + kIASKSpacing;
	if (!_label.text.length)
		textFieldFrame.origin.x = _label.frame.origin.x;
	textFieldFrame.size.width = _textField.superview.frame.size.width - textFieldFrame.origin.x - (self.accessoryType==UITableViewCellAccessoryNone?5:0); // - _label.frame.origin.x;
	_textField.frame = textFieldFrame;

/*	if(self.iconImage!=nil && self.iconImage.image==nil){
		CGRect f = _label.frame; f.size.width=_label.superview.bounds.size.width- _textField.frame.origin.x; _label.frame=f;
	}
*/
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)dealloc {
//    [_rightImageView release];
    [_iconImage release];
	self.gradient=nil;
    [super dealloc];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    // only when adding on the end of textfield && it's a space
    if (range.location == textField.text.length && [string isEqualToString:@" "]) {
        // ignore replacement string and add your own
        textField.text = [textField.text stringByAppendingString:@"\u00a0"];
        return NO;
    }
    // for all other cases, proceed with replacement
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if(_delegate!=nil && [_delegate respondsToSelector:@selector(validateTableViewCellEntry:)]){
		if([_delegate validateTableViewCellEntry:self]){
			[textField resignFirstResponder]; return YES;			
		}else
			return NO;
	}else{
		[textField resignFirstResponder]; return YES;
	}
}

- (IBAction)editingDidEnd:(id)sender {
	self.textField.text = [self.textField.text stringByReplacingOccurrencesOfString:@"\u00a0" withString:@" "];
	if(_delegate!=nil && [_delegate respondsToSelector:@selector(editedTableViewCell:)])
		[_delegate editedTableViewCell:self];
}
@end
