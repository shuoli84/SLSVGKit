//
// Created by Li Shuo on 13-9-5.
// Copyright (c) 2013 com.menic. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>


@interface SLSVGLinearGradientLayer : CALayer
@property (nonatomic, assign) CGPoint p1;
@property (nonatomic, assign) CGPoint p2;

@property (nonatomic, strong) NSArray *stopArray;

@end