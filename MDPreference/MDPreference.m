//
//  MDPreference.m
//  MDPreference
//
//  Created by xulinfeng on 2017/9/25.
//  Copyright © 2017年 bilibili. All rights reserved.
//

#import <objc/runtime.h>

#import "MDPreference.h"
#import "MDPreference+Private.h"

NSString * const MDPreferenceSetterPredicateString = @"^set[A-Z]([a-z]|[A-Z]|[0-9]|_)*:$";
NSString * const MDPreferenceGetterPredicateString = @"^[a-z]([a-z]|[A-Z]|[0-9]|_)*$";

NSString * const MDPreferenceEncodeKey = @"keyValues";

@implementation MDPreference

+ (instancetype)preferenceWithProtocol:(Protocol *)protocol;{
    return [[self alloc] initWithProtocol:protocol];
}

- (instancetype)initWithProtocol:(Protocol *)protocol;{
    if (self = [super init]) {
        _protocol = protocol;
    }
    return self;
}

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
    MDPreference *preference = [[[self class] alloc] init];
    preference.keyValues = [[self keyValues] copy];
    
    return preference;
}

#pragma mark - NSObject Invocation

- (void)forwardInvocation:(NSInvocation *)anInvocation{
    NSMethodSignature *signature = [anInvocation methodSignature];
    NSString *selectorString = NSStringFromSelector([anInvocation selector]);
    
    NSPredicate *setterPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", MDPreferenceSetterPredicateString];
    NSPredicate *getterPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", MDPreferenceGetterPredicateString];
    
    BOOL setter = [setterPredicate evaluateWithObject:selectorString];
    BOOL getter = [getterPredicate evaluateWithObject:selectorString];
    if (setter || getter) {
        if (setter) {
            NSString *prefix = [[selectorString substringWithRange:NSMakeRange(3, 1)] lowercaseString];
            NSString *suffix = [selectorString substringWithRange:NSMakeRange(4, [selectorString length] - 5)];
            
            NSString *key = [prefix stringByAppendingString:suffix];
            const char *type = [signature getArgumentTypeAtIndex:2];
            
            void *value = NULL;
            [anInvocation getArgument:&value atIndex:2];
            
            id result = MDPreferenceBoxValue(type, value);
            [self setObject:result forKey:key];
        }  if (getter) {
            NSString *key = selectorString;
            
            NSUInteger methodReturnLength = [signature methodReturnLength];
            const char *type = [signature methodReturnType];
            
            id value = [self objectForKey:key];
            void *result = MDPreferenceReverseBoxValue(type, value, methodReturnLength);
            
            [anInvocation setReturnValue:&result];
        }
        
        anInvocation.target = nil;
        [anInvocation invoke];
    } else {
        [super forwardInvocation:anInvocation];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector{
    struct objc_method_description description = protocol_getMethodDescription(_protocol, aSelector, YES, YES);
    if (description.name && description.types) return [NSMethodSignature signatureWithObjCTypes:description.types];
    
    description = protocol_getMethodDescription(_protocol, aSelector, NO, YES);
    if (description.name && description.types) return [NSMethodSignature signatureWithObjCTypes:description.types];
    
    return [super methodSignatureForSelector:aSelector];
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
    
    self.keyValues.dictionary = dictionary;
    
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
    id value = [[self keyValues] valueForKeyPath:keyPath];
    
    return value == [NSNull null] ? nil : value;
}

- (void)setValue:(id)value forKeyPath:(NSString *)keyPath;{
    NSParameterAssert([keyPath length]);
    
    id originValue = [self valueForKeyPath:keyPath];
    
    [self preference:self willUpdateKey:keyPath value:value];
    [[self keyValues] setValue:value forKeyPath:keyPath];
    [self preference:self didUpdateKey:keyPath value:value origin:originValue];
}

#pragma mark - private

- (id<NSObject, NSCopying, NSCoding>)objectForKey:(NSString *)aKey;{
    id value = [self keyValues][aKey];
    
    return value == [NSNull null] ? nil : value;
}

- (void)setObject:(id<NSObject, NSCopying, NSCoding>)object forKey:(NSString *)key{
    if (![key length]) return;
    if (object && ![object respondsToSelector:@selector(copyWithZone:)]) return;
    if (object && ![object respondsToSelector:@selector(encodeWithCoder:)]) return;
    if (object && ![object respondsToSelector:@selector(initWithCoder:)]) return;
    
    object = object ?: [NSNull null];
    id originValue = [self objectForKey:key];
    
    [self preference:self willUpdateKey:key value:object];
    [[self keyValues] setObject:object forKey:key];
    [self preference:self didUpdateKey:key value:object origin:originValue];
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
    NSParameterAssert([key length]);
    
    [self setObject:value forKey:key];
}

- (id)valueForUndefinedKey:(NSString *)key;{
    NSParameterAssert([key length]);
    
    return [self objectForKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key;{
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
    
    return [[self keyValues] dictionaryWithValuesForKeys:keys];
}

- (void)setValuesForKeysWithDictionary:(NSDictionary<NSString *, id> *)keyedValues;{
    NSParameterAssert(keyedValues && [keyedValues count]);
    
    self.dictionary = keyedValues;
}

@end

id MDPreferenceBoxValue(const char *type, ...) {
    va_list v;
    va_start(v, type);
    id obj = nil;
    if (strcmp(type, @encode(id)) == 0) {
        id actual = va_arg(v, id);
        obj = actual;
    } else if (strcmp(type, @encode(void *)) == 0) {
        void *actual = va_arg(v, void *);
        obj = [NSValue valueWithPointer:actual];
    } else if (strcmp(type, @encode(CGPoint)) == 0) {
        CGPoint actual = (CGPoint)va_arg(v, CGPoint);
        obj = [NSValue valueWithCGPoint:actual];
    } else if (strcmp(type, @encode(CGSize)) == 0) {
        CGSize actual = (CGSize)va_arg(v, CGSize);
        obj = [NSValue valueWithCGSize:actual];
    } else if (strcmp(type, @encode(CGRect)) == 0) {
        CGRect actual = (CGRect)va_arg(v, CGRect);
        obj = [NSValue valueWithCGRect:actual];
    } else if (strcmp(type, @encode(CGVector)) == 0) {
        CGVector actual = (CGVector)va_arg(v, CGVector);
        obj = [NSValue valueWithCGVector:actual];
    } else if (strcmp(type, @encode(CGAffineTransform)) == 0) {
        CGAffineTransform actual = (CGAffineTransform)va_arg(v, CGAffineTransform);
        obj = [NSValue valueWithCGAffineTransform:actual];
    } else if (strcmp(type, @encode(UIOffset)) == 0) {
        UIOffset actual = (UIOffset)va_arg(v, UIOffset);
        obj = [NSValue valueWithUIOffset:actual];
    } else if (strcmp(type, @encode(UIEdgeInsets)) == 0) {
        UIEdgeInsets actual = (UIEdgeInsets)va_arg(v, UIEdgeInsets);
        obj = [NSValue valueWithUIEdgeInsets:actual];
    } else if (strcmp(type, @encode(NSRange)) == 0) {
        NSRange actual = (NSRange)va_arg(v, NSRange);
        obj = [NSValue valueWithRange:actual];
    } else if (strcmp(type, @encode(NSDirectionalEdgeInsets)) == 0) {
        NSDirectionalEdgeInsets actual = (NSDirectionalEdgeInsets)va_arg(v, NSDirectionalEdgeInsets);
        obj = [NSValue valueWithDirectionalEdgeInsets:actual];
    } else if (strcmp(type, @encode(double)) == 0) {
        double actual = (double)va_arg(v, double);
        obj = [NSNumber numberWithDouble:actual];
    } else if (strcmp(type, @encode(float)) == 0) {
        float actual = (float)va_arg(v, double);
        obj = [NSNumber numberWithFloat:actual];
    } else if (strcmp(type, @encode(bool)) == 0) {
        bool actual = (bool)va_arg(v, int);
        obj = [NSNumber numberWithBool:actual];
    } else if (strcmp(type, @encode(int)) == 0) {
        int actual = (int)va_arg(v, int);
        obj = [NSNumber numberWithInt:actual];
    } else if (strcmp(type, @encode(short)) == 0) {
        short actual = (short)va_arg(v, int);
        obj = [NSNumber numberWithShort:actual];
    } else if (strcmp(type, @encode(char)) == 0) {
        char actual = (char)va_arg(v, int);
        obj = [NSNumber numberWithChar:actual];
    } else if (strcmp(type, @encode(long)) == 0) {
        long actual = (long)va_arg(v, long);
        obj = [NSNumber numberWithLong:actual];
    } else if (strcmp(type, @encode(long long)) == 0) {
        long long actual = (long long)va_arg(v, long long);
        obj = [NSNumber numberWithLongLong:actual];
    } else if (strcmp(type, @encode(unsigned int)) == 0) {
        unsigned int actual = (unsigned int)va_arg(v, unsigned int);
        obj = [NSNumber numberWithUnsignedInt:actual];
    } else if (strcmp(type, @encode(unsigned short)) == 0) {
        unsigned short actual = (unsigned short)va_arg(v, unsigned int);
        obj = [NSNumber numberWithUnsignedShort:actual];
    } else if (strcmp(type, @encode(unsigned char)) == 0) {
        unsigned char actual = (unsigned char)va_arg(v, unsigned int);
        obj = [NSNumber numberWithUnsignedChar:actual];
    } else if (strcmp(type, @encode(unsigned long)) == 0) {
        unsigned long actual = (unsigned long)va_arg(v, unsigned long);
        obj = [NSNumber numberWithUnsignedLong:actual];
    } else if (strcmp(type, @encode(unsigned long long)) == 0) {
        unsigned long long actual = (unsigned long long)va_arg(v, unsigned long long);
        obj = [NSNumber numberWithUnsignedLongLong:actual];
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
               strcmp(type, @encode(CGRect)) == 0 ||
               strcmp(type, @encode(CGVector)) == 0 ||
               strcmp(type, @encode(CGAffineTransform)) == 0 ||
               strcmp(type, @encode(UIOffset)) == 0 ||
               strcmp(type, @encode(UIEdgeInsets)) == 0 ||
               strcmp(type, @encode(NSRange)) == 0 ||
               strcmp(type, @encode(NSDirectionalEdgeInsets)) == 0 ||
               strcmp(type, @encode(double)) == 0 ||
               strcmp(type, @encode(float)) == 0 ||
               strcmp(type, @encode(bool)) == 0 ||
               strcmp(type, @encode(int)) == 0 ||
               strcmp(type, @encode(char)) == 0 ||
               strcmp(type, @encode(short)) == 0 ||
               strcmp(type, @encode(long)) == 0 ||
               strcmp(type, @encode(long long)) == 0 ||
               strcmp(type, @encode(unsigned int)) == 0 ||
               strcmp(type, @encode(unsigned char)) == 0 ||
               strcmp(type, @encode(unsigned short)) == 0 ||
               strcmp(type, @encode(unsigned long)) == 0 ||
               strcmp(type, @encode(unsigned long long)) == 0) {
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
 
