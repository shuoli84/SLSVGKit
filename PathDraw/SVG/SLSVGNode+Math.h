//
// Created by Li Shuo on 13-9-6.
// Copyright (c) 2013 com.menic. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "SLSVGNode.h"

@interface SLSVGNode (Math)

-(CGRect)bbox;

+(CGPoint)pointOnPathStart:(CGPoint)p1 control1:(CGPoint)c1 control2:(CGPoint)c2 end:(CGPoint)p2 t:(float)t;
+(CGPoint)derivativeOnPathStart:(CGPoint)p1 control1:(CGPoint)c1 control2:(CGPoint)c2 end:(CGPoint)p2 t:(float)t;

+(CGRect)bboxForPathStart:(CGPoint)p1 control1:(CGPoint)c1 control2:(CGPoint)c2 end:(CGPoint)p2;
+(CGRect)bboxForPath:(NSString *)d;

+(NSString*)pathForArcStart:(CGPoint)start end:(CGPoint)end rx:(float)rx ry:(float)ry xAxisRotation:(float)rotate largeFlat:(BOOL)large sweepFlag:(BOOL)sweep;
@end