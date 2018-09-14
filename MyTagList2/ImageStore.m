#import "ImageStore.h"
#import "FileHelpers.h"
#import "UIImage+Resize.h"
#import "Tag.h"
#import "NSData+MD5.h"
#import "WebImageOperations.h"
#import "UIImage+RoundedCorner.h"

@implementation ImageStore

+(ImageStore*)defaultImageStore
{
    static dispatch_once_t pred;
    static ImageStore *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[ImageStore alloc] init];
    });
    return sharedInstance;
}

+(UIImage*)placeholderImageNamed:(NSString*)name
{
	return [UIImage imageNamed:name==nil?@"Placeholder.png":name];
}

- (id)init
{
    self = [super init];
    if (self) {    
        dictionary = [[NSMutableDictionary alloc] init];
		thumb_cache = [[NSMutableDictionary alloc] init];
    }
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self 
           selector:@selector(clearCache:) 
               name:UIApplicationDidReceiveMemoryWarningNotification 
             object:nil];
    
    return self;
}

- (NSUInteger)retainCount
{
    return NSUIntegerMax;
}

- (void)clearCache:(NSNotification *)note
{
    //NSLog(@"flushing %ld images out of the cache", [dictionary count]);
    [dictionary removeAllObjects];
	[thumb_cache removeAllObjects];
}

-(void)loadImageFromServerAsyncForKey:(NSString*)uuid placeHolderNamed:(NSString*)placeHolderName ToView:(UIImageView*)view
{
	[WebImageOperations processImageDataWithURLString:[NSString stringWithFormat:@"%@eth/tags/%@.jpg",WSROOT,uuid]
											 andBlock:^(NSData *d) {

		UIImage* image = [[[UIImage alloc]initWithData:d] autorelease];
		if(image==nil){
			view.image = [ImageStore placeholderImageNamed:placeHolderName];
			return;
		}
		
		[dictionary setObject:image forKey:uuid];
		NSString *imagePath = pathInDocumentDirectory(uuid);
		[d writeToFile:imagePath atomically:YES];
		UIImage *small = [image resizedImage:CGSizeMake(THUMB_WIDTH, THUMB_HEIGHT) interpolationQuality:kCGInterpolationHigh];
		[UIImageJPEGRepresentation(small, 0.5) writeToFile:[imagePath stringByAppendingPathExtension:@"thumb"] atomically:YES];
		[thumb_cache setObject:small forKey:uuid];
		[self setBase64MD5:[d Base64MD5] ForKey:uuid];

		 view.image = [small roundedCornerImage:16 borderSize:10];
		
	}];
}
- (NSString*)setImage:(UIImage *)image forKey:(NSString *)s
{
    [dictionary setObject:image forKey:s];
    
    NSString *imagePath = pathInDocumentDirectory(s);
    NSData *d = UIImageJPEGRepresentation(image, 0.5);
    [d writeToFile:imagePath atomically:YES];

    UIImage *small = [image resizedImage:CGSizeMake(THUMB_WIDTH, THUMB_HEIGHT) interpolationQuality:kCGInterpolationHigh];
	[UIImageJPEGRepresentation(small, 0.5) writeToFile:[imagePath stringByAppendingPathExtension:@"thumb"] atomically:YES];
	[thumb_cache setObject:small forKey:s];
	
	NSString* md5 = [d Base64MD5];
	[self setBase64MD5:md5 ForKey:s];
	return md5;
}

- (BOOL) thumbnailLoadedForKey:(NSString *)key
{
	return [thumb_cache objectForKey:key]!=nil;
}
- (UIImage *)thumbnailForKey:(NSString *)s placeHolderNamed:(NSString*)placeHolderName loadFromFile:(BOOL) load
{
	if([s length]==0)return [ImageStore placeholderImageNamed:placeHolderName];
	
    UIImage *result = [thumb_cache objectForKey:s];
	if(result)return [result roundedCornerImage:16 borderSize:5];
	
    if (load) {
		NSString *fn = [s stringByAppendingPathExtension:@"thumb"];
        result = [UIImage imageWithContentsOfFile:pathInDocumentDirectory(fn)];
		
		if (!result)
			return [ImageStore placeholderImageNamed:placeHolderName];
		else
			[thumb_cache setObject:result forKey:s];
		
		return [result roundedCornerImage:16 borderSize:5];
    }
	else{
		return [ImageStore placeholderImageNamed:placeHolderName];
	}
}
-(void)setBase64MD5:(NSString*)md5 ForKey:(NSString*)uuid
{
	NSString *fn = pathInDocumentDirectory([uuid stringByAppendingPathExtension:@"md5"]);
	[md5 writeToFile:fn atomically:NO encoding:NSASCIIStringEncoding error:nil];
	[md5_cache setObject:md5 forKey:uuid];
}
- (NSString *)base64MD5ForKey:(NSString *)uuid
{
	if([uuid length]==0)return @"";
	
    NSString *result = [md5_cache objectForKey:uuid];
    if(result)return result;
	NSString *fn = pathInDocumentDirectory([uuid stringByAppendingPathExtension:@"md5"]);
	result =[NSString stringWithContentsOfFile:fn encoding:NSASCIIStringEncoding error:nil];
    if (!result)result = @"";
	[md5_cache setObject:result forKey:uuid];
	return result;
}

+ (BOOL)hasImageForKey:(NSString *)s
{
	return [[NSFileManager defaultManager] fileExistsAtPath: pathInDocumentDirectory(s)];
}

- (UIImage *)imageForKey:(NSString *)s
{
    UIImage *result = [dictionary objectForKey:s];
    
    if (!result) {
        // Create UIImage object from file
        result = [UIImage imageWithContentsOfFile:pathInDocumentDirectory(s)];
		if(!result) result = [ImageStore placeholderImageNamed:nil];

        [dictionary setObject:result forKey:s];
    }
    return result;
}

- (void)deleteImageForKey:(NSString *)s
{
    if (!s)
        return;
    [dictionary removeObjectForKey:s];
	[thumb_cache removeObjectForKey:s];
	[md5_cache removeObjectForKey:s];
	
    NSString *path = pathInDocumentDirectory(s);
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:[path stringByAppendingPathExtension:@"thumb"] error:nil];
	
}

@end
