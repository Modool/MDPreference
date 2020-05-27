//
//  MDPreference.m
//  MDPreference
//
//  Created by xulinfeng on 2017/9/25.
//  Copyright © 2017年 bilibili. All rights reserved.
//

#import <objc/runtime.h>
#import <UIKit/UIKit.h>

#import "MDPreference.h"
#import "MDPreference+Private.h"

NSString * const MDPreferenceSetterPredicateString = @"^set[A-Z]([a-z]|[A-Z]|[0-9]|_)*:$";
NSString * const MDPreferenceGetterPredicateString = @"^[a-z]([a-z]|[A-Z]|[0-9]|_)*$";

NSString * const MDPreferenceEncodeValueKey = @"keyValues";
NSString * const MDPreferenceEncodeProtocolKey = @"protocol";

@implementation MDPreferencePropertyInfo

+ (instancetype)infoWithName:(NSString *)name getter:(SEL)getter setter:(SEL)setter; {
    if (!name.length || (!getter && !setter)) return nil;

    MDPreferencePropertyInfo *info = [[self alloc] init];
    info->_name = name;
    info->_getter = getter;
    info->_setter = setter;

    return info;
}

- (BOOL)isEqual:(MDPreferencePropertyInfo *)object {
    BOOL equal = [super isEqual:object];
    if (equal) return YES;

    return [object isKindOfClass:[MDPreferencePropertyInfo class]] && [object.name isEqual:_name];
}

- (NSUInteger)hash {
    return _name.hash ^ self.class.hash;
}

- (BOOL)match:(SEL)selector setter:(BOOL *)setterPtr {
    BOOL matched = _setter == selector;

    if (setterPtr) *setterPtr = matched;
    if (matched) return YES;

    return _getter == selector || [_name isEqualToString:NSStringFromSelector(selector)];
}

+ (NSArray<MDPreferencePropertyInfo *> *)propertyInfosWithProtocol:(Protocol *)protocol dictionary:(NSDictionary<NSString *, MDPreferencePropertyInfo *> **)dictionary {
    NSMutableArray<MDPreferencePropertyInfo *> *infos = [NSMutableArray array];
    NSMutableDictionary<NSString *, MDPreferencePropertyInfo *> *infoDictioanry = [NSMutableDictionary dictionary];

    [self _addPropertyInfosForProtocol:protocol array:infos dictionary:infoDictioanry];

    if (dictionary) *dictionary = [infoDictioanry copy];
    return [infos copy];
}

+ (void)_addPropertyInfosForProtocol:(Protocol *)protocol array:(NSMutableArray<MDPreferencePropertyInfo *> *)array dictionary:(NSMutableDictionary<NSString *, MDPreferencePropertyInfo *> *)dictionary {
    if (!protocol || protocol == @protocol(NSObject)) return;

    unsigned int protocolCount = 0;
    __unsafe_unretained Protocol **protocols = protocol_copyProtocolList(protocol, &protocolCount);
    for (int i = 0; i < protocolCount; i++) {
        Protocol *superProtocol = protocols[i];

        [self _addPropertyInfosForProtocol:superProtocol array:array dictionary:dictionary];
    }
    free(protocols);

    [self _addPropertyInfosInProtocol:protocol array:array dictionary:dictionary];
}

+ (void)_addPropertyInfosInProtocol:(Protocol *)protocol array:(NSMutableArray<MDPreferencePropertyInfo *> *)array dictionary:(NSMutableDictionary<NSString *, MDPreferencePropertyInfo *> *)dictionary {
    unsigned int propertyCount = 0;
    objc_property_t *properties = protocol_copyPropertyList(protocol, &propertyCount);
    if (!properties || !propertyCount) return;

    for (unsigned int i = 0; i < propertyCount; i++) {
        objc_property_t property = properties[i];
        const char *name = property_getName(property);
        if (!name) continue;

        NSString *propertyName = [NSString stringWithUTF8String:name];
        const char *getter = property_copyAttributeValue(property, "G");
        const char *setter = property_copyAttributeValue(property, "S");

        NSString *getterName = getter ? [NSString stringWithUTF8String:getter] : propertyName;
        NSString *setterName = nil;
        if (setter) {
            setterName = [NSString stringWithUTF8String:setter];
        } else {
            NSString *first = [[propertyName substringToIndex:1] uppercaseString];
            NSString *tail = [propertyName substringFromIndex:1];
            setterName = [NSString stringWithFormat:@"set%@%@:", first, tail];
        }

        MDPreferencePropertyInfo *info = [MDPreferencePropertyInfo infoWithName:propertyName getter:NSSelectorFromString(getterName) setter:NSSelectorFromString(setterName)];
        if (!info) continue;

        [array removeObject:info];
        [array addObject:info];

        dictionary[propertyName] = info;
    }
    free(properties);
}

