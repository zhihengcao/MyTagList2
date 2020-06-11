#import <Foundation/Foundation.h>
#import <Webkit/Webkit.h>

@interface WebViewController : UIViewController<WKNavigationDelegate>
{
}

-(id)initWithTitle:(NSString*)title;
@property (nonatomic, readonly) WKWebView *webView;
@property(nonatomic, copy) void (^completion)();
@property(nonatomic, copy) void (^webviewClosed)(BOOL cancelled);

-(void)loadRequest:(NSURLRequest*) req WithCompletion:(void(^)())completion onClose:(void(^)(BOOL))onClosed;

@end
