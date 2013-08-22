//
// Created by Li Shuo on 13-8-11.
// Copyright (c) 2013 com.menic. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "DrawShape.h"
#import "PathOperation.h"
#import "CGUtil.h"

@implementation DrawShape{
    UIBezierPath *_path;
}
-(id)init{
    self = [super init];
    if(self){
        _pathOperations = [NSMutableArray array];
        _lineWidth = 1.f;
        _stroke = YES;
        _fill = NO;
        _antiAliasing = YES;
        _strokeColor = [UIColor redColor];
        _fillColor = [UIColor orangeColor];
    }
    return self;
}

-(void)appendOperation:(PathOperation *)operation {
    [_pathOperations addObject:operation];
}

-(void)generatePath {
    NSArray *operations = self.pathOperations;
    if(operations.count == 0){
        self.path = nil;
        return;
    }

    UIBezierPath *path =[UIBezierPath bezierPath];

    for(PathOperation *op in self.operationsWithAbsolutePoint){
        switch (op.operationType){
            case PathOperationLineTo:
                [path addLineToPoint:op.location];
                break;
            case PathOperationQuadCurveTo:
                [path addQuadCurveToPoint:op.location controlPoint:op.controlPoint1];
                break;
            case PathOperationClose:
                [path closePath];
                break;
            case PathOperationMoveTo:
                [path moveToPoint:op.location];
                break;
            case PathOperationArc:{
                    //[path addArcWithCenter:op.location radius:op.controlPoint1.x startAngle:0 endAngle:2*M_PI clockwise:YES];
                    CGFloat startAngle = atan2f(op.controlPoint1.y-op.location.y, op.controlPoint1.x-op.location.x);
                    CGFloat endAngle = 0;
                    if (CGPointEqualToPoint(op.controlPoint1, op.controlPoint2)){
                        endAngle = 2 * M_PI + startAngle;
                    }
                    else{
                        endAngle = atan2f(op.controlPoint2.y - op.location.y, op.controlPoint2.x - op.location.x);
                    }
                    [path addArcWithCenter:op.location radius:distanceBetweenPoints(op.controlPoint1, op.location) startAngle:startAngle endAngle:endAngle clockwise:YES];
                    break;
                }
            case PathOperationCurveTo:
                [path addCurveToPoint:op.location controlPoint1:op.controlPoint1 controlPoint2:op.controlPoint2];
                break;
            case PathOperationOval:
                path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(op.location.x, op.location.y, op.controlPoint1.x - op.location.x, op.controlPoint1.y - op.location.y)];
                break;
            case PathOperationRect:
                path = [UIBezierPath bezierPathWithRect:CGRectMake(op.location.x, op.location.y, op.controlPoint1.x - op.location.x, op.controlPoint1.y - op.location.y)];
                break;
            case PathOperationEllipse:
                path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(op.location.x, op.location.y, op.controlPoint1.x - op.location.x, op.controlPoint1.y - op.location.y)];
                break;
        }
    }
    self.path = path;
}

-(CGPoint)absolutePointForIndex:(NSInteger)index{
    NSAssert(index < _pathOperations.count, @"index out of bound, array count is %d", _pathOperations.count);
    CGPoint firstPoint = [_pathOperations[0] location];
    PathOperation *op = _pathOperations[index];
    switch (op.locationType){
        case LocationTypeAbsolute:
            return op.location;
        case LocationTypeRelativeToFirst:
            return CGPointMake(op.location.x + firstPoint.x, op.location.y + firstPoint.y);
        default:
            return CGPointZero;
    }
}

-(NSArray *)operationsWithAbsolutePoint {
    NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:self.pathOperations.count];

    if(_pathOperations.count == 0){
        return resultArray;
    }

    CGPoint firstPoint = [_pathOperations[0] location];

    for (PathOperation *op in _pathOperations){
        PathOperation *newOp = [op copy];
        newOp.locationType = LocationTypeAbsolute;
        switch (op.locationType){
            case LocationTypeAbsolute:
                break;
            case LocationTypeRelativeToFirst:
                newOp.location = CGPointMake(newOp.location.x + firstPoint.x, newOp.location.y + firstPoint.y);
                newOp.controlPoint1 = CGPointMake(newOp.controlPoint1.x + firstPoint.x, newOp.controlPoint1.y + firstPoint.y);
                newOp.controlPoint2 = CGPointMake(newOp.controlPoint2.x + firstPoint.x, newOp.controlPoint2.y + firstPoint.y);
                break;
        }

        [resultArray addObject:newOp];
    }

    return resultArray;
}

-(void)setPath:(UIBezierPath *)path {
    _path = path;
}

-(UIBezierPath *)path{
    return _path;
}
@end

