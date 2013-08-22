//
// Created by Li Shuo on 13-8-22.
// Copyright (c) 2013 com.menic. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "DrawDocument.h"


@implementation DrawDocument {

}

-(id)init{
    self = [super init];

    if (self){
        _shapes = [NSMutableArray array];
    }

    return self;
}
@end