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

#define MDPreferenceClassBegin(ClassName)           \
@protocol ClassName <NSObject>                      \
@optional                                           \

#define MDPreferenceClassEnd(ClassName)             \
@end                                                \
@interface ClassName : MDPreference<ClassName>      \
@end                                                \

#define MDPreferenceClassImplementation(ClassName)  \
@implementation ClassName                           \
@end

#import "MDPreference.h"

@class MDPreference;
@protocol MDPreference <NSObject, NSCoding, NSSecureCoding, NSCopying>

- (void)preference:(MDPreference *)preference willUpdateKey:(NSString *)key value:(id)value;
- (void)preference:(MDPreference *)preference didUpdateKey:(NSString *)key value:(id)value origin:(id)origin;

@end

// Support NSKeyValueCoding, 
@interface MDPreference : NSObject <MDPreference>

@property (nonatomic, weak) id<MDPreference> parent;

@end

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
