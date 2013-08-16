//
// Created by Li Shuo on 13-8-11.
// Copyright (c) 2013 com.menic. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "DrawShape.h"
#import "PathOperation.h"

@implementation DrawShape
-(id)init{
    self = [super init];
    if(self){
        _pathOperations = [NSMutableArray array];
        _lineWidth = 1.f;
        _stroke = YES;
        _fill = NO;
        _antialiasing = YES;
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
        if(op.operationType == PathOperationLineTo){
            [path addLineToPoint:op.location];
        }
        else if (op.operationType == PathOperationQuadCurveTo){
            [path addQuadCurveToPoint:op.location controlPoint:op.controlPoint1];
        }
        else if (op.operationType == PathOperationClose){
            [path closePath];
        }
        else if(op.operationType == PathOperationMoveTo){
            [path moveToPoint:op.location];
        }
        else if (op.operationType == PathOperationArc){
            [path addArcWithCenter:op.location radius:op.controlPoint1.x startAngle:0 endAngle:2*M_PI clockwise:YES];
        }
        else if (op.operationType == PathOperationRect){
            path = [UIBezierPath bezierPathWithRect:CGRectMake(op.location.x, op.location.y, op.controlPoint1.x, op.controlPoint1.y)];
        }
        else if(op.operationType == PathOperationEllipse){
            path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(op.location.x, op.location.y, op.controlPoint1.x, op.controlPoint1.y)];
        }
        else{
            NSAssert(NO, @"Should not execute here");
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

-(CGPoint)absolutePointForOperation:(PathOperation *)op {
    int index = [_pathOperations indexOfObject:op];
    return [self absolutePointForIndex:index];
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
                break;
        }

        [resultArray addObject:newOp];
    }

    return resultArray;
}
@end

