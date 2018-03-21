//
//  MDPreference+Private.h
//  MDPreference
//
//  Created by xulinfeng on 2017/9/26.
//  Copyright © 2017年 bilibili. All rights reserved.
//

#import "MDPreference.h"
#import "MDPreference.h"

@interface MDPreference ()

@property (nonatomic, strong) NSMutableDictionary *keyValues;

@end

FOUNDATION_EXTERN id MDPreferenceBoxValue(const char *type, ...);

FOUNDATION_EXTERN void * MDPreferenceReverseBoxValue(const char *type, id obj, NSUInteger length);
