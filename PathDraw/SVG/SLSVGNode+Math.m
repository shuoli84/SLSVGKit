//
// Created by Li Shuo on 13-9-6.
// Copyright (c) 2013 com.menic. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "SLSVGNode+Math.h"
#import "SLSVGNode+ParseFunctions.h"

#define fval(name) [self[@"##name##"] floatValue]

@implementation SLSVGNode (Math)

-(CGRect)bbox{
    if([self.type isEqualToString:@"path"]){
        return [SLSVGNode bboxForPath:self[@"d"]];
    }

    if([self.type isEqualToString:@"rect"]){
        float x, y, width, height;
        x = [self[@"x"] floatValue];
        y = [self[@"y"] floatValue];
        width = [self[@"width"] floatValue];
        height = [self[@"height"] floatValue];

        return CGRectMake(x, y, width, height);
    }

    if([self.type isEqualToString:@"circle"]){
        float cx, cy, r;
        cx = [self[@"cx"] floatValue];
        cy = [self[@"cy"] floatValue];
        r  = [self[@"r"] floatValue];
        return CGRectMake(cx-r, cy-r, 2*r, 2*r);
    }

    if([self.type isEqualToString:@"ellipse"]){
        float cx, cy, rx, ry;
        cx = [self[@"cx"] floatValue];
        cy = [self[@"cy"] floatValue];
        rx = [self[@"rx"] floatValue];
        ry = [self[@"ry"] floatValue];
        return CGRectMake(cx - rx, cy - ry, rx * 2, ry * 2);
    }

    if([self.type isEqualToString:@"line"]){
        float x1, y1, x2, y2;
        x1 = fval(x1);
        y1 = fval(y1);
        x2 = fval(x2);
        y2 = fval(y2);
        return CGRectMake(x1, y1, x2-x1, y2-y1);
    }

    if([self.type isEqualToString:@"polyline"] || [self.type isEqualToString:@"polygon"]){
        NSArray *points = [SLSVGNode parsePoints:self[@"points"]];
        float minx = FLT_MAX, miny = FLT_MAX, maxx = -FLT_MAX, maxy = -FLT_MAX;
        float x, y;
        for(NSArray *point in points){
            x = [point[0] floatValue];
            y = [point[1] floatValue];

            minx = MIN(minx, x);
            miny = MIN(miny, y);
            maxx = MAX(maxx, x);
            maxy = MAX(maxy, y);
        }

        return CGRectMake(minx, miny, maxx - minx, maxy - miny);
    }
}

+(CGPoint)pointOnPathStart:(CGPoint)p1 control1:(CGPoint)c1 control2:(CGPoint)c2 end:(CGPoint)p2 t:(float)t{
    float x = (p1.x) * powf(1-t, 3) + c1.x * 3 * powf(1-t, 2) * t + c2.x * 3 * (1-t) * powf(t, 2) + p2.x * powf(t, 3);
    float y = (p1.y) * powf(1-t, 3) + c1.y * 3 * powf(1-t, 2) * t + c2.y * 3 * (1-t) * powf(t, 2) + p2.y * powf(t, 3);

    return CGPointMake(x, y);
}

/**
* x' = 3 * (-a + 3b - 3c +d)t*t + 2 * (3a - 6b + 3c)t + (-3a + 3b)
*/
+(CGPoint)derivativeOnPathStart:(CGPoint)p1 control1:(CGPoint)c1 control2:(CGPoint)c2 end:(CGPoint)p2 t:(float)t{
    float xd = 3 * (-p1.x + 3 * c1.x - 3 * c2.x + p2.x) * t * t + 2 * (3 * p1.x - 6 * c1.x + 3 * c2.x) * t + (-3 * p1.x + 3 * c1.x);
    float yd = 3 * (-p1.y + 3 * c1.y - 3 * c2.y + p2.y) * t * t + 2 * (3 * p1.y - 6 * c1.y + 3 * c2.y) * t + (-3 * p1.y + 3 * c1.y);

    return CGPointMake(xd, yd);
}

