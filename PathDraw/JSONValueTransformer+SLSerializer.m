//
// Created by Li Shuo on 13-7-5.
// Copyright (c) 2013 Li Shuo. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "JSONValueTransformer+SLSerializer.h"
#import <CoreImage/CIColor.h>

@implementation JSONValueTransformer (SLSerializer)

-(NSString*)JSONObjectFromCGRect:(NSValue *)rect
{
    return NSStringFromCGRect([rect CGRectValue]);
}

-(NSValue*)CGRectFromNSString:(NSString*)string{
    return [NSValue valueWithCGRect:CGRectFromString(string)];
}

-(NSString*)JSONObjectFromCGPoint:(NSValue *)point{
    return NSStringFromCGPoint([point CGPointValue]);
}

-(NSValue*)CGPointFromNSString:(NSString*)string{
    return [NSValue valueWithCGPoint:CGPointFromString(string)];
}

-(NSString*)JSONObjectFromUIColor:(UIColor*)color{

    CGColorRef colorRef = color.CGColor;
    if(colorRef)
        return [CIColor colorWithCGColor:colorRef].stringRepresentation;
    return @"";
}

-(UIColor*)UIColorFromNSString:(NSString*)string{
    if(string == nil || [string length] == 0)
        return nil;
    CIColor *ciColor = [CIColor colorWithString:string];
    return [UIColor colorWithCGColor:[UIColor colorWithCIColor:ciColor].CGColor];
}

-(NSString*)JSONObjectFromCATransform3D:(NSValue*)transform{
    CATransform3D transform3D = [transform CATransform3DValue];
#define M(x,y) transform3D.m##x##y
    NSString *result = [NSString stringWithFormat:@"%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f",
        M(1,1), M(1,2), M(1,3), M(1,4),
        M(2,1), M(2,2), M(2,3), M(2,4),
        M(3,1), M(3,2), M(3,3), M(3,4),
        M(4,1), M(4,2), M(4,3), M(4,4)];
#undef M
    return result;
}

-(NSValue*)CATransform3DFromNSString:(NSString*)string{
    NSArray *array = [string componentsSeparatedByString:@" "];
    CATransform3D transform3D = CATransform3DIdentity;

#define M(x,y) transform3D.m##x##y = [(NSString*)array[(x-1) * 4 + (y-1)] floatValue]
    M(1,1);  M(1,2); M(1,3); M(1,4);
    M(2,1);  M(2,2); M(2,3); M(2,4);
    M(3,1);  M(3,2); M(3,3); M(3,4);
    M(4,1);  M(4,2); M(4,3); M(4,4);
#undef M

    return [NSValue valueWithCATransform3D:transform3D];
}

-(NSString*)JSONObjectFromCGSize:(NSValue*)size{
    return NSStringFromCGSize([size CGSizeValue]);
}

-(NSValue*)CGSizeFromNSString:(NSString*)string{
    return [NSValue valueWithCGSize:CGSizeFromString(string)];
}

@end