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
    CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
    shapeLayer.fillColor = [UIColor clearColor].CGColor;
    shapeLayer.name = @"SLSVGLayer";

    NSString *opacity = svgNode[@"opacity"];
    if (opacity){
        shapeLayer.opacity = opacity.floatValue;
    }

    NSString *fill = svgNode[@"fill"];
    if(fill && ![fill isEqualToString:@"none"]){
        UIColor *fillColor = [svgNode parseColor:fill];
        if(fillColor){
            fillColor = [fillColor colorWithAlphaComponent:[svgNode[@"fill-opacity"] floatValue]];
            shapeLayer.fillColor = fillColor.CGColor;
        }
    }

    shapeLayer.lineWidth = [svgNode[@"stroke-width"] floatValue];

    UIColor *strokeColor = [svgNode parseColor:svgNode[@"stroke"]];
    strokeColor = [strokeColor colorWithAlphaComponent:[svgNode[@"stroke-opacity"] floatValue]];
    shapeLayer.strokeColor = strokeColor.CGColor;

    NSString* fillRule = svgNode[@"fill-rule"];
    if(fillRule){
        if([fillRule isEqualToString:@"nonzero"]){
            shapeLayer.fillRule = kCAFillRuleNonZero;
        }
        else if ([fillRule isEqualToString:@"evenodd"]) {
            shapeLayer.fillRule = kCAFillRuleEvenOdd;
        }
    }

    NSString *strokeMiterLimit = svgNode[@"stroke-miterlimit"];
    if(strokeMiterLimit){
        shapeLayer.miterLimit = strokeMiterLimit.floatValue;
    }

    UIBezierPath *bezierPath = [[UIBezierPath alloc] init];

    if ([svgNode.type isEqualToString:@"svg"]){
        //0 0 207338 174170
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

                CGAffineTransform resultM = CGAffineTransformConcat(shapeLayer.affineTransform, translateM);
                resultM = CGAffineTransformConcat(resultM, scaleM);

                [shapeLayer setAffineTransform: resultM];
            }
        }
    }
    else if ([svgNode.type isEqualToString:@"path"]){
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
                        controlPoint1 = CGPointMake([lastParams[0] floatValue], [lastParams[1] floatValue]);
                    }
                    else if ([lastCommand[0] isEqualToString:@"C"]){
                        NSArray *lastParams = lastCommand[1];
                        controlPoint1 = CGPointMake([lastParams[2] floatValue], [lastParams[3] floatValue]);
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

    shapeLayer.path = bezierPath.CGPath;
    shapeLayer.anchorPoint = CGPointZero; //top left as anchor point
    shapeLayer.frame = self.bounds;
    shapeLayer.masksToBounds = YES;

    CGAffineTransform transformMatrix = shapeLayer.affineTransform;
    transformMatrix = CGAffineTransformConcat([svgNode transformMatrix:svgNode[@"transform"]], transformMatrix);
    [shapeLayer setAffineTransform:transformMatrix];

    for(SLSVGNode* child in svgNode.childNodes){
        [shapeLayer addSublayer:[self layerForNode:child]];
    }

    return shapeLayer;
}
@end