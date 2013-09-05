//
// Created by Li Shuo on 13-9-4.
// Copyright (c) 2013 com.menic. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@class SLSVGNode;


@interface SLSVGView : UIView

@property (nonatomic, strong) SLSVGNode *svg;

-(void)draw;
@end