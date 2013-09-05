//
// Created by Li Shuo on 13-9-5.
// Copyright (c) 2013 com.menic. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "SLSVGLinearGradientLayer.h"


@implementation SLSVGLinearGradientLayer {
    NSMutableArray *_colors;
    NSMutableArray *_locations;
}

-(id)init{
    self = [super init];

    if(self){
        _colors = [NSMutableArray array];
        _locations = [NSMutableArray array];
    }

    return self;
}

-(void)drawInContext:(CGContextRef)ctx {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    float* locations = malloc(sizeof(float) * _locations.count + 1);
    for(unsigned int i = 0; i < _locations.count; ++i){
        locations[i] = [_locations[i] floatValue];
    }
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)_colors, locations);

    CGContextSaveGState(ctx);
    CGContextDrawLinearGradient(ctx, gradient, self.p1, self.p2, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
    CGContextRestoreGState(ctx);
    free(locations);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
}

-(void)setStopArray:(NSArray *)stopArray {
    _stopArray = stopArray;

    [_colors removeAllObjects];
    [_locations removeAllObjects];
    for(NSArray *stop in stopArray){
        [_locations addObject:stop[0]];
        [_colors addObject:(__bridge id)[stop[1] CGColor]];
    }
}
@end