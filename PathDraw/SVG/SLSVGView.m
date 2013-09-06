//
// Created by Li Shuo on 13-9-4.
// Copyright (c) 2013 com.menic. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <QuartzCore/QuartzCore.h>
#import "SLSVGView.h"
#import "SLSVGNode.h"
#import "NSArray+BlocksKit.h"
#import "UIView+RenderViewImage.h"
#import "SLSVGLinearGradientLayer.h"
#import "SLSVGRadialGradientLayer.h"


@implementation SLSVGView {

}

-(void)draw {
    [[self.layer sublayers] each:^(CALayer *sender) {
        if([sender.name isEqualToString:@"SLSVGLayer"]){
            [sender removeFromSuperlayer];
        }
    }];

    [self.layer addSublayer:[self layerForNode:self.svg]];
}

-(CALayer*)layerForNode:(SLSVGNode*)svgNode{
    if([svgNode.type isEqualToString:@"linearGradient"] || [svgNode.type isEqualToString:@"radialGradient"] || [svgNode.type isEqualToString:@"defs"]){
        return nil;
    }

    CAShapeLayer *containerLayer = [[CAShapeLayer alloc] init];
    containerLayer.backgroundColor = [UIColor clearColor].CGColor;

    containerLayer.anchorPoint = CGPointZero; //top left as anchor point
    containerLayer.masksToBounds = YES;

    containerLayer.fillColor = [UIColor clearColor].CGColor;
    containerLayer.name = @"SLSVGLayer";

    NSString *opacity = svgNode[@"opacity"];
    if (opacity){ containerLayer.opacity = opacity.floatValue; }

    if ([svgNode.type isEqualToString:@"svg"]){
        CGRect bounds = self.bounds;
        float width = [svgNode[@"width"] floatValue];
        float height = [svgNode[@"height"] floatValue];

        if(ABS(width) > 0.0002f && ABS(height) > 0.0002f){
            bounds = CGRectMake(0, 0, width, height);
        }

        NSString *viewBox = svgNode[@"viewBox"];
        if(viewBox){
            NSArray *components = [viewBox componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" ,;"]];
            components = [components filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *evaluatedObject, NSDictionary *bindings) {
                if (evaluatedObject.length == 0){
                    return NO;
                }
                return YES;
            }]];
            if(components.count == 4){
                float x = [components[0] floatValue];
                float y = [components[1] floatValue];
                float width = [components[2] floatValue];
                float height = [components[3] floatValue];

                float scale = MIN(self.bounds.size.width/width, self.bounds.size.height/height);
                CGAffineTransform translateM = CGAffineTransformMakeTranslation(-x, -y);
                CGAffineTransform scaleM = CGAffineTransformMakeScale(scale, scale);

                CGAffineTransform resultM = CGAffineTransformConcat(containerLayer.affineTransform, translateM);
                resultM = CGAffineTransformConcat(resultM, scaleM);

                [containerLayer setAffineTransform:resultM];

                bounds = CGRectMake(0, 0, width, height);
            }
        }

        svgNode[@"bounds"] = [NSValue valueWithCGRect:bounds];
    }
    else{
        containerLayer.path = [self pathForNode:svgNode].CGPath;
    }

    containerLayer.bounds = [self.svg[@"bounds"] CGRectValue];

    CAShapeLayer *contentLayer = [CAShapeLayer layer];
    contentLayer.anchorPoint = CGPointZero;
    contentLayer.bounds = [self.svg[@"bounds"] CGRectValue];
    contentLayer.path = containerLayer.path;

    contentLayer.lineWidth = [svgNode[@"stroke-width"] floatValue];
    contentLayer.fillColor = [UIColor clearColor].CGColor;
    contentLayer.backgroundColor = [UIColor clearColor].CGColor;

    UIColor *strokeColor = [svgNode parseColor:svgNode[@"stroke"]];
    strokeColor = [strokeColor colorWithAlphaComponent:[svgNode[@"stroke-opacity"] floatValue]];
    contentLayer.strokeColor = strokeColor.CGColor;

    NSString* fillRule = svgNode[@"fill-rule"];
    if(fillRule){
        if([fillRule isEqualToString:@"nonzero"]){
            contentLayer.fillRule = kCAFillRuleNonZero;
        }
        else if ([fillRule isEqualToString:@"evenodd"]) {
            contentLayer.fillRule = kCAFillRuleEvenOdd;
        }
    }

    //TODO stroke-linecap
    NSString *strokeMiterLimit = svgNode[@"stroke-miterlimit"];
    if(strokeMiterLimit){
        contentLayer.miterLimit = strokeMiterLimit.floatValue;
    }

    NSString *fill = svgNode[@"fill"];
    if(fill && ![fill isEqualToString:@"none"]){
        if([fill hasPrefix:@"url"]){
            fill = [fill substringFromIndex:3];
            fill = [fill stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" ()#"]];
            NSLog(@"Fill id: %@", fill);
            SLSVGNode *gradient = [self.svg getNodeById:fill];
            CALayer *gradientLayer = nil;
            if(gradient){
                //TODO for offset with percentage, use the bbox size
                if([gradient.type isEqualToString:@"linearGradient"]){
                    CGPoint p1 = CGPointMake([gradient[@"x1"] floatValue], [gradient[@"y1"] floatValue]);
                    CGPoint p2 = CGPointMake([gradient[@"x2"] floatValue], [gradient[@"y2"] floatValue]);

                    SLSVGLinearGradientLayer *linerGradientLayer = [[SLSVGLinearGradientLayer alloc] init];
                    linerGradientLayer.anchorPoint = CGPointZero;
                    linerGradientLayer.bounds =[self.svg[@"bounds"] CGRectValue];
                    linerGradientLayer.p1 = p1;
                    linerGradientLayer.p2 = p2;

                    NSMutableArray *stopArray = [NSMutableArray array];
                    for (SLSVGNode *stop in gradient.childNodes){
                        float offset;
                        NSString *offsetString = stop[@"offset"];
                        offsetString = [offsetString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

                        if([offsetString hasSuffix:@"%"]){
                            offset = [[offsetString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"% "]] floatValue] / 100.f;
                        }
                        else{
                            offset = [stop[@"offset"] floatValue];
                        }

                        UIColor *stopColor = [stop parseColor:stop[@"stop-color"]];
                        [stopArray addObject:@[@(offset), stopColor]];
                    }
                    linerGradientLayer.stopArray = stopArray;

                    gradientLayer = linerGradientLayer;
                }
                else if([gradient.type isEqualToString:@"radialGradient"]){
                    float cx = 0.f, cy = 0.f, fx = 0.f, fy = 0.f, r = 0.f;

                    NSString* cxAttr = gradient[@"cx"];
                    if(cxAttr){
                        cx = cxAttr.floatValue;
                    }

                    NSString *cyAttr = gradient[@"cy"];
                    if(cyAttr){
                        cy = cyAttr.floatValue;
                    }

                    NSString *fxAttr = gradient[@"fx"];
                    if(fxAttr){
                        fx = fxAttr.floatValue;
                    }
                    else{
                        fx = cx;
                    }

                    NSString *fyAttr = gradient[@"fy"];
                    if(fyAttr){
                        fy = fyAttr.floatValue;
                    }
                    else{
                        fy = cy;
                    }

                    CGPoint center = CGPointMake(cx, cy);
                    CGPoint focal = CGPointMake(fx, fy);

                    r = [gradient[@"r"] floatValue];

                    SLSVGRadialGradientLayer *radialGradientLayer = [[SLSVGRadialGradientLayer alloc] init];
                    radialGradientLayer.anchorPoint = CGPointZero;
                    radialGradientLayer.bounds = [self.svg[@"bounds"] CGRectValue];
                    radialGradientLayer.center = center;
                    radialGradientLayer.focal = focal;
                    radialGradientLayer.r = r;

                    NSMutableArray *stopArray = [NSMutableArray array];
                    for (SLSVGNode *stop in gradient.childNodes){
                        float offset = [stop[@"offset"] floatValue];
                        UIColor *stopColor = [stop parseColor:stop[@"stop-color"]];
                        [stopArray addObject:@[@(offset), stopColor]];
                    }
                    radialGradientLayer.stopArray = stopArray;

                    gradientLayer = radialGradientLayer;
               }

                if(gradient[@"gradientTransform"]){
                    NSLog(@"gradient transform");
                    [gradientLayer setAffineTransform:[gradient transformMatrix:gradient[@"gradientTransform"]]];
                }

                CAShapeLayer *maskLayer = [CAShapeLayer layer];
                maskLayer.anchorPoint = CGPointZero;
                maskLayer.bounds = [self.svg[@"bounds"] CGRectValue];
                maskLayer.path = containerLayer.path;
                [maskLayer setAffineTransform:CGAffineTransformInvert(gradientLayer.affineTransform)];
                gradientLayer.mask = maskLayer;

                [containerLayer addSublayer:gradientLayer];
                [gradientLayer setNeedsDisplay];
            }
            else{
                NSLog(@"Failed, no gradient found");
            }
        }
        else{
            UIColor *fillColor = [svgNode parseColor:fill];
            if(fillColor){
                fillColor = [fillColor colorWithAlphaComponent:[svgNode[@"fill-opacity"] floatValue]];
                contentLayer.fillColor = fillColor.CGColor;
            }
        }
    }

    [containerLayer addSublayer:contentLayer];

    CGAffineTransform transformMatrix = containerLayer.affineTransform;
    transformMatrix = CGAffineTransformConcat([svgNode transformMatrix:svgNode[@"transform"]], transformMatrix);
    [containerLayer setAffineTransform:transformMatrix];

    for(SLSVGNode* child in svgNode.childNodes){
        CALayer *layer = [self layerForNode:child];
        if(layer != nil){
            [containerLayer addSublayer:layer];
        }
    }

    return containerLayer;
}

