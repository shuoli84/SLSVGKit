//
// Created by Li Shuo on 13-7-5.
// Copyright (c) 2013 Li Shuo. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "JSONValueTransformer.h"

@interface JSONValueTransformer (SLSerializer)
-(NSString*)JSONObjectFromCGRect:(NSValue *)rect;
-(NSValue*)CGRectFromNSString:(NSString*)string;
-(NSString*)JSONObjectFromCGPoint:(NSValue *)point;
-(NSValue*)CGPointFromNSString:(NSString*)string;
-(NSString*)JSONObjectFromUIColor:(UIColor*)color;
-(UIColor*)UIColorFromNSString:(NSString*)string;
-(NSString*)JSONObjectFromCATransform3D:(NSValue*)transform;
-(NSValue*)CATransform3DFromNSString:(NSString*)string;
-(NSString*)JSONObjectFromCGSize:(NSValue*)size;
-(NSValue*)CGSizeFromNSString:(NSString*)string;
@end