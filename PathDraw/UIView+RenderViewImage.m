//
// Created by Li Shuo on 13-8-23.
// Copyright (c) 2013 com.menic. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <QuartzCore/QuartzCore.h>
#import "UIView+RenderViewImage.h"


@implementation UIView (RenderViewImage)

-(UIImage*)viewImage {
    CGRect rect = self.bounds;
    UIGraphicsBeginImageContext(rect.size);

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [[UIColor whiteColor] set];
    CGContextFillRect(ctx, rect);

    [self.layer renderInContext:ctx];

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return newImage;
}

@end