//
//  MDPreference.h
//  MDPreference
//
//  Created by xulinfeng on 2018/3/21.
//  Copyright © 2018年 modool. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for MDPreference.
FOUNDATION_EXPORT double MDPreferenceVersionNumber;

//! Project version string for MDPreference.
FOUNDATION_EXPORT const unsigned char MDPreferenceVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <MDPreference/PublicHeader.h>

#import "MDPreference.h"

NS_ASSUME_NONNULL_BEGIN

@class MDPreference;
@protocol MDPreference <NSObject, NSCoding, NSSecureCoding, NSCopying>

- (void)preference:(MDPreference *)preference willUpdateKey:(NSString *)key value:(id)value;
- (void)preference:(MDPreference *)preference didUpdateKey:(NSString *)key value:(id)value origin:(_Nullable id)origin;

@end

@interface MDPreference : NSObject <MDPreference>

@property (nonatomic, weak, nullable) id<MDPreference> parent;

@property (nonatomic, weak, nullable, readonly) Protocol *protocol;

+ (instancetype)preferenceWithProtocol:(Protocol * _Nullable)protocol;
- (instancetype)initWithProtocol:(Protocol * _Nullable)protocol;

@end

// Support NSKeyValueCoding
@interface MDPreference (NSKeyValueCoding)

/* Return the value of property named key.
 */
- (id)valueForKey:(NSString *)key;

/* Invoke -setValue:forKey: on each of the receiver's elements.
 */
- (void)setValue:(id)value forKey:(NSString *)key;

/* Return the value of property named key.
 */
- (id)objectForKeyedSubscript:(NSString *)key;

/* Invoke -setValue:forKey: on each of the receiver's elements.
 */
- (void)setObject:(id<NSObject, NSCopying, NSCoding>)anObject forKeyedSubscript:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
