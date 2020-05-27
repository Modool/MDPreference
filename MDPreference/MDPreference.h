//
//  MDPreference.h
//  MDPreference
//
//  Created by xulinfeng on 2018/3/21.
//  Copyright © 2018年 modool. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MDPreference;
@protocol MDPreference <NSObject>

@optional
@property (nonatomic, strong, readonly) dispatch_queue_t queue;

- (id)preference:(MDPreference *)preference requiredValueForKey:(NSString *)key;
- (void)preference:(MDPreference *)preference willUpdateKey:(NSString *)key value:(id)value;
- (void)preference:(MDPreference *)preference didUpdateKey:(NSString *)key value:(id)value origin:(nullable id)origin;

@end

@interface MDPreference : NSObject <NSCoding, NSSecureCoding, NSCopying, MDPreference>

@property (nonatomic, weak, nullable) id<MDPreference> parent;

@property (nonatomic, weak, nullable, readonly) Protocol *protocol;

@property (nonatomic, copy, nullable, readonly) NSSet<NSString *> *ignoredProperties;

// Default is nil;
@property (nonatomic, strong, readonly) dispatch_queue_t queue;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)preferenceWithProtocol:(Protocol *)protocol;
+ (instancetype)preferenceWithProtocol:(Protocol *)protocol queue:(nullable dispatch_queue_t)queue;
+ (instancetype)preferenceWithProtocol:(Protocol *)protocol queue:(nullable dispatch_queue_t)queue ignoredProperties:(nullable NSSet<NSString *> *)ignoredProperties;

- (instancetype)initWithProtocol:(Protocol *)protocol;
- (instancetype)initWithProtocol:(Protocol *)protocol queue:(nullable dispatch_queue_t)queue;
- (instancetype)initWithProtocol:(Protocol *)protocol queue:(nullable dispatch_queue_t)queue ignoredProperties:(nullable NSSet<NSString *> *)ignoredProperties NS_DESIGNATED_INITIALIZER;

- (id)preference:(MDPreference *)preference requiredValueForKey:(NSString *)key NS_REQUIRES_SUPER;
- (void)preference:(MDPreference *)preference willUpdateKey:(NSString *)key value:(nullable id)value NS_REQUIRES_SUPER;
- (void)preference:(MDPreference *)preference didUpdateKey:(NSString *)key value:(nullable id)value origin:(nullable id)origin NS_REQUIRES_SUPER;

@end

// Support NSKeyValueCoding
@interface MDPreference (NSKeyValueCoding)

@property (nonatomic, copy, readonly) NSDictionary *dictionary;

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
