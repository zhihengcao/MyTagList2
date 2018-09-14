#import <Foundation/Foundation.h>


@interface WebViewController : UIViewController<UIWebViewDelegate>
{
}

-(id)initWithTitle:(NSString*)title;
@property (nonatomic, readonly) UIWebView *webView;
@property(nonatomic, copy) void (^completion)();
@property(nonatomic, copy) void (^webviewClosed)(BOOL cancelled);

-(void)loadRequest:(NSURLRequest*) req WithCompletion:(void(^)())completion onClose:(void(^)(BOOL))onClosed;

@end
