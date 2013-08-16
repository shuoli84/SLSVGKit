//
// Created by Li Shuo on 13-8-11.
// Copyright (c) 2013 com.menic. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PathOperationType){
    PathOperationMoveTo,
    PathOperationLineTo,
    PathOperationArc,
    PathOperationRect,
    PathOperationCurveTo,
    PathOperationQuadCurveTo,
    PathOperationEllipse,
    PathOperationClose,
};

typedef NS_ENUM(NSInteger, LocationType){
    LocationTypeAbsolute,
    LocationTypeRelativeToFirst,
};

@interface PathOperation : NSObject <NSCopying>
@property (nonatomic, assign) PathOperationType operationType;
@property (nonatomic, assign) CGPoint location;
@property (nonatomic, assign) LocationType locationType;

/**
* Control point have different meaning in different type
*
* Line to: Not used
* Arc: controlPoint1.x means start angle, y means end angle. location is the o, radius is calculated based on prev point
* Curve To: controlPoint1 and controlPoint2
* QuadCurveTo: controlPoint1 is used as the controlPoint
*/
@property (nonatomic, assign) CGPoint controlPoint1;
@property (nonatomic, assign) CGPoint controlPoint2;

-(PathOperation *)copy;
@end

