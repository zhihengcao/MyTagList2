#import "AsyncURLConnection.h"
//#import "SBJson.h"
#ifndef TARGET_IS_EXTENSION
#import "iToast.h"
#endif

NSString *const TagListCookiePrefKey = @"TagListCookiePrefKey";
NSString *const UseDegFPrefKey = @"UseDegFPrefKey";
NSString *const TagListGroupName = @"group.com.mytaglist";

@implementation AsyncSoapURLConnection

+ (id)soapRequest:(NSString *)requestUrl soapAction:(NSString*) soapAction xml:(NSString*)data completeBlock:(completeBlock_t)completeBlock errorBlock:(errorBlock_t)errorBlock
{
	NSURL *url = [NSURL URLWithString:requestUrl];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:120];
	request.HTTPMethod=@"POST";
	[request setValue:@"text/xml; charset=\"utf-8\"" forHTTPHeaderField:@"Content-Type"];
	[request setValue:[NSString stringWithFormat:@"\"%@\"",soapAction] forHTTPHeaderField:@"SOAPAction"];
	NSString* cookie =  [self getCookie];// [[NSUserDefaults standardUserDefaults]objectForKey:TagListCookiePrefKey];
	if(cookie)[request addValue:cookie forHTTPHeaderField:@"Cookie"];
	
	if(data){
		request.HTTPBody = [data dataUsingEncoding:NSUTF8StringEncoding]; //[NSData dataWithBytes:[data UTF8String] length:[data length]];
		[request setValue:[NSString stringWithFormat:@"%d", (int)[request.HTTPBody length]] forHTTPHeaderField:@"Content-Length"];
    }else{
		request.HTTPBody=[NSData dataWithBytes:[@"{}" UTF8String] length:2];
		[request setValue:@"2" forHTTPHeaderField:@"Content-Length"];
	}
	AsyncURLConnection* ret = [[[self alloc] initWithRequest:request
							completeBlock:completeBlock errorBlock:errorBlock] autorelease];
	ret.xmlMethodName = [soapAction substringFromIndex: [soapAction rangeOfString:@"/" options:NSBackwardsSearch].location+1];
	return ret;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
//<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><soap:Body><GetNextUpdateResponse xmlns="http://mytaglist.com/ethClient"><GetNextUpdateResult>[]</GetNextUpdateResult></GetNextUpdateResponse></soap:Body></soap:Envelope>
	
	NSString *xml = [[[NSString alloc] initWithData:data_ encoding:NSUTF8StringEncoding] autorelease];
//	NSRange starttag = [xml rangeOfString:@"<GetNextUpdateResult>"], endtag = [xml rangeOfString:@"</GetNextUpdateResult>"];
	NSRange starttag = [xml rangeOfString: [NSString stringWithFormat:@"<%@Result>", self.xmlMethodName]],
						endtag = [xml rangeOfString:[NSString stringWithFormat:@"</%@Result>", self.xmlMethodName]];
	
	if(starttag.length==0){
		starttag = [xml rangeOfString:@"<faultstring>"]; endtag = [xml rangeOfString:@"</faultstring>"];
		NSDictionary* ui = nil;
		if(starttag.length>0)
			ui=[NSDictionary dictionaryWithObject:[xml substringWithRange:NSMakeRange(starttag.location+starttag.length, endtag.location-starttag.location-starttag.length)] forKey:@"Message"];
		
		NSError* err = [NSError errorWithDomain:@"Server Error" code:lastStatusCode userInfo:ui];
		[self connection:connection didFailWithError: err];
		return;
	}
	NSString* json = [xml substringWithRange:NSMakeRange(starttag.location+starttag.length, endtag.location-starttag.location-starttag.length)];
	//NSLog(@"json in in XML=%@", json);

	NSError* jsonError = nil;
	id representation =[NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&jsonError];

	if(lastStatusCode>=400){
		NSError* err = [NSError errorWithDomain:@"Server Error" code:lastStatusCode userInfo:representation];		
		[self connection:connection didFailWithError: err];
	}
	else{
		if(jsonError!=nil){
			[self connection:connection didFailWithError: jsonError];
		}
		else{
			if(completeBlock_!=nil)
				//		dispatch_async(dispatch_get_main_queue(), ^{
				completeBlock_(representation);
			//		});
		}
	}
}

@end
@implementation AsyncURLConnection
//@synthesize cookie=_cookie;

