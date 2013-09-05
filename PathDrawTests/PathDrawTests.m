#import "Kiwi.h"
#import "SLSVGNode.h"
#import "SLSVG.h"

SPEC_BEGIN(SLSVGSpec)

    describe(@"SVGDom", ^{
        context(@"Basic Operation DOM", ^{
            /*
            it(@"try the api first", ^{
                SLSVG* svg = [SLSVG svgWithRect:@"10, 50, 320, 200"];
                svg = [SVG svgWithRect:CGRectMake(10, 50, 320, 200)];
                SVGView *svgView = [SVGView viewWithSVG:svg]; //From now on, all model change will indicate view update. Or will trigger the related Layer to update
                [[svg rect:CGRectMake(0, 0, 20, 50)] attr:{@"stroke":@"#000"}];
                [[svg path:@"M10 10L90 90"] attr:{@"fill":@"#FFF"}];
                SVGCircle *circle = [svg circle:@"30 50 20"];
                circle.cx = 50;
                circle.cy = 60;
                Animation *animation = [circle animate:{@"cx":@30} duration:3.f easing:@"cubic-bezier(.2 .3 .7 -.3)" completion:^{}];
                animation.attr;
                [svg setViewBoxWithRect:CGRectMake(0, 0, 100, 100) fit:YES];

                CGRect box = [svg pathBBox:path];
            });
            */

            it(@"dom", ^{
                SLSVGNode *path = [[SLSVGNode alloc]init];
                path.type = @"path";
                [path setAttribute:@"d" value:@"m 20 30 m 20,30 l 50 200 l 100 200 z"];

                SLSVGNode *rect = [[SLSVGNode alloc]init];
                rect.type = @"rect";
                [rect setAttribute:@"x" value:@"20"];
                [rect setAttribute:@"y" value:@"30"];
                [rect setAttribute:@"width" value:@"300"];
                [rect setAttribute:@"height" value:@"150"];

                [rect attr:@{
                    @"x":@"20",
                    @"y":@"30",
                    @"width":@"300",
                    @"height":@"150",
                }];

                rect[@"x"]=@"20";
                rect[@"y"]=@"40";

                SLSVGNode *g = [[SLSVGNode alloc]init];
                g.type = @"g";
                [g appendChild:rect];

                g[@"fill"] = @"rgb(20,30,40)";
                g[@"stroke"] = @"#FFF";

                [g path:@"m 20 30 l 50 200"];
          //      [g rect:CGRectMake(0, 0, 100, 200)];
          //      [g circle:CGPointMake(0, 0) radius:50];
            });

            it(@"should parse d string", ^{
                SLSVGNode *node = [[SLSVGNode alloc] init];
                NSArray * array = [SLSVGNode parseDString:@"m 20.523 -30.0 l 50 60.9L20 30 H30 v50 c 20 30 20 30 23 50 C 30 20 20 20 20,20z M 20,30 s20,40,50,60z"];

                NSLog(@"%@", array);
            });

           it(@"should parse transform", ^{
               SLSVGNode *node = [[SLSVGNode alloc]init];
               node[@"transform"] = @"translate(-10, -20) scale(2) rotate(45) translate(5,10) skewX(30) skewY(20) matrix( 1, 2, 3, 4, 5, 6)";
               NSArray *transforms = [node parseTransform:node[@"transform"]];

               NSLog(@"%@", transforms);

               CGAffineTransform transform = [node transformMatrix:@"translate(-10, 20) scale(2)"];
               NSLog(@"%@", NSStringFromCGAffineTransform(transform));



               CGAffineTransform transform2 = [node transformMatrix:@"scale(.5) translate(29,30)"];
               NSLog(@"%@", NSStringFromCGAffineTransform(transform));
           });

            it(@"should able to parse color", ^{
                SLSVGNode *node = [[SLSVGNode alloc]init];
                NSLog(@"%@", [node parseColor:@"#FFF"]);
                NSLog(@"%@", [node parseColor:@"#fff"]);
                NSLog(@"%@", [node parseColor:@"#feffff"]);
                NSLog(@"%@", [node parseColor:@"rgb(0,0,0)"]);
                NSLog(@"%@", [node parseColor:@"rgb(100%,100%,100%)"]);
                NSLog(@"%@", [node parseColor:@"red"]);
                NSLog(@"%@", [node parseColor:@"greenyellow"]);
            });

            it(@"should able to calculate the point for cubic path", ^{
                CGPoint p0 = CGPointMake(120, 160);
                CGPoint c1 = CGPointMake(35, 200);
                CGPoint c2 = CGPointMake(220, 260);
                CGPoint p1 = CGPointMake(220, 40);

                CGPoint t0 = [SLSVGNode pointOnPathStart:p0 control1:c1 control2:c2 end:p1 t:0];
                NSLog(@"%@", NSStringFromCGPoint(t0));

                CGPoint t1 = [SLSVGNode pointOnPathStart:p0 control1:c1 control2:c2 end:p1 t:1];
                NSLog(@"%@", NSStringFromCGPoint(t1));

                CGRect bbox = [SLSVGNode bboxForPathStart:p0 control1:c1 control2:c2 end:p1];
                NSLog(@"BBox: %@", NSStringFromCGRect(bbox));

                bbox = [SLSVGNode bboxForPath:@"M 1, 1 L 3, 3 L 5 1 L 5 10"];
                NSLog(@"BBox: %@", NSStringFromCGRect(bbox));

                bbox = [SLSVGNode bboxForPath:@"M 1, 1 L 3, 3 C 4,4 3,7 8,9"];
                NSLog(@"BBox: %@", NSStringFromCGRect(bbox));
            });
        });
    });
SPEC_END