@end

@implementation MDPreference

+ (instancetype)preferenceWithProtocol:(Protocol *)protocol {
    return [self preferenceWithProtocol:protocol queue:nil];
}

+ (instancetype)preferenceWithProtocol:(Protocol *)protocol queue:(dispatch_queue_t)queue {
    return [self preferenceWithProtocol:protocol queue:queue ignoredProperties:nil];
}

+ (instancetype)preferenceWithProtocol:(Protocol *)protocol queue:(dispatch_queue_t)queue ignoredProperties:(NSSet<NSString *> *)ignoredProperties {
    return [[self alloc] initWithProtocol:protocol queue:queue];
}

- (instancetype)initWithProtocol:(Protocol *)protocol {
    return [self initWithProtocol:protocol queue:nil];
}

- (instancetype)initWithProtocol:(Protocol *)protocol queue:(dispatch_queue_t)queue {
    return [self initWithProtocol:protocol queue:queue ignoredProperties:nil];
}

- (instancetype)initWithProtocol:(Protocol *)protocol queue:(dispatch_queue_t)queue ignoredProperties:(NSSet<NSString *> *)ignoredProperties {
    NSParameterAssert(protocol);

    if (self = [super init]) {
        _dictionary = [NSMutableDictionary dictionary];

        _protocol = protocol;
        _ignoredProperties = [ignoredProperties copy];

        NSDictionary<NSString *, MDPreferencePropertyInfo *> *dictionary = nil;
        _propertyInfos = [MDPreferencePropertyInfo propertyInfosWithProtocol:protocol dictionary:&dictionary];
        _propertyInfoDictionary = dictionary;

        _queue = queue;
        _queueTag = &_queueTag;
        if (queue) dispatch_queue_set_specific(_queue, _queueTag, _queueTag, NULL);
    }
    return self;
}

