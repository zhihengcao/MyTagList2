#import "WebViewController.h"
#import <Webkit/Webkit.h>


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

    WKWebView *wv = [[WKWebView alloc] initWithFrame:screenFrame];
	wv.navigationDelegate = self;
    //[wv setScalesPageToFit:YES];
    //[wv setDelegate:self];

	if (@available(iOS 11.0, *)) {
		for(NSHTTPCookie* cookie in NSHTTPCookieStorage.sharedHTTPCookieStorage.cookies){
			[wv.configuration.websiteDataStore.httpCookieStore setCookie:cookie completionHandler:nil];
		}
	}
    [self setView:wv];


	[wv release];

	//self.preferredContentSize = CGSizeMake(480, 600);
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

- (WKWebView *)webView
{
    return (WKWebView *)[self view];
}
-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{

	[webView evaluateJavaScript:@"history.back = function () { location.href = '//close.webview'; }" completionHandler:nil];
	if(self.completion)self.completion();
	self.completion=nil;
}
-(void)dealloc{
	self.completion=nil;
	self.webviewClosed=nil;
	[super dealloc];
}
-(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
	NSString* url =navigationAction.request.URL.absoluteString;
	NSLog(@"URL=%@", url);
	if([url rangeOfString:@"//close.webview"].length>0){
		[self.navigationController popViewControllerAnimated:YES];
		if(self.webviewClosed!=nil)
			self.webviewClosed(YES);
		//return NO;
		decisionHandler( WKNavigationActionPolicyCancel);
		return;
	}
	if([url rangeOfString:@"ifttt.com"].length>0){
		decisionHandler( WKNavigationActionPolicyAllow);
		return;
	}
	
	if([url rangeOfString:@"/eth/index.html"].length>0  && [url rangeOfString:@"#indexPage"].length>0 && [url rangeOfString:@"ui-state=dialog"].length==0){

		[self.navigationController popViewControllerAnimated:YES];
		if(self.webviewClosed!=nil)
			self.webviewClosed(NO);
		decisionHandler( WKNavigationActionPolicyCancel);
		return;
	}
	decisionHandler( WKNavigationActionPolicyAllow);
	return;
}

@end
