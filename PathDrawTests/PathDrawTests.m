#import "Kiwi.h"
#import "RecurseFense.h"

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