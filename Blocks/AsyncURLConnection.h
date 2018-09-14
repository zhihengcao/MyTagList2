#import <Foundation/Foundation.h>

typedef void (^completeBlock_t)(id jsonObj);
typedef void (^completeBlockRaw_t)(NSData* data);
typedef BOOL (^errorBlock_t)(NSError *error, id* sender);

extern NSString *const TagListCookiePrefKey;
extern NSString *const TagListGroupName;
extern NSString *const UseDegFPrefKey;

@interface AsyncURLConnection : NSURLConnection<NSURLConnectionDelegate>
{
	int lastStatusCode;
	NSMutableData *data_;
	completeBlock_t completeBlock_;
	completeBlockRaw_t completeBlockRaw_;
	errorBlock_t errorBlock_;
}
@property(retain, nonatomic) NSString* xmlMethodName;
//@property (nonatomic, retain) NSString *cookie;

+(void)standardShowError:(NSError*)error From:(id)sender;

+(id)request:(NSString *)requestUrl jsonObj:(id)obj completeBlock:(completeBlock_t)completeBlock errorBlock:(errorBlock_t)errorBlock setMac:(NSString*)setMac;

+ (NSDictionary *)syncRequest:(NSString *)requestUrl jsonObj:(id)obj error:(NSError **)error setMac:(NSString*)setMac;

+(NSString*)getCookie;
+(void)storeCookie:(NSString*)cookie;

+(id)request:(NSString *)requestUrl jsonString:(NSString*)data completeBlock:(completeBlock_t)completeBlock errorBlock:(errorBlock_t)errorBlock setMac:(NSString*)setMac;
//+ (id)getRequest:(NSString *)requestUrl completeBlock:(completeBlockRaw_t)completeBlockRaw errorBlock:(errorBlock_t)errorBlock;
+ (id)request:(NSString *)requestUrl jsonString:(NSString*)data completeBlock:(completeBlock_t)completeBlock errorBlock:(errorBlock_t)errorBlock setMac:(NSString*)setMac timeOut:(NSTimeInterval)timeout;
+(NSData*)syncGetRequest:(NSString *)requestUrl error:(NSError **)error;

-(id)initWithRequest:(NSURLRequest *)request completeBlock:(completeBlock_t)completeBlock errorBlock:(errorBlock_t)errorBlock;
- (id)initWithRequest:(NSURLRequest *)request completeBlockRaw:(completeBlockRaw_t)completeBlockRaw errorBlock:(errorBlock_t)errorBlock;
@end

@interface AsyncSoapURLConnection : AsyncURLConnection
+ (id)soapRequest:(NSString *)requestUrl soapAction:(NSString*) soapAction xml:(NSString*)data completeBlock:(completeBlock_t)completeBlock errorBlock:(errorBlock_t)errorBlock;
@end
