#import "Kiwi.h"
#import "RecurseFense.h"
#import "PathOperation.h"
#import "DrawShape.h"
#import "DrawDocument.h"

typedef void (^Block)();

SPEC_BEGIN(RecurseFenseSpec)

    describe(@"RecurseFense", ^{
        context(@"init", ^{
            it(@"should prevent recurse call", ^{
                int __block count = 0;
                NSObject *fenseObject = [[NSObject alloc]init];

                __block void (^block1)() = ^(){
                    static char key;
                    RecurseFense *fense = [[RecurseFense alloc] initWithObject:fenseObject functionKey:&key];
                    if(fense){
                        NSLog(@"called");
                        count++;
                        block1();
                    }
                    else{
                        block1 = nil;
                    }
                };

                block1();
                [[theValue(count) should] equal:theValue(1)];
            });
        });
    });

SPEC_END

SPEC_BEGIN(SerializationSpec)

    describe(@"PathOperationSerialization", ^{
        PathOperation *op = [[PathOperation alloc] init];
        op.location = CGPointZero;
        op.operationType = PathOperationLineTo;

        DrawShape * shape = [[DrawShape alloc] init];
        shape.antiAliasing = YES;
        shape.fill = YES;
        shape.lineWidth = 2.0f;
        [shape appendOperation:op];

        DrawDocument* document = [[DrawDocument alloc] init];
        [document.shapes addObject:shape];

        it(@"should able to serialize PathOperation", ^{
            NSString *json = [op toJSONString];
            NSLog(@"%@", json);
        });

        it(@"should able to serialize shape", ^{

            NSString *json = [shape toJSONString];
            NSLog(@"%@", json);
        });

        it(@"should able to serialize draw", ^{
            NSString *json = [document toJSONString];
            NSLog(@"%@", json);
        });
    });

SPEC_END