- (instancetype)init {
    return nil;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    NSString *protocolName = [aDecoder decodeObjectForKey:MDPreferenceEncodeProtocolKey];
    Protocol *protocol = NSProtocolFromString(protocolName);

    if (self = [self initWithProtocol:protocol]) {
        _dictionary = [aDecoder decodeObjectForKey:MDPreferenceEncodeValueKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [self _performWithBlock:^{
        [self _encodeWithCoder:aCoder];
    }];
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding{
    return [NSMutableDictionary supportsSecureCoding];
}

#pragma mark - NSCopy

- (id)copyWithZone:(nullable NSZone *)zone {
    return [self _copy];
}

#pragma mark - NSObject Invocation

- (void)forwardInvocation:(NSInvocation *)invocation {
    __block BOOL success = NO;

    [self _performWithBlock:^{
        success = [self _forwardInvocation:invocation];
    }];

    if (!success) [super forwardInvocation:invocation];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    __block NSMethodSignature *signature = nil;

    [self _performWithBlock:^{
        signature = [self _methodSignatureForSelector:aSelector];
    }];

    return signature ?: [super methodSignatureForSelector:aSelector];
}

#pragma mark - accessor

- (NSString *)description{
    __block NSString *description = nil;
    [self _performWithBlock:^{
        description = [self->_dictionary description];
    }];
    return description;
}

- (void)setDictionary:(NSDictionary *)dictionary {
    [self _performWithBlock:^{
        [self _setDictionary:dictionary];
    }];
}

- (NSDictionary *)dictionary{
    __block NSDictionary<NSString *,id> *dictionary = nil;

    [self _performWithBlock:^{
        dictionary = [self _dictionary];
    }];
    return dictionary;
}

#pragma mark - KVC

- (BOOL)validateValue:(inout id *)ioValue forKey:(NSString *)inKey error:(out NSError **)outError {
    return [self validateValue:ioValue forKey:inKey error:outError relative:YES];
}

- (BOOL)validateValue:(inout id *)ioValue forKeyPath:(NSString *)inKeyPath error:(out NSError **)outError {
    return [self validateValue:ioValue forKey:inKeyPath error:outError relative:NO];
}

- (id)valueForKeyPath:(NSString *)keyPath {
    __block id value = nil;
    [self _performWithBlock:^{
        value = [self _valueForKeyPath:keyPath];
    }];
    return value;
}

- (void)setValue:(id)value forKeyPath:(NSString *)keyPath {
    [self _performWithBlock:^{
        [self _setValue:value forKeyPath:keyPath];
    }];
}

- (id<NSObject, NSCopying, NSCoding>)objectForKey:(NSString *)key {
    __block id<NSObject, NSCopying, NSCoding> object = nil;
    [self _performWithBlock:^{
        object = [self _objectForKey:key];
    }];
    return object;
}

- (void)setObject:(id<NSObject, NSCopying, NSCoding>)object forKey:(NSString *)key{
    [self _performWithBlock:^{
        [self _setObject:object forKey:key];
    }];
}

#pragma mark - protected

- (BOOL)validateValue:(inout id *)ioValue forKey:(NSString *)inKey error:(out NSError **)outError relative:(BOOL)relative {
    __block BOOL valid = NO;
    __block id value = ioValue ? *ioValue : nil;
    __block NSError *error = outError ? *outError : nil;

    [self _performWithBlock:^{
        id value_ = value;
        NSError *error_ = error;
        if (relative) {
            valid = [self->_dictionary validateValue:&value_ forKey:inKey error:&error_];
        } else {
            valid = [self->_dictionary validateValue:&value_ forKeyPath:inKey error:&error_];
        }
        value = value_;
        error = error_;
    }];

    if (ioValue) *ioValue = value;
    if (outError) *outError = error;

    return valid;
}

#pragma mark - private

- (void)_encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:_dictionary forKey:MDPreferenceEncodeValueKey];
    [aCoder encodeObject:NSStringFromProtocol(_protocol) forKey:MDPreferenceEncodeProtocolKey];
}

- (MDPreference *)_copy {
    MDPreference *preference = [[self class] preferenceWithProtocol:_protocol queue:_queue];
    preference->_dictionary = [_dictionary ?: @{} mutableCopy];

    return preference;
}

- (BOOL)_forwardInvocation:(NSInvocation *)invocation {
    SEL selector = [invocation selector];
    BOOL matched = NO;
    for (MDPreferencePropertyInfo *info in _propertyInfos) {
        BOOL setter = NO;
        matched = [info match:selector setter:&setter];
        if (!matched) continue;

        if (setter) [self _invokeSetterWithPropertyName:info.name invocation:invocation];
        else [self _invokeGetterWithPropertyName:info.name invocation:invocation];

        break;
    }
    if (matched) {
        invocation.target = nil;
        [invocation invoke];
    }
    return matched;
}

- (NSMethodSignature *)_methodSignatureForSelector:(SEL)aSelector {
    struct objc_method_description description = protocol_getMethodDescription(_protocol, aSelector, YES, YES);
    if (description.name && description.types) return [NSMethodSignature signatureWithObjCTypes:description.types];

    description = protocol_getMethodDescription(_protocol, aSelector, NO, YES);
    if (description.name && description.types) return [NSMethodSignature signatureWithObjCTypes:description.types];

    return nil;
}

- (void)_invokeSetterWithPropertyName:(NSString *)propertyName invocation:(NSInvocation *)invocation {
    id result = MDPreferenceBoxValue(invocation, 2);
    [self _setObject:result forKey:propertyName];
}

- (void)_invokeGetterWithPropertyName:(NSString *)propertyName invocation:(NSInvocation *)invocation {
    id value = [self _objectForKey:propertyName];
    MDPreferenceReturnValue(invocation, value);
}

- (void)_setDictionary:(NSDictionary *)dictionary {
    for (NSString *key in [dictionary allKeys]) {
        [self willChangeValueForKey:key];
    }

    _dictionary.dictionary = dictionary;

    for (NSString *key in [dictionary allKeys]) {
        [self didChangeValueForKey:key];
    }
}

- (NSDictionary *)_dictionary{
    return [_dictionary copy];
}

- (id<NSObject, NSCopying, NSCoding>)_objectForKey:(NSString *)key {
    return [self _objectForKey:key relative:YES];
}

- (void)_setObject:(id<NSObject, NSCopying, NSCoding>)object forKey:(NSString *)key {
    if (![key length]) return;
    if (object && ![object respondsToSelector:@selector(copyWithZone:)]) return;
    if (object && ![object respondsToSelector:@selector(encodeWithCoder:)]) return;
    if (object && ![object respondsToSelector:@selector(initWithCoder:)]) return;
    
    object = object ?: [NSNull null];
    id originValue = [self _objectForKey:key];

    [self _setObject:object origin:originValue forKey:key relative:YES];
}

- (id)_valueForKeyPath:(NSString *)keyPath {
    return [self _objectForKey:keyPath relative:NO];
}

- (void)_setValue:(id)value forKeyPath:(NSString *)keyPath {
    NSParameterAssert([keyPath length]);

    id originValue = [self _valueForKeyPath:keyPath];
    [self _setObject:value origin:originValue forKey:keyPath relative:NO];
}

- (id<NSObject, NSCopying, NSCoding>)_objectForKey:(NSString *)key relative:(BOOL)relative {
    id value = nil;
    if ([_ignoredProperties containsObject:key]) {
        value = [self preference:self requiredValueForKey:key];
    } else {
        value = relative ? _dictionary[key] : [_dictionary valueForKeyPath:key];
    }
    return value == [NSNull null] ? nil : value;
}

- (void)_setObject:(id<NSObject, NSCopying, NSCoding>)object origin:(id<NSObject, NSCopying, NSCoding>)origin forKey:(NSString *)key relative:(BOOL)relative {
    [self preference:self willUpdateKey:key value:object];

    if (relative) [self willChangeValueForKey:key];

    if (![_ignoredProperties containsObject:key]) {
        if (relative) [_dictionary setValue:object forKey:key];
        else [_dictionary setValue:object forKeyPath:key];
    }
    if (relative) [self didChangeValueForKey:key];

    [self preference:self didUpdateKey:key value:object origin:origin];
}

- (void)_performWithBlock:(dispatch_block_t)block {
    if (_queue && dispatch_get_specific(_queueTag) == NULL) dispatch_sync(_queue, block);
    else block();
}

- (void)_respondWithBlock:(dispatch_block_t)block {
    dispatch_queue_t queue = [self.parent respondsToSelector:@selector(queue)] ? self.parent.queue : nil;
    if (queue) {
        dispatch_async(queue, block);
    } else {
        block();
    }
}

#pragma mark - MDPreference

- (id)preference:(MDPreference *)preference requiredValueForKey:(NSString *)key {
    if (![_parent respondsToSelector:@selector(preference:requiredValueForKey:)]) return nil;

    __block id value = nil;
    [self _respondWithBlock:^{
        value = [self->_parent preference:preference requiredValueForKey:key];
    }];
    return value;
}

- (void)preference:(MDPreference *)preference willUpdateKey:(NSString *)key value:(id)value {
    if (![_parent respondsToSelector:@selector(preference:willUpdateKey:value:)]) return;

    [self _respondWithBlock:^{
        [self->_parent preference:preference willUpdateKey:key value:value];
    }];
}

- (void)preference:(MDPreference *)preference didUpdateKey:(NSString *)key value:(id)value origin:(id)origin {
    if (![_parent respondsToSelector:@selector(preference:didUpdateKey:value:origin:)]) return;

    [self _respondWithBlock:^{
        [self->_parent preference:preference didUpdateKey:key value:value origin:origin];
    }];
}

@end

@implementation MDPreference (NSKeyValueCoding)

- (id)valueForKey:(NSString *)key{
    NSParameterAssert([key length]);
    
    return [self objectForKey:key];
}

- (void)setValue:(id)value forKey:(NSString *)key{
    NSParameterAssert([key length]);
    
    [self setObject:value forKey:key];
}

- (id)valueForUndefinedKey:(NSString *)key {
    NSParameterAssert([key length]);
    
    return [self objectForKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    NSParameterAssert([key length]);
    
    [self setObject:value forKey:key];
}

- (void)setObject:(id<NSObject, NSCopying, NSCoding>)anObject forKeyedSubscript:(NSString *)key{
    NSParameterAssert([key length]);
    
    [self setObject:anObject forKey:key];
}

- (id)objectForKeyedSubscript:(NSString *)key{
    NSParameterAssert([key length]);
    
    return [self objectForKey:key];
}

- (NSDictionary<NSString *,id> *)dictionaryWithValuesForKeys:(NSArray<NSString *> *)keys{
    NSParameterAssert(keys && [keys count]);

    __block NSDictionary<NSString *,id> *dictionary = nil;
    [self _performWithBlock:^{
        dictionary = [self->_dictionary dictionaryWithValuesForKeys:keys];
    }];

    return dictionary;
}

- (void)setValuesForKeysWithDictionary:(NSDictionary<NSString *, id> *)keyedValues {
    NSParameterAssert(!keyedValues || [keyedValues isKindOfClass:NSDictionary.class]);

    [self _performWithBlock:^{
        [self _setDictionary:keyedValues];
    }];
}

@end

id MDPreferenceBoxValue(NSInvocation *invocation, NSUInteger index) {
    NSMethodSignature *signature = [invocation methodSignature];
    const char *type = [signature getArgumentTypeAtIndex:index];

    id obj = nil;
    if (strcmp(type, @encode(id)) == 0) {
        [invocation getArgument:&obj atIndex:index];
        if (obj) {
            if (@available(iOS 8, *)) CFRetain((__bridge void *)obj);
        }
    } else if (strcmp(type, @encode(void *)) == 0) {
        void *actual = NULL;
        [invocation getArgument:&actual atIndex:index];
        obj = [NSValue valueWithPointer:actual];
    } else if (strcmp(type, @encode(CGPoint)) == 0) {
        CGPoint actual = CGPointZero;
        [invocation getArgument:&actual atIndex:index];
        obj = [NSValue valueWithCGPoint:actual];
    } else if (strcmp(type, @encode(CGSize)) == 0) {
        CGSize actual = CGSizeZero;
        [invocation getArgument:&actual atIndex:index];
        obj = [NSValue valueWithCGSize:actual];
    } else if (strcmp(type, @encode(CGRect)) == 0) {
        CGRect actual = CGRectZero;
        [invocation getArgument:&actual atIndex:index];
        obj = [NSValue valueWithCGRect:actual];
    } else if (strcmp(type, @encode(CGVector)) == 0) {
        CGVector actual = CGVectorMake(0, 0);
        [invocation getArgument:&actual atIndex:index];
        obj = [NSValue valueWithCGVector:actual];
    } else if (strcmp(type, @encode(CGAffineTransform)) == 0) {
        CGAffineTransform actual = CGAffineTransformIdentity;
        [invocation getArgument:&actual atIndex:index];
        obj = [NSValue valueWithCGAffineTransform:actual];
    } else if (strcmp(type, @encode(UIOffset)) == 0) {
        UIOffset actual = UIOffsetZero;
        [invocation getArgument:&actual atIndex:index];
        obj = [NSValue valueWithUIOffset:actual];
    } else if (strcmp(type, @encode(UIEdgeInsets)) == 0) {
        UIEdgeInsets actual = UIEdgeInsetsZero;
        [invocation getArgument:&actual atIndex:index];
        obj = [NSValue valueWithUIEdgeInsets:actual];
    } else if (strcmp(type, @encode(NSRange)) == 0) {
        NSRange actual = NSMakeRange(0, 0);
        [invocation getArgument:&actual atIndex:index];
        obj = [NSValue valueWithRange:actual];
    } else if (strcmp(type, @encode(double)) == 0) {
        double actual = 0;
        [invocation getArgument:&actual atIndex:index];
        obj = [NSNumber numberWithDouble:actual];
    } else if (strcmp(type, @encode(float)) == 0) {
        float actual = 0;
        [invocation getArgument:&actual atIndex:index];
        obj = [NSNumber numberWithFloat:actual];
    } else if (strcmp(type, @encode(bool)) == 0) {
        bool actual;
        [invocation getArgument:&actual atIndex:index];
        obj = [NSNumber numberWithBool:actual];
    } else if (strcmp(type, @encode(int)) == 0) {
        int actual = 0;
        [invocation getArgument:&actual atIndex:index];
        obj = [NSNumber numberWithInt:actual];
    } else if (strcmp(type, @encode(short)) == 0) {
        short actual = 0;
        [invocation getArgument:&actual atIndex:index];
        obj = [NSNumber numberWithShort:actual];
    } else if (strcmp(type, @encode(char)) == 0) {
        char actual = 0;
        [invocation getArgument:&actual atIndex:index];
        obj = [NSNumber numberWithChar:actual];
    } else if (strcmp(type, @encode(long)) == 0) {
        long actual = 0;
        [invocation getArgument:&actual atIndex:index];
        obj = [NSNumber numberWithLong:actual];
    } else if (strcmp(type, @encode(long long)) == 0) {
        long long actual = 0;
        [invocation getArgument:&actual atIndex:index];
        obj = [NSNumber numberWithLongLong:actual];
    } else if (strcmp(type, @encode(unsigned int)) == 0) {
        unsigned int actual = 0;
        [invocation getArgument:&actual atIndex:index];
        obj = [NSNumber numberWithUnsignedInt:actual];
    } else if (strcmp(type, @encode(unsigned short)) == 0) {
        unsigned short actual = 0;
        [invocation getArgument:&actual atIndex:index];
        obj = [NSNumber numberWithUnsignedShort:actual];
    } else if (strcmp(type, @encode(unsigned char)) == 0) {
        unsigned char actual = 0;
        [invocation getArgument:&actual atIndex:index];
        obj = [NSNumber numberWithUnsignedChar:actual];
    } else if (strcmp(type, @encode(unsigned long)) == 0) {
        unsigned long actual = 0;
        [invocation getArgument:&actual atIndex:index];
        obj = [NSNumber numberWithUnsignedLong:actual];
    } else if (strcmp(type, @encode(unsigned long long)) == 0) {
        unsigned long long actual = 0;
        [invocation getArgument:&actual atIndex:index];
        obj = [NSNumber numberWithUnsignedLongLong:actual];
    } else {
        if (@available(iOS 11, *)) {
            if (strcmp(type, @encode(NSDirectionalEdgeInsets)) == 0) {
                NSDirectionalEdgeInsets actual = NSDirectionalEdgeInsetsZero;
                [invocation getArgument:&actual atIndex:index];
                obj = [NSValue valueWithDirectionalEdgeInsets:actual];
            }
        }
    }
    return obj;
}

#define MDPreferenceReverseBoxValue(encoding, type, method)     \
if (strcmp(encoding, @encode(type)) == 0) {                     \
type result = [number method];                              \
[invocation setReturnValue:&result];                        \
return;                                                     \
}

void MDPreferenceReturnValue(NSInvocation *invocation, id obj) {
    NSMethodSignature *signature = [invocation methodSignature];
    const char *type = [signature methodReturnType];

    if (strcmp(type, @encode(id)) == 0) {
        [invocation setReturnValue:&obj];
        return;
    }
    NSNumber *number = obj;
    MDPreferenceReverseBoxValue(type, CGPoint, CGPointValue)
    MDPreferenceReverseBoxValue(type, CGSize, CGSizeValue)
    MDPreferenceReverseBoxValue(type, CGRect, CGRectValue)
    MDPreferenceReverseBoxValue(type, CGVector, CGVectorValue)
    MDPreferenceReverseBoxValue(type, CGAffineTransform, CGAffineTransformValue)
    MDPreferenceReverseBoxValue(type, UIOffset, UIOffsetValue)
    MDPreferenceReverseBoxValue(type, UIEdgeInsets, UIEdgeInsetsValue)
    MDPreferenceReverseBoxValue(type, NSRange, rangeValue)
    MDPreferenceReverseBoxValue(type, double, doubleValue)
    MDPreferenceReverseBoxValue(type, float, floatValue)
    MDPreferenceReverseBoxValue(type, bool, boolValue)
    MDPreferenceReverseBoxValue(type, int, intValue)
    MDPreferenceReverseBoxValue(type, char, charValue)
    MDPreferenceReverseBoxValue(type, short, shortValue)
    MDPreferenceReverseBoxValue(type, long, longValue)
    MDPreferenceReverseBoxValue(type, unsigned int, unsignedIntValue)
    MDPreferenceReverseBoxValue(type, unsigned char, unsignedCharValue)
    MDPreferenceReverseBoxValue(type, unsigned short, unsignedShortValue)
    MDPreferenceReverseBoxValue(type, unsigned long, unsignedLongValue)
    MDPreferenceReverseBoxValue(type, unsigned long long, unsignedLongLongValue)

    if (@available(iOS 11, *)) {
        if ([obj isKindOfClass:[NSValue class]]) {
            MDPreferenceReverseBoxValue(type, NSDirectionalEdgeInsets, directionalEdgeInsetsValue)
        }
    }
}
