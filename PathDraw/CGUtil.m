//
// Created by Li Shuo on 13-8-11.
// Copyright (c) 2013 com.menic. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "CGUtil.h"

BOOL pointIsNearPoint(CGPoint point1, CGPoint point2){
    return ABS(point1.x - point2.x) < 15 && ABS(point1.y - point2.y) < 15;
}

CGFloat distanceBetweenPoints(CGPoint point1, CGPoint point2){
    return sqrtf((point2.x - point1.x) * (point2.x - point1.x) + (point2.y - point1.y) * (point2.y - point1.y));
}

