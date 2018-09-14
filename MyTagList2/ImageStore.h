#import <Foundation/Foundation.h>

#define THUMB_HEIGHT 68.0
//#define THUMB_HEIGHT 80
#define THUMB_WIDTH 68.0
//#define THUMB_WIDTH 80

#define DETAIL_HEIGHT 200.0
//#define DETAIL_HEIGHT 240.0
#define DETAIL_WIDTH 200.0
//#define DETAIL_WIDTH 240.0

@interface ImageStore : NSObject
{
    NSMutableDictionary *dictionary;
    NSMutableDictionary *md5_cache;
    NSMutableDictionary *thumb_cache;
}

+ (ImageStore *)defaultImageStore;
+(UIImage*)placeholderImageNamed:(NSString*)name;

+ (BOOL)hasImageForKey:(NSString *)s;
- (NSString*)setImage:(UIImage *)i forKey:(NSString *)s;
-(void)loadImageFromServerAsyncForKey:(NSString*)uuid placeHolderNamed:(NSString*)placeHolderName ToView:(UIImageView*)view;
-(void)setBase64MD5:(NSString*)md5 ForKey:(NSString*)uuid;

- (UIImage *)imageForKey:(NSString *)s;
- (void)deleteImageForKey:(NSString *)s;
- (UIImage *)thumbnailForKey:(NSString *)s  placeHolderNamed:(NSString*)placeHolderName loadFromFile:(BOOL) load;
- (BOOL) thumbnailLoadedForKey:(NSString *)key;

- (NSString *)base64MD5ForKey:(NSString *)uuid;
@end