-(UIBezierPath *)pathForNode:(SLSVGNode *)svgNode{
    UIBezierPath *bezierPath = [[UIBezierPath alloc]init];
    if ([svgNode.type isEqualToString:@"path"]){
        NSArray *commands = [SLSVGNode parseDString:svgNode[@"d"]];
        NSArray *lastCommand;
        CGPoint lastPoint;

        for (NSArray *command in commands){
            NSString *name = command[0];
            NSArray *params = command.count > 1 ? command[1] : nil;

            if([name isEqualToString:@"M"]){
                lastPoint = CGPointMake([params[0] floatValue], [params[1] floatValue]);
                [bezierPath moveToPoint:lastPoint];
            }
            else if ([name isEqualToString:@"L"]){
                lastPoint = CGPointMake([params[0] floatValue], [params[1] floatValue]);
                [bezierPath addLineToPoint:lastPoint];
            }
            else if ([name isEqualToString:@"H"]){
                lastPoint = CGPointMake([params[0] floatValue], lastPoint.y);
                [bezierPath addLineToPoint:lastPoint];
            }
            else if ([name isEqualToString:@"V"]){
                lastPoint = CGPointMake(lastPoint.x, [params[0] floatValue]);
                [bezierPath addLineToPoint:lastPoint];
            }
            else if ([name isEqualToString:@"C"]){
                lastPoint = CGPointMake([params[4] floatValue], [params[5] floatValue]);
                [bezierPath addCurveToPoint:lastPoint controlPoint1:CGPointMake([params[0] floatValue], [params[1] floatValue]) controlPoint2:CGPointMake([params[2] floatValue], [params[3] floatValue])];
            }
            else if ([name isEqualToString:@"S"]){
                CGPoint controlPoint1;
                if(lastCommand){
                    if([lastCommand[0] isEqualToString:@"S"]){
                        NSArray *lastParams = lastCommand[1];
                        CGPoint lastControlPoint2 = CGPointMake([lastParams[0] floatValue], [lastParams[1] floatValue]);
                        controlPoint1 = CGPointMake(lastPoint.x + lastPoint.x - lastControlPoint2.x, lastPoint.y + lastPoint.y - lastControlPoint2.y);
                    }
                    else if ([lastCommand[0] isEqualToString:@"C"]){
                        NSArray *lastParams = lastCommand[1];
                        CGPoint lastControlPoint2 = CGPointMake([lastParams[2] floatValue], [lastParams[3] floatValue]);
                        controlPoint1 = CGPointMake(lastPoint.x + lastPoint.x - lastControlPoint2.x, lastPoint.y + lastPoint.y - lastControlPoint2.y);
                    }
                    else{
                        controlPoint1 = lastPoint;
                    }
                }

                lastPoint = CGPointMake([params[2] floatValue], [params[3] floatValue]);

                [bezierPath addCurveToPoint:lastPoint controlPoint1:controlPoint1 controlPoint2:CGPointMake([params[0] floatValue], [params[1] floatValue])];
            }
            else if([name isEqualToString:@"A"]){
                NSLog(@"Now A is not supported yet, need to learn the math to convert A to C");
            }
            else if ([name isEqualToString:@"Z"]){
                [bezierPath closePath];
            }
            else if([name isEqualToString:@"Q"]){
                CGPoint controlPoint = CGPointMake([params[0] floatValue], [params[1] floatValue]);
                lastPoint = CGPointMake([params[2] floatValue], [params[3] floatValue]);

                [bezierPath addQuadCurveToPoint:lastPoint controlPoint:controlPoint];
            }

            lastCommand = command;
        }
    }
    else if([svgNode.type isEqualToString:@"rect"]){
        bezierPath = [UIBezierPath bezierPathWithRect:CGRectMake(
            [svgNode[@"x"] floatValue],
            [svgNode[@"y"] floatValue],
            [svgNode[@"width"] floatValue],
            [svgNode[@"height"] floatValue])];
    }
    else if([svgNode.type isEqualToString:@"polygon"]){
        NSArray *points = [svgNode parsePoints:svgNode[@"points"]];
        if(points.count > 1){
            CGPoint firstPoint = CGPointMake([points[0][0] floatValue], [points[0][1] floatValue]);
            [bezierPath moveToPoint:firstPoint];
        }
        for (NSArray *point in points){
            [bezierPath addLineToPoint:CGPointMake([point[0] floatValue], [point[1] floatValue])];
        }

        [bezierPath closePath];
    }
    else if ([svgNode.type isEqualToString:@"line"]){
        CGPoint p1 = CGPointMake([svgNode[@"x1"] floatValue], [svgNode[@"y1"] floatValue]);
        CGPoint p2 = CGPointMake([svgNode[@"x2"] floatValue], [svgNode[@"y2"] floatValue]);

        [bezierPath moveToPoint:p1];
        [bezierPath addLineToPoint:p2];
    }
    else if ([svgNode.type isEqualToString:@"polyline"]){
        NSArray *points = [svgNode parsePoints:svgNode[@"points"]];
        if(points.count > 1){
            CGPoint firstPoint = CGPointMake([points[0][0] floatValue], [points[0][1] floatValue]);
            [bezierPath moveToPoint:firstPoint];
        }

        for (NSArray *point in points){
            [bezierPath addLineToPoint:CGPointMake([point[0] floatValue], [point[1] floatValue])];
        }
    }
    else if ([svgNode.type isEqualToString:@"circle"]){
        CGPoint center = CGPointMake([svgNode[@"cx"] floatValue], [svgNode[@"cy"] floatValue]);
        float r = [svgNode[@"r"] floatValue];

        bezierPath = [UIBezierPath bezierPathWithArcCenter:center radius:r startAngle:0 endAngle:M_PI * 2 clockwise:YES];
    }
    else if ([svgNode.type isEqualToString:@"ellipse"]){
        CGPoint center = CGPointMake([svgNode[@"cx"] floatValue], [svgNode[@"cy"] floatValue]);
        float rx = [svgNode[@"rx"] floatValue];
        float ry = [svgNode[@"ry"] floatValue];

        bezierPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(center.x - rx, center.y - ry, rx * 2, ry * 2)];
    }
    return bezierPath;
}
@end