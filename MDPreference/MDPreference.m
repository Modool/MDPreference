//
//  MDPreference.m
//  MDPreference
//
//  Created by xulinfeng on 2017/9/25.
//  Copyright © 2017年 bilibili. All rights reserved.
//

#import "MDPreference.h"
#import "MDPreference+Private.h"

NSString * const MDPreferenceSetPredicateString = @"^set[A-Z]([a-z]|[A-Z]|[0-9]|_)*:$";
NSString * const MDPreferenceGetPredicateString = @"^[a-z]([a-z]|[A-Z]|[0-9]|_)*$";

NSString * const MDPreferenceEncodeKey = @"keyValues";

@implementation MDPreference

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:[self keyValues] forKey:MDPreferenceEncodeKey];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super init]) {
        self.keyValues = [aDecoder decodeObjectForKey:MDPreferenceEncodeKey];
    }
    return self;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding{
    return [NSDictionary supportsSecureCoding];
}

#pragma mark - NSCopy

- (id)copyWithZone:(nullable NSZone *)zone;{
    MDPreference *preference = [[self class] init];
    preference.keyValues = [[self keyValues] copy];
    
    return preference;
}

#pragma mark - NSObject Invocation

- (void)forwardInvocation:(NSInvocation *)anInvocation{
    NSMethodSignature *signature = [anInvocation methodSignature];
    NSString *selectorString = NSStringFromSelector([anInvocation selector]);
    if ([[NSPredicate predicateWithFormat:@"SELF MATCHES %@", MDPreferenceSetPredicateString] evaluateWithObject:selectorString]) {
        NSString *prefix = [[selectorString substringWithRange:NSMakeRange(3, 1)] lowercaseString];
        NSString *suffix = [selectorString substringWithRange:NSMakeRange(4, [selectorString length] - 5)];
        
        NSString *key = [prefix stringByAppendingString:suffix];
        const char *type = [signature getArgumentTypeAtIndex:2];
        
        void *value = NULL;
        [anInvocation getArgument:&value atIndex:2];
        
        id result = MDPreferenceBoxValue(type, value);
        if (result) [self setObject:result forKey:key];
        
        anInvocation.target = nil;
        [anInvocation invoke];
        
    } else if ([[NSPredicate predicateWithFormat:@"SELF MATCHES %@", MDPreferenceGetPredicateString] evaluateWithObject:selectorString]) {
        NSString *key = selectorString;
    
        NSUInteger methodReturnLength = [signature methodReturnLength];
        const char *type = [signature methodReturnType];
        
        id value = [self objectForKey:key];
        void *result = MDPreferenceReverseBoxValue(type, value, methodReturnLength);
        
        [anInvocation setReturnValue:&result];
        
        anInvocation.target = nil;
        [anInvocation invoke];
        
    } else {
        [super forwardInvocation:anInvocation];
    }
}

#pragma mark - accessor

- (NSMutableDictionary *)keyValues{
    if (!_keyValues) {
        _keyValues = [NSMutableDictionary new];
    }
    return _keyValues;
}

- (NSString *)description{
    return [[self keyValues] description];
}

- (void)setDictionary:(NSDictionary *)dictionary;{
    NSParameterAssert(dictionary && [dictionary count]);
    
    for (NSString *key in [dictionary allKeys]) {
        [self willChangeValueForKey:key];
    }
    [[self keyValues] setValuesForKeysWithDictionary:dictionary];
    
    for (NSString *key in [dictionary allKeys]) {
        [self didChangeValueForKey:key];
    }
}

- (NSDictionary *)dictionary{
    return [[self keyValues] copy];
}

#pragma mark - KVC

- (BOOL)validateValue:(inout id *)ioValue forKey:(NSString *)inKey error:(out NSError **)outError;{
    return [[self keyValues] validateValue:ioValue forKey:inKey error:outError];
}

- (BOOL)validateValue:(inout id*)ioValue forKeyPath:(NSString *)inKeyPath error:(out NSError **)outError;{
    return [[self keyValues] validateValue:ioValue forKeyPath:inKeyPath error:outError];
}

