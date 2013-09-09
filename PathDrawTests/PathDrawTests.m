#import "Kiwi.h"
#import "SLSVGNode.h"
#import "SLSVG.h"
#import "SLSVGNode+ParseFunctions.h"
#import "SLSVGNode+Math.h"

SPEC_BEGIN(SLSVGSpec)

    describe(@"SVGDom", ^{
        context(@"Basic Operation DOM", ^{
            it(@"dom", ^{
                SLSVGNode *path = [[SLSVGNode alloc]init];
                path.type = @"path";
                path[@"d"] = @"m 20 30 m 20,30 l 50 200 l 100 200 z";

                SLSVGNode *rect = [[SLSVGNode alloc]init];
                rect.type = @"rect";
                rect[@"x"] = @"20";
                rect[@"y"] = @"30";
                rect[@"width"] = @"300";
                rect[@"height"] = @"150";

                [rect setAttributeDictionary:@{
                    @"x" : @"20",
                    @"y" : @"30",
                    @"width" : @"300",
                    @"height" : @"150",
                }];

                rect[@"x"]=@"20";
                rect[@"y"]=@"40";

                SLSVGNode *g = [[SLSVGNode alloc]init];
                g.type = @"g";
                [g appendChild:rect];

                g[@"fill"] = @"rgb(20,30,40)";
                g[@"stroke"] = @"#FFF";

                [g node:@"path" attr:@"d:m 20 30 l 50 200"];
            });

            it(@"should parse d string", ^{
                SLSVGNode *node = [[SLSVGNode alloc] init];
                NSArray * array = [SLSVGNode parseDString:@"m 20.523 -30.0 l 50 60.9L20 30 H30 v50 c 20 30 20 30 23 50 C 30 20 20 20 20,20z M 20,30 s20,40,50,60z"];

                NSLog(@"%@", array);
            });

           it(@"should parse transform", ^{
               SLSVGNode *node = [[SLSVGNode alloc]init];
               node[@"transform"] = @"translate(-10, -20) scale(2) rotate(45) translate(5,10) skewX(30) skewY(20) matrix( 1, 2, 3, 4, 5, 6)";
               NSArray *transforms = [SLSVGNode parseTransform:node[@"transform"]];

               NSLog(@"%@", transforms);

               CGAffineTransform transform = [SLSVGNode transformMatrix:@"translate(-10, 20) scale(2)"];
               NSLog(@"%@", NSStringFromCGAffineTransform(transform));



               CGAffineTransform transform2 = [SLSVGNode transformMatrix:@"scale(.5) translate(29,30)"];
               NSLog(@"%@", NSStringFromCGAffineTransform(transform));
           });

            it(@"should able to parse color", ^{
                NSLog(@"%@", [SLSVGNode parseColor:@"#FFF"]);
                NSLog(@"%@", [SLSVGNode parseColor:@"#fff"]);
                NSLog(@"%@", [SLSVGNode parseColor:@"#feffff"]);
                NSLog(@"%@", [SLSVGNode parseColor:@"rgb(0,0,0)"]);
                NSLog(@"%@", [SLSVGNode parseColor:@"rgb(100%,100%,100%)"]);
                NSLog(@"%@", [SLSVGNode parseColor:@"red"]);
                NSLog(@"%@", [SLSVGNode parseColor:@"greenyellow"]);
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

            it(@"should able to convert elliptic to curve", ^{
                NSLog(@"%@", [SLSVGNode pathForArcStart:CGPointMake(0, 0) end:CGPointMake(1, 1) rx:1 ry:1 xAxisRotation:0 largeFlat:NO sweepFlag:NO]);
                NSLog(@"%@", [SLSVGNode pathForArcStart:CGPointMake(0, 0) end:CGPointMake(1, 1) rx:1 ry:1 xAxisRotation:90 largeFlat:NO sweepFlag:YES]);

                NSLog(@"%@", [SLSVGNode pathForArcStart:CGPointMake(0, 0) end:CGPointMake(1, 1.73205/2.f) rx:2 ry:1 xAxisRotation:0 largeFlat:NO sweepFlag:NO]);

            });

            it(@"should able to parse simple css", ^{
                NSDictionary *dict = [SLSVGNode parseCSS:@""
                    ".st0{opacity:0.35;}\n"
                    "\t.st1{opacity:0.75;}\n"
                    "\t.st2{fill:#231F20;}\n"
                    "\t.st3{fill:none;stroke:#231F20;stroke-miterlimit:10;}\n"
                    "\t.ch0{fill:#F69321;}\n"
                    "\t.ch1{fill:#29ABE2;}"
                    ""];

                [[dict[@".st1"][@"opacity"] should] equal:@"0.75"];
            });
        });
    });
SPEC_END