/**
* 6 * ( -a + 3b - 3c +d ) * t + 2 * (3a - 6b + 3c)
*/
+(CGPoint)deriveOfDeriveOnPathStart:(CGPoint)p1 control1:(CGPoint)c1 control2:(CGPoint)c2 end:(CGPoint)p2 t:(float)t{
    float xdd = 6 * (-p1.x + 3 * c1.x - 3 * c2.x + p2.x) * t + 2 * ( 3 * p1.x - 6 * p1.x + 3 * c2.x);
    float ydd = 6 * (-p1.y + 3 * c1.y - 3 * c2.y + p2.y) * t + 2 * ( 3 * p1.y - 6 * p1.y + 3 * c2.y);
    return CGPointMake(xdd, ydd);
}

+(BOOL)rootForA:(float)a b:(float)b c:(float)c r1:(float*)r1 r2:(float*)r2{
    float q = b * b - 4 * a * c;
    if(q < 0){
        return NO;
    }

    *r1 = 0.5 * (-b + sqrtf(q) ) / a;
    *r2 = 0.5 * (-b - sqrtf(q) ) / a;
    return YES;
}

+(CGRect)bboxForPathStart:(CGPoint)p1 control1:(CGPoint)c1 control2:(CGPoint)c2 end:(CGPoint)p2{
    float ax = 3 * (-p1.x + 3 * c1.x - 3 * c2.x + p2.x);
    float bx = 2 * (3 * p1.x - 6 * c1.x + 3 * c2.x);
    float cx = (-3 * p1.x + 3 * c1.x);
    float t1 = 0, t2 = 0;
    [SLSVGNode rootForA:ax  b:bx c:cx r1:&t1 r2:&t2]; //if no root, 0 means start point
    CGPoint p3 = [SLSVGNode pointOnPathStart:p1 control1:c1 control2:c2 end:p2 t:t1];
    CGPoint p4 = [SLSVGNode pointOnPathStart:p1 control1:c1 control2:c2 end:p2 t:t2];

    float minX, maxX;
    minX = MIN(MIN(MIN(p1.x, p2.x), p3.x), p4.x);
    maxX = MAX(MAX(MAX(p1.x, p2.x), p3.x), p4.x);

    float ay = 3 * (-p1.y + 3 * c1.y - 3 * c2.y + p2.y);
    float by = 2 * (3 * p1.y - 6 * c1.y + 3 * c2.y);
    float cy = (-3 * p1.y + 3 * c1.y);
    [SLSVGNode rootForA:ay  b:by c:cy r1:&t1 r2:&t2]; //if no root, 0 means start point
    p3 = [SLSVGNode pointOnPathStart:p1 control1:c1 control2:c2 end:p2 t:t1];
    p4 = [SLSVGNode pointOnPathStart:p1 control1:c1 control2:c2 end:p2 t:t2];

    float minY, maxY;
    minY = MIN(MIN(MIN(p1.y, p2.y), p3.y), p4.y);
    maxY = MAX(MAX(MAX(p1.y, p2.y), p3.y), p4.y);

    return CGRectMake(minX, minY, maxX - minX, maxY - minY);
}

+(CGRect)bboxForPath:(NSString *)d{
    NSArray* commands = [SLSVGNode parseDString:d];
    CGPoint currentPoint = CGPointZero;
    CGRect bbox = CGRectNull;
    for(NSArray *command in commands){
        NSString* name = command[0];
        NSArray *param = command.count > 1 ? command[1] : nil;
        if([name isEqualToString:@"M"]){
            currentPoint = CGPointMake([param[0] floatValue], [param[1] floatValue]);
        }
        else if([name isEqualToString:@"L"]){
            CGPoint end = CGPointMake([param[0] floatValue], [param[1] floatValue]);
            float x = MIN(currentPoint.x, end.x);
            float y = MIN(currentPoint.y, end.y);
            float w = MAX(currentPoint.x, end.x) - x;
            float h = MAX(currentPoint.y, end.y) - y;
            CGRect r = CGRectMake( x, y, w, h);
            bbox = CGRectUnion(bbox, r);

            currentPoint = end;
        }
        else if([name isEqualToString:@"C"]){
            CGPoint end =  CGPointMake([param[4] floatValue], [param[5] floatValue]);
            CGPoint c1 =  CGPointMake([param[0] floatValue], [param[1] floatValue]);
            CGPoint c2 =  CGPointMake([param[2] floatValue], [param[3] floatValue]);
            CGRect r = [SLSVGNode bboxForPathStart:currentPoint control1:c1 control2:c2 end:end];
            bbox = CGRectUnion( bbox, r);

            currentPoint = end;
        }
        else{
            NSLog(@"name not handled yet");
        }
    }
    return bbox;
}

