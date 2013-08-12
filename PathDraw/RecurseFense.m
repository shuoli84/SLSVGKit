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

- (id)initWithObject:(id)object functionKey:(const void *)key {
    self = [super init];
    if(self){
        if([object associatedValueForKey:key] != nil){
            return nil;
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