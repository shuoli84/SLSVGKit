//
// Created by Li Shuo on 13-8-7.
// Copyright (c) 2013 com.menic. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

/**
* Draw cache layer is the layer which holds draw cache
* layer should know the count of operations it holds, from xxx to xxx.
*/
@interface DrawCacheImage : NSObject
@property (nonatomic, assign) NSInteger fromIndex;
@property (nonatomic, assign) NSInteger toIndex;
@property (nonatomic, strong) UIImage* image;
@end
