//
// Created by Li Shuo on 13-9-5.
// Copyright (c) 2013 com.menic. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>


@interface SLSVGRadialGradientLayer : CALayer

@property (nonatomic, assign) CGPoint center;
@property (nonatomic, assign) CGPoint focal;

@property (nonatomic, assign) CGFloat r;

@property (nonatomic, strong) NSArray *stopArray;
@end