+(void)standardShowError:(NSError*)error From:(id)sender{
#ifndef TARGET_IS_EXTENSION
	NSString* json_msg = [error.userInfo objectForKey:@"Message"];
#ifdef DEBUG
	NSString* stackTrace = [error.userInfo objectForKey:@"StackTrace"];
#endif

	if([[UIApplication sharedApplication] applicationState]==UIApplicationStateActive){

		if(json_msg){
#ifdef DEBUG
			iToast* t =[[iToast makeText:json_msg andDetail:stackTrace] setDuration:iToastDurationNormal];
#else
			iToast* t =[[iToast makeText:json_msg] setDuration:iToastDurationNormal];
#endif
			[t showFrom:sender];
			
			//[alert setTitle:[error localizedDescription]];
			//[alert setMessage:json_msg];
		}else{
			UIAlertView *alert = [[UIAlertView alloc] init];
			[alert setTitle:@"Error connecting to server"];
			[alert setMessage:error.localizedDescription];
			[alert addButtonWithTitle:@"Continue"];
			[alert setCancelButtonIndex:0];
			[alert show];
			[alert release];
		}
	}else{
		UILocalNotification *reminder1 = [[[UILocalNotification alloc] init] autorelease];
		[reminder1 setFireDate:[NSDate date]];
		[reminder1 setTimeZone:[NSTimeZone localTimeZone]];
		[reminder1 setHasAction:YES];
		[reminder1 setAlertAction:@"Show"];
		[reminder1 setSoundName:@"Uh oh"];
		[reminder1 setAlertBody:json_msg?json_msg:@"Error connecting to server"];
		[[UIApplication sharedApplication] scheduleLocalNotification:reminder1];
	}
#endif
}
+(NSData*)syncGetRequest:(NSString *)requestUrl error:(NSError **)error
{
	NSURL *url = [NSURL URLWithString:requestUrl];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
	request.HTTPMethod=@"GET";
	NSString* cookie = [AsyncURLConnection getCookie];//[[NSUserDefaults standardUserDefaults]objectForKey:TagListCookiePrefKey];
	if(cookie)[request addValue:cookie forHTTPHeaderField:@"Cookie"];
	NSURLResponse* response=nil;
	NSData* data_= [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:error];
	int lastStatusCode = (int)[(NSHTTPURLResponse*)response statusCode];
	return data_;
}
+ (NSDictionary *)syncRequest:(NSString *)requestUrl jsonObj:(id)obj error:(NSError **)error setMac:(NSString*)setMac
{
#ifndef TARGET_IS_EXTENSION
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible=YES;
    });
#endif
	NSError* jsonError=nil;
	NSString* jsonS = [[[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:obj options:0 error:&jsonError]  encoding:NSUTF8StringEncoding] autorelease];

	#ifdef DEBUG
	NSLog(@"SYNC json out: %@(%@): %@\n", requestUrl, setMac, jsonS);
	#endif

	NSURL *url = [NSURL URLWithString:requestUrl];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
	request.HTTPMethod=@"POST";
	[request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	
	NSString* cookie = [AsyncURLConnection getCookie];//[[NSUserDefaults standardUserDefaults]objectForKey:TagListCookiePrefKey];
	if(cookie)[request addValue:cookie forHTTPHeaderField:@"Cookie"];
	if(setMac)[request addValue:setMac forHTTPHeaderField:@"X-Set-Mac"];
	
	request.HTTPBody = [jsonS dataUsingEncoding:NSUTF8StringEncoding];//[NSData dataWithBytes:[jsonS UTF8String] length:[jsonS length]];
	[request setValue:[NSString stringWithFormat:@"%d", (int)[request.HTTPBody length]] forHTTPHeaderField:@"Content-Length"];

	NSURLResponse* response=nil;
	NSData* data_= [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:error];
	int lastStatusCode = (int)[(NSHTTPURLResponse*)response statusCode];

#ifndef TARGET_IS_EXTENSION
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible=NO;
    });
#endif
	
	NSString *json = [[[NSString alloc] initWithData:data_ encoding:NSUTF8StringEncoding] autorelease];
#if DEBUG
	NSLog(@"SYNC ====== %@: %ld bytes received", request.URL.path, (unsigned long)data_.length);