- (id)valueForKeyPath:(NSString *)keyPath;{
    return [[self keyValues] valueForKeyPath:keyPath];
}

- (void)setValue:(id)value forKeyPath:(NSString *)keyPath;{
    NSParameterAssert(value && [keyPath length]);
    
    id originValue = [[self keyValues] valueForKeyPath:keyPath];
    if ([originValue isEqual:value]) return;
    
    [self preference:self willUpdateKey:keyPath value:value];
    [[self keyValues] setValue:value forKeyPath:keyPath];
    [self preference:self didUpdateKey:keyPath value:value origin:originValue];
}

#pragma mark - private

- (id<NSObject, NSCopying, NSCoding>)objectForKey:(NSString *)aKey;{
    return [self keyValues][aKey];
}

- (void)setObject:(id<NSObject, NSCopying, NSCoding>)anObject forKey:(NSString *)aKey{
    if (!anObject || ![aKey length]) return;
    if (![anObject respondsToSelector:@selector(copyWithZone:)]) return;
    if (![anObject respondsToSelector:@selector(encodeWithCoder:)]) return;
    if (![anObject respondsToSelector:@selector(initWithCoder:)]) return;
    
    id originValue = [[self keyValues] objectForKey:aKey];
    if ([originValue isEqual:anObject]) return;
    
    
    [self preference:self willUpdateKey:aKey value:anObject];
    self.keyValues[aKey] = anObject;
    [self preference:self didUpdateKey:aKey value:anObject origin:originValue];
}

#pragma MDPreference

- (void)preference:(MDPreference *)preference willUpdateKey:(NSString *)key value:(id)value;{
    if ([[self parent] respondsToSelector:@selector(preference:willUpdateKey:value:)]) [[self parent] preference:preference willUpdateKey:key value:value];
}

- (void)preference:(MDPreference *)preference didUpdateKey:(NSString *)key value:(id)value origin:(id)origin;{
    if ([[self parent] respondsToSelector:@selector(preference:didUpdateKey:value:origin:)]) [[self parent] preference:preference didUpdateKey:key value:value origin:origin];
}

@end

@implementation MDPreference (NSKeyValueCoding)

- (id)valueForKey:(NSString *)key{
    NSParameterAssert([key length]);
    
    return [self objectForKey:key];
}

- (void)setValue:(id)value forKey:(NSString *)key{
    NSParameterAssert(value && [key length]);
    
    [self setObject:value forKey:key];
}

