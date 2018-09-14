//
//  NSNull+JSON.h
//  MyTagList2
//
//  Created by cao on 7/14/13.
//
//

#import <Foundation/Foundation.h>

@interface NSNull (JSON)
- (NSUInteger)length;
- (double)doubleValue;
- (float)floatValue;
- (int)intValue;
- (NSInteger)integerValue;
- (long long)longLongValue;
- (BOOL)boolValue;
- (BOOL)isEqualToString:(NSString *)aString;

@end
