//
//  NSDictionary+SDExtensions.m
//  walmart
//
//  Created by Brandon Sneed on 6/27/11.
//  Copyright 2011 Set Direction. All rights reserved.
//

#import "NSDictionary+SDExtensions.h"

@implementation NSDictionary (NSDictionary_SDExtensions)

- (NSString *)stringForKey:(NSString *)key
{
    id obj = [self objectForKey:key];
    if ([obj isKindOfClass:[NSString class]])
        return obj;
    else
    if ([obj isKindOfClass:[NSNumber class]])
        return [obj stringValue];
    return nil;
}

- (NSInteger)intForKey:(NSString *)key { return [self integerForKey:key]; }
- (NSInteger)integerForKey:(NSString *)key
{
    id obj = [self objectForKey:key];
    if ([obj isKindOfClass:[NSString class]])
        return [obj integerValue];
    else
    if ([obj isKindOfClass:[NSNumber class]])
        return [obj integerValue];
    return 0;
}

- (NSUInteger)unsignedIntForKey:(NSString *)key { return [self unsignedIntegerForKey:key]; }
- (NSUInteger)unsignedIntegerForKey:(NSString *)key
{
    id obj = [self objectForKey:key];
    if ([obj isKindOfClass:[NSString class]])
    {
        NSNumber *number = [NSNumber numberWithInteger:[obj integerValue]];
        return [number unsignedIntegerValue];
    }
    else
    if ([obj isKindOfClass:[NSNumber class]])
        return [obj unsignedIntegerValue];
    return 0;
}

- (float)floatForKey:(NSString *)key
{
    id obj = [self objectForKey:key];
    if ([obj isKindOfClass:[NSString class]])
        return [obj floatValue];
    else
    if ([obj isKindOfClass:[NSNumber class]])
        return [obj floatValue];
    return 0;
}

- (double)doubleForKey:(NSString *)key
{
    id obj = [self objectForKey:key];
    if ([obj isKindOfClass:[NSString class]])
        return [obj doubleValue];
    else
    if ([obj isKindOfClass:[NSNumber class]])
        return [obj doubleValue];
    return 0;
}

- (long long)longLongForKey:(NSString *)key
{
    id obj = [self objectForKey:key];
    if ([obj isKindOfClass:[NSString class]])
        return [obj longLongValue];
    else
    if ([obj isKindOfClass:[NSNumber class]])
        return [obj longLongValue];
    return 0;
}

- (BOOL)boolForKey:(NSString *)key
{
    id obj = [self objectForKey:key];
    if ([obj isKindOfClass:[NSString class]])
        return [obj boolValue];
    else
    if ([obj isKindOfClass:[NSNumber class]])
        return [obj boolValue];
    return 0;
}

@end