- (id)valueForUndefinedKey:(NSString *)key;{
    NSParameterAssert([key length]);
    
    return [self objectForKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key;{
    NSParameterAssert(value && [key length]);
    
    [self setObject:value forKey:key];
}

- (void)setObject:(id<NSObject, NSCopying, NSCoding>)anObject forKeyedSubscript:(NSString *)key{
    NSParameterAssert(anObject && [key length]);
    
    [self setObject:anObject forKey:key];
}

- (id)objectForKeyedSubscript:(NSString *)key{
    NSParameterAssert([key length]);
    
    return [self objectForKey:key];
}

- (void)setValuesForKeysWithDictionary:(NSDictionary<NSString *, id> *)keyedValues;{
    [[self keyValues] setValuesForKeysWithDictionary:keyedValues];
}

@end


id MDPreferenceBoxValue(const char *type, ...) {
    va_list v;
    va_start(v, type);
    id obj = nil;
    if (strcmp(type, @encode(id)) == 0) {
        id actual = va_arg(v, id);
        obj = actual;
    } else if (strcmp(type, @encode(CGPoint)) == 0) {
        CGPoint actual = (CGPoint)va_arg(v, CGPoint);
        obj = [NSValue value:&actual withObjCType:type];
    } else if (strcmp(type, @encode(CGSize)) == 0) {
        CGSize actual = (CGSize)va_arg(v, CGSize);
        obj = [NSValue value:&actual withObjCType:type];
    } else if (strcmp(type, @encode(UIEdgeInsets)) == 0) {
        UIEdgeInsets actual = (UIEdgeInsets)va_arg(v, UIEdgeInsets);
        obj = [NSValue value:&actual withObjCType:type];
    } else if (strcmp(type, @encode(double)) == 0) {
        double actual = (double)va_arg(v, double);
        obj = [NSNumber numberWithDouble:actual];
    } else if (strcmp(type, @encode(float)) == 0) {
        float actual = (float)va_arg(v, double);
        obj = [NSNumber numberWithFloat:actual];
    } else if (strcmp(type, @encode(int)) == 0) {
        int actual = (int)va_arg(v, int);
        obj = [NSNumber numberWithInt:actual];
    } else if (strcmp(type, @encode(long)) == 0) {
        long actual = (long)va_arg(v, long);
        obj = [NSNumber numberWithLong:actual];
    } else if (strcmp(type, @encode(long long)) == 0) {
        long long actual = (long long)va_arg(v, long long);
        obj = [NSNumber numberWithLongLong:actual];
    } else if (strcmp(type, @encode(short)) == 0) {
        short actual = (short)va_arg(v, int);
        obj = [NSNumber numberWithShort:actual];
    } else if (strcmp(type, @encode(char)) == 0) {
        char actual = (char)va_arg(v, int);
        obj = [NSNumber numberWithChar:actual];
    } else if (strcmp(type, @encode(bool)) == 0) {
        bool actual = (bool)va_arg(v, int);
        obj = [NSNumber numberWithBool:actual];
    } else if (strcmp(type, @encode(unsigned char)) == 0) {
        unsigned char actual = (unsigned char)va_arg(v, unsigned int);
        obj = [NSNumber numberWithUnsignedChar:actual];
    } else if (strcmp(type, @encode(unsigned int)) == 0) {
        unsigned int actual = (unsigned int)va_arg(v, unsigned int);
        obj = [NSNumber numberWithUnsignedInt:actual];
    } else if (strcmp(type, @encode(unsigned long)) == 0) {
        unsigned long actual = (unsigned long)va_arg(v, unsigned long);
        obj = [NSNumber numberWithUnsignedLong:actual];
    } else if (strcmp(type, @encode(unsigned long long)) == 0) {
        unsigned long long actual = (unsigned long long)va_arg(v, unsigned long long);
        obj = [NSNumber numberWithUnsignedLongLong:actual];
    } else if (strcmp(type, @encode(unsigned short)) == 0) {
        unsigned short actual = (unsigned short)va_arg(v, unsigned int);
        obj = [NSNumber numberWithUnsignedShort:actual];
    }
    va_end(v);
    return obj;
}

void * MDPreferenceReverseBoxValue(const char *type, id obj, NSUInteger length) {
    void *value = NULL;
    if (strcmp(type, @encode(id)) == 0) {
        value = (__bridge void *)obj;
    } else if (strcmp(type, @encode(CGPoint)) == 0 ||
               strcmp(type, @encode(CGSize)) == 0 ||
               strcmp(type, @encode(UIEdgeInsets)) == 0 ||
               strcmp(type, @encode(double)) == 0 ||
               strcmp(type, @encode(float)) == 0 ||
               strcmp(type, @encode(int)) == 0 ||
               strcmp(type, @encode(long)) == 0 ||
               strcmp(type, @encode(long long)) == 0 ||
               strcmp(type, @encode(short)) == 0 ||
               strcmp(type, @encode(char)) == 0 ||
               strcmp(type, @encode(bool)) == 0 ||
               strcmp(type, @encode(unsigned char)) == 0 ||
               strcmp(type, @encode(unsigned int)) == 0 ||
               strcmp(type, @encode(unsigned long)) == 0 ||
               strcmp(type, @encode(unsigned long long)) == 0 ||
               strcmp(type, @encode(unsigned short)) == 0) {
        if ([obj isKindOfClass:[NSValue class]]) {
            if (@available(iOS 11, *)) {
                [(NSValue *)obj getValue:&value size:length];
            } else {
                [(NSValue *)obj getValue:&value];
            }
        }
    }
    return value;
}