CGPoint rotate(CGPoint point, float rad){
    float x = point.x * cosf(rad) - point.y * sinf(rad);
    float y = point.x * sinf(rad) + point.y * cosf(rad);
    return CGPointMake(x, y);
}

float angleForPoints(CGPoint start, CGPoint end){
    float rad = atan2f(-(end.y-start.y), end.x-start.x);
    if(rad < 0){
        rad = ABS(rad);
    }
    else{
        rad = 2 * (float)M_PI - rad;
    }
    return rad;
}

CGPoint derivativeForPointOnEllipse(float rx, float ry, float xAxisRotation, float pointAngle){
    float cosTheta = cosf(xAxisRotation);
    float sinTheta = sinf(xAxisRotation);
    float cosPhy = cosf(pointAngle);
    float sinPhy = sinf(pointAngle);
    float dx = -rx * cosTheta * sinPhy - ry * sinTheta * cosPhy;
    float dy = -rx * sinTheta * sinPhy + ry * cosTheta * cosPhy;

    return CGPointMake(dx, dy);
}

/**
* Here is how we do this:
* 1, get the center, angle1, angle2
* 2, follow formula in http://www.spaceroots.org/documents/ellipse/elliptical-arc.pdf to calculate the control point
*/
+(NSString*)pathForArcStart:(CGPoint)start end:(CGPoint)end rx:(float)rx ry:(float)ry xAxisRotation:(float)rotation largeFlat:(BOOL)large sweepFlag:(BOOL)sweep{
    float rotationInRad = rotation * (float)M_PI / 180.f;

    CGPoint rstart = rotate(start, -rotationInRad);
    CGPoint rend = rotate(end, -rotationInRad);

    float scale = ry / rx;

    //Then scale in x-axis make it to a circle
    CGPoint sstart = CGPointMake(rstart.x * scale, rstart.y);
    CGPoint send = CGPointMake(rend.x * scale, rend.y);

    float l = sqrtf((send.x - sstart.x) * (send.x - sstart.x) + (send.y - sstart.y)*(send.y - sstart.y));
    float l_2 = l / 2;
    float h = sqrtf(ry * ry - l_2 * l_2);
    float tan_a = (send.y - sstart.y) / (send.x - sstart.x);
    float sin_a = tan_a / sqrtf(1 + tan_a * tan_a);
    float cos_a = sin_a / tan_a;

    float rcy = (sstart.y + send.y) / 2 + (sweep?1:-1) * h * cos_a;
    float scx = ((sstart.x + send.x) / 2) + (sweep?-1:1) * h * sin_a;
    float rcx = scx / scale;
    CGPoint center = rotate(CGPointMake(rcx, rcy), rotationInRad);

    float a1 = angleForPoints(center, start);
    float a2 = angleForPoints(center, end);

    float k = sinf(a2 - a1) / 3 * (sqrtf(4 + 3 * tanf((a2 - a1)/2) * tanf((a2 - a1)/2)) - 1);

    CGPoint p1 = start;
    CGPoint p2 = end;
    CGPoint dp1 = derivativeForPointOnEllipse(rx, ry, rotationInRad, a1);
    CGPoint c1 = CGPointMake(p1.x + k * dp1.x, p1.y + k * dp1.y);

    CGPoint dp2 = derivativeForPointOnEllipse(rx, ry, rotationInRad, a2);
    CGPoint c2 = CGPointMake(p2.x - k * dp2.x, p2.y - k * dp2.y);

    return [NSString stringWithFormat:@"C %f,%f %f,%f %f,%f", c1.x, c1.y, c2.x, c2.y, end.x, end.y];
}
@end