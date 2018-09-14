//
//  Copyright iOSDeveloperTips.com All rights reserved.
//
 
#import <CommonCrypto/CommonDigest.h>
#import "NSData+Base64.h"
#import "NSData+MD5.h"

@implementation NSData(MD5)
 
-(NSString*)Base64MD5{
	return [[self MD5] base64EncodedString];
}
-(NSData*)MD5
{
 	// Create byte array of unsigned chars
  unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];

	// Create 16 byte MD5 hash value, store in buffer
  CC_MD5(self.bytes, (CC_LONG)self.length, md5Buffer);
    
	return [[[NSData alloc] initWithBytes:md5Buffer length:sizeof(md5Buffer)] autorelease];
	
	// Convert unsigned char buffer to NSString of hex values
/*  NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
  for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) 
		[output appendFormat:@"%02x",md5Buffer[i]];

  return output;
 */
	
}
 
@end
