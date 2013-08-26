//
// Created by Li Shuo on 13-8-11.
// Copyright (c) 2013 com.menic. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "RecurseFense.h"
#import "NSObject+AssociatedObjects.h"

@interface RecurseFense()
@property (nonatomic, weak) id object;
@property (nonatomic, strong) NSMutableSet *lockNames;
@end

@implementation RecurseFense {
    const void * _key;
}

+ (id)fenseObject {
    static id object;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        object = [[NSObject alloc]init];
    });

    return object;
}

- (id)initWithObject:(id)object functionKey:(const void *)key{
    return [self initWithObject:object functionKey:key lockName:@""];
}

- (id)initWithObject:(id)object functionKey:(const void *)key lockName:(NSString*)lockName{
    self = [super init];
    if(self){
        if(lockName == nil){
            lockName = @"";
        }

        if([object associatedValueForKey:key] != nil){
            RecurseFense *fense = [object associatedValueForKey:key];
            if([fense.lockNames containsObject:lockName]){
                return nil;
            }

            [fense.lockNames addObject:lockName];
            return fense;
        }

        _key = key;
        _object = object;
        [object associateValue:[NSNumber numberWithBool:YES] withKey:key];
    }

    return self;
}

-(void)dealloc{
    [_object associateValue:nil withKey:_key];
}
@end