//	NSLog(@"======= %@ returns:%@",request.URL.path,  json);
#endif
	
	NSDictionary* ret = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&jsonError];
	
	if(lastStatusCode>=400){
		__block NSError* e = [[NSError errorWithDomain:@"Server Error" code:lastStatusCode userInfo:ret] copy];
		if(error!=nil)
			*error = e;
		dispatch_async(dispatch_get_main_queue(), ^{
			[AsyncURLConnection standardShowError:e From:nil];
			[e release];
		});
		return nil;
	}else{
		if(jsonError!=nil){
			__block NSError* e = [jsonError copy];
			if(error!=nil)
				*error = jsonError;
			dispatch_async(dispatch_get_main_queue(), ^{
				[AsyncURLConnection standardShowError:e From:nil];
				[e release];
			});
			return nil;
		}
		else{
			return ret;
		}
	}

}

+ (id)request:(NSString *)requestUrl jsonObj:(id)obj completeBlock:(completeBlock_t)completeBlock errorBlock:(errorBlock_t)errorBlock setMac:(NSString*) setMac
{
	//SBJsonWriter* writer = [[[SBJsonWriter alloc]init] autorelease];
	//NSString* jsonS = [writer stringWithObject:obj];
	NSError* jsonError=nil;
	NSString* jsonS = [[[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:obj options:0 error:&jsonError]  encoding:NSUTF8StringEncoding] autorelease];
	jsonS = [jsonS stringByReplacingOccurrencesOfString:@"’" withString:@"\\'"];
	jsonS = [jsonS stringByReplacingOccurrencesOfString:@"‘" withString:@"\\'"];
	jsonS = [jsonS stringByReplacingOccurrencesOfString:@"“" withString:@"\\\""];
	jsonS = [jsonS stringByReplacingOccurrencesOfString:@"”" withString:@"\\\""];	
	
	return [self.class request:requestUrl jsonString:jsonS completeBlock:completeBlock errorBlock:errorBlock setMac:setMac];
}
+ (id)request:(NSString *)requestUrl jsonString:(NSString*)data completeBlock:(completeBlock_t)completeBlock errorBlock:(errorBlock_t)errorBlock setMac:(NSString*)setMac
{
	return [AsyncURLConnection request:requestUrl jsonString:data completeBlock:completeBlock errorBlock:errorBlock setMac:setMac timeOut:120];
}
+(id)request:(NSString *)requestUrl jsonString:(NSString *)data completeBlock:(completeBlock_t)completeBlock errorBlock:(errorBlock_t)errorBlock setMac:(NSString *)setMac timeOut:(NSTimeInterval)timeout
{
//#ifdef DEBUG
	NSLog(@"json out: %@(%@): %@\n", requestUrl, setMac, data);
//#endif
	

	NSURL *url = [NSURL URLWithString:requestUrl];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
	request.HTTPMethod=@"POST";
	request.timeoutInterval=timeout;
	[request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	
	NSString* cookie = [self getCookie]; //[[NSUserDefaults standardUserDefaults]objectForKey:TagListCookiePrefKey];
	if(cookie)[request addValue:cookie forHTTPHeaderField:@"Cookie"];
	
	if(setMac)[request addValue:setMac forHTTPHeaderField:@"X-Set-Mac"];
	
	if(data){
		request.HTTPBody = [data dataUsingEncoding:NSUTF8StringEncoding]; //[NSData dataWithBytes:[data UTF8String] length:[data length]];
		[request setValue:[NSString stringWithFormat:@"%d", (int)[request.HTTPBody length]] forHTTPHeaderField:@"Content-Length"];
    }else{
		request.HTTPBody=[NSData dataWithBytes:[@"{}" UTF8String] length:2];
		[request setValue:@"2" forHTTPHeaderField:@"Content-Length"];
	}
#ifndef TARGET_IS_EXTENSION
	[UIApplication sharedApplication].networkActivityIndicatorVisible=YES;
#endif
	return [[[self alloc] initWithRequest:request
							completeBlock:completeBlock errorBlock:errorBlock] autorelease];
}
/*
+ (id)getRequest:(NSString *)requestUrl completeBlock:(completeBlockRaw_t)completeBlockRaw errorBlock:(errorBlock_t)errorBlock
{
	NSURL *url = [NSURL URLWithString:requestUrl];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
//	request.HTTPMethod=@"GET";
	NSString* cookie = [[NSUserDefaults standardUserDefaults]objectForKey:TagListCookiePrefKey];
	if(cookie)[request addValue:cookie forHTTPHeaderField:@"Cookie"];

	[UIApplication sharedApplication].networkActivityIndicatorVisible=YES;
	
	return [[[self alloc] initWithRequest:request
							completeBlockRaw:completeBlockRaw errorBlock:errorBlock] autorelease];
}
*/

- (id)initWithRequest:(NSURLRequest *)request completeBlockRaw:(completeBlockRaw_t)completeBlockRaw errorBlock:(errorBlock_t)errorBlock
{
	if ((self = [super initWithRequest:request delegate:self startImmediately:NO])) {
		data_ = [[NSMutableData alloc] init];
		completeBlockRaw_ = [completeBlockRaw copy];
		completeBlock_=nil;
		errorBlock_ = [errorBlock copy];
		[self start];
	}
	return self;
}

- (id)initWithRequest:(NSURLRequest *)request completeBlock:(completeBlock_t)completeBlock errorBlock:(errorBlock_t)errorBlock
{
	if ((self = [super initWithRequest:request delegate:self startImmediately:NO])) {
		data_ = [[NSMutableData alloc] init];
		completeBlock_ = [completeBlock copy];
		completeBlockRaw_=nil;
		errorBlock_ = [errorBlock copy];
		[self start];
	}
	return self;
}

- (void)dealloc
{
	[data_ release];
	[completeBlock_ release];
	[completeBlockRaw_ release];
	[errorBlock_ release];
	self.xmlMethodName=nil;
	[super dealloc];
}
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse{
	return nil;
}
+(void)storeCookie:(NSString *)cookie{
	[[[[NSUserDefaults alloc]initWithSuiteName:TagListGroupName]autorelease]setValue:cookie forKey:TagListCookiePrefKey];
}
+(NSString*)getCookie{
	return [[[[NSUserDefaults alloc]initWithSuiteName:TagListGroupName]autorelease]objectForKey:TagListCookiePrefKey];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	lastStatusCode = (int)[(NSHTTPURLResponse*)response statusCode];
	
	NSDictionary *fields = [(NSHTTPURLResponse*)response allHeaderFields];
	
    NSString* cookie= [fields valueForKey:@"Set-Cookie"];
	if(cookie){
		NSRange lastc = [cookie rangeOfString:@";"];
		if(lastc.length)cookie = [cookie substringWithRange:NSMakeRange(0, lastc.location)];
		[AsyncSoapURLConnection storeCookie:cookie];
	}
	
/*	NSHTTPURLResponse        *httpResponse = (NSHTTPURLResponse *)response;
	NSArray                  *cookies =  [ NSHTTPCookie cookiesWithResponseHeaderFields:<#(nonnull NSDictionary<NSString *,NSString *> *)#> forURL:<#(nonnull NSURL *)#> cookiesWithResponseHeaderFields:
			   [ httpResponse allHeaderFields ]];
	[[ NSHTTPCookieStorage sharedHTTPCookieStorage ]
	 setCookies: cookies forURL: self.url mainDocumentURL: nil ]; */
	
	[data_ setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[data_ appendData:data];
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
#ifndef TARGET_IS_EXTENSION
	[UIApplication sharedApplication].networkActivityIndicatorVisible=NO;
#endif
	id sender=nil;
	if(errorBlock_!=nil){
		if(NO==errorBlock_(error, &sender))return;
	}
	[AsyncURLConnection standardShowError:error From:sender];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
#ifndef TARGET_IS_EXTENSION
	[UIApplication sharedApplication].networkActivityIndicatorVisible=NO;
#endif
	
#if DEBUG
	//NSLog(@"======= %@: %ld bytes received", self.currentRequest.URL.path, data_.length);
#endif

	if(completeBlockRaw_==nil){
		NSString *json = [[[NSString alloc] initWithData:data_ encoding:NSUTF8StringEncoding] autorelease];

#if DEBUG
		NSLog(@"======= %@ returns:%@",self.currentRequest.URL.path,  json);
#endif
		
		NSError* jsonError = nil;
		id representation =[NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&jsonError];
		
		if(lastStatusCode>=400){
			NSError* err = [NSError errorWithDomain:@"Server Error" code:lastStatusCode userInfo:representation];
			[self connection:connection didFailWithError: err];
		}
		else{
			if(jsonError!=nil){
				[self connection:connection didFailWithError: jsonError];
			}
			else{
				if(completeBlock_!=nil)
					//		dispatch_async(dispatch_get_main_queue(), ^{
					completeBlock_(representation);
				//		});
			}
		}
	}else{

		if(lastStatusCode>=400){
			NSError* err = [NSError errorWithDomain:@"Server Error" code:lastStatusCode userInfo:nil];
			[self connection:connection didFailWithError: err];
		}
		else{
			completeBlockRaw_(data_);
		}
	}
}


@end
