#import "WebViewController.h"


@implementation WebViewController

-(id)initWithTitle:(NSString*)title{
	self=[super init];
	if(self){
		self.navigationItem.title = title;
	}
	return self;
}

-(void)loadRequest:(NSURLRequest*) req WithCompletion:(void(^)())completion onClose:(void(^)(BOOL))onClosed{
	self.completion = completion;
	self.webviewClosed = onClosed;
	[self.webView loadRequest:req];
}
- (void)loadView
{
    CGRect screenFrame = self.navigationController.view.frame;   //[[UIScreen mainScreen] applicationFrame];

    UIWebView *wv = [[UIWebView alloc] initWithFrame:screenFrame];
    [wv setScalesPageToFit:YES];
    [wv setDelegate:self];
	
    [self setView:wv];
    [wv release];

	self.contentSizeForViewInPopover = CGSizeMake(480, 600);
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	self.navigationController.toolbarHidden=YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (UIWebView *)webView
{
    return (UIWebView *)[self view];
}
-(void)webViewDidFinishLoad:(UIWebView *)webView{
	[webView stringByEvaluatingJavaScriptFromString:@"history.back = function () { location.href = '//close.webview'; }"];
	if(self.completion)self.completion();
	self.completion=nil;
}
-(void)dealloc{
	self.completion=nil;
	self.webviewClosed=nil;
	[super dealloc];
}
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
	NSString* url =request.URL.absoluteString;
	NSLog(@"URL=%@", url);
	if([url rangeOfString:@"//close.webview"].length>0){
		[self.navigationController popViewControllerAnimated:YES];
		if(self.webviewClosed!=nil)
			self.webviewClosed(YES);
		return NO;
	}
	if([url rangeOfString:@"/eth/index.html"].length>0  && [url rangeOfString:@"#indexPage"].length>0 && [url rangeOfString:@"ui-state=dialog"].length==0){

		[self.navigationController popViewControllerAnimated:YES];
		if(self.webviewClosed!=nil)
			self.webviewClosed(NO);
		return NO;
	}
	return YES;
}

@end
