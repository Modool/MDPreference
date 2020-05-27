//
//  MDPreference+Private.h
//  MDPreference
//
//  Created by xulinfeng on 2017/9/26.
//  Copyright © 2017年 bilibili. All rights reserved.
//

#import "MDPreference.h"

@interface MDPreferencePropertyInfo : NSObject

@property (nonatomic, copy, readonly) NSString *name;

@property (nonatomic, assign, readonly) SEL getter;
@property (nonatomic, assign, readonly) SEL setter;

+ (instancetype)infoWithName:(NSString *)name getter:(SEL)getter setter:(SEL)setter;

+ (NSArray<MDPreferencePropertyInfo *> *)propertyInfosWithProtocol:(Protocol *)protocol dictionary:(NSDictionary<NSString *, MDPreferencePropertyInfo *> **)dictionary;

@end

@interface MDPreference () {
    @protected
    NSArray<MDPreferencePropertyInfo *> *_propertyInfos;

    @private
    NSDictionary<NSString *, MDPreferencePropertyInfo *> *_propertyInfoDictionary;
    NSMutableDictionary *_dictionary;
    void *_queueTag;
}

@end

FOUNDATION_EXTERN id MDPreferenceBoxValue(NSInvocation *invocation, NSUInteger index);

FOUNDATION_EXTERN void MDPreferenceReturnValue(NSInvocation *invocation, id obj);
