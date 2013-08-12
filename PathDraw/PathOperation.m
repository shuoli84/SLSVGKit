//
// Created by Li Shuo on 13-8-11.
// Copyright (c) 2013 com.menic. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "PathOperation.h"


@implementation PathOperation

-(id)init{
    self = [super init];
    if (self){
        _locationType = LocationTypeAbsolute;
    }
    return self;
}

-(PathOperation *)copy{
    PathOperation *op = [[PathOperation alloc]init];
    op.operationType = _operationType;
    op.location = _location;
    op.locationType = _locationType;
    op.controlPoint1 = _controlPoint1;
    op.controlPoint2 = _controlPoint2;
    return op;
}
@end

