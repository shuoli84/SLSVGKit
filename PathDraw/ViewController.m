//
//  ViewController.m
//  PathDraw
//
//  Created by Li Shuo on 13-7-29.
//  Copyright (c) 2013 com.menic. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ViewController.h"
#import "DrawView.h"
#import "FVDeclareHelper.h"
#import "UIControl+BlocksKit.h"
#import "DrawDocument.h"
#import "StandardPaths.h"
#import "NSObject+AssociatedObjects.h"
#import "UIView+RenderViewImage.h"
#import "UIImage+ProportionalFill.h"
#import "SLSVGView.h"
#import "SLSVGNode.h"

#import "RXMLElement.h"

SLSVGNode* createSVGNodeFromXMLElement(RXMLElement *element, SLSVGNode *parentNode){
    SLSVGNode *n = [[SLSVGNode alloc]init];
    if([element.tag isEqualToString:@"svg"]){
        n.type = @"svg";
        [parentNode appendChild:n];
        for (NSString *attribute in element.attributeNames){
            n[attribute] = [element attribute:attribute];
        }

        [element iterate:@"*" usingBlock:^(RXMLElement *element) {
            createSVGNodeFromXMLElement(element, n);
        }];
    }
    else if([element.tag isEqualToString:@"style"]){

    }
    else {
        n.type = element.tag;
        [parentNode appendChild:n];
        [element iterate:@"*" usingBlock:^(RXMLElement *element) {
            createSVGNodeFromXMLElement(element, n);
        }];

        for (NSString *attribute in element.attributeNames){
            n[attribute] = [element attribute:attribute];
        }

        if(n[@"style"]){
            [n attr:[n parseStyle:n[@"style"]]];
            [n removeAttribute:@"style"];
        }
    }

    return n;
}

@interface ViewController ()
@property (nonatomic, strong) FVDeclaration *rootDeclare;
@property (nonatomic, strong) DrawView *drawView;
@property (nonatomic, strong) NSMutableArray *interlockButtonGroup;
@property (nonatomic, strong) UIImageView *previewView;
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation ViewController

#define F CGRectMake

- (void)viewDidLoad {
    [super viewDidLoad];

    NSLog(@"View start loading");

    //RXMLElement *rootElement = [RXMLElement elementFromXMLFile:@"samples/breaking-1.svg"];
    RXMLElement *rootElement = [RXMLElement elementFromXMLFile:@"samples/RainbowWing.svg"];

    SLSVGNode *node = createSVGNodeFromXMLElement(rootElement, nil);

    SLSVGView *svgView = [[SLSVGView alloc] initWithFrame:CGRectMake(100, 200, 600, 600)];
    svgView.backgroundColor = [UIColor grayColor];
    [self.view addSubview:svgView];
    svgView.svg = node;
    [svgView draw];

    /*
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:10];
    svgView.transform = CGAffineTransformMakeScale(5, 5);
    [UIView commitAnimations];
    */
/*
    _interlockButtonGroup = [NSMutableArray array];

    typeof(self) __weak weakSelf = self;

    UIButton * (^buttonCreateBlock)(NSString *title) = ^UIButton *(NSString *title){
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:title forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont boldSystemFontOfSize:17];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor colorWithRed:52/255.0f green:152/255.0f blue:219/255.0f alpha:1.f] forState:UIControlStateSelected];
        [button setTitleColor:[UIColor colorWithRed:52/255.0f green:152/255.0f blue:219/255.0f alpha:1.f] forState:UIControlStateHighlighted];
        [button addEventHandler:^(UIButton *btn) {
            for (UIButton *b in weakSelf.interlockButtonGroup){
                if (![b isEqual:btn]){
                    b.selected = NO;
                }
            }
            btn.selected = YES;
        } forControlEvents:UIControlEventTouchUpInside];
        return button;
    };

    _rootDeclare = [dec(@"root") $:@[
        dec(@"backgroundView", CGRectMake(0, 0, FVP(1), FVP(1)), ^{
            UIView *backgroundView = [[UIView alloc] init];
            backgroundView.backgroundColor = [UIColor whiteColor];
            return backgroundView;
        }()),

        [dec(@"MenuPanel", F(0, 0, 230, FVP(1)), ^{
            UIView *view = [[UIView alloc] init];
            view.backgroundColor = [UIColor colorWithWhite:54/255.f alpha:1.f];
            view.clipsToBounds = YES;
            return view;
        }()) $:@[
            [dec(@"tools", F(0, FVA(0), FVP(1), FVAuto)) $:@[
                dec(@"pen", F(10, FVA(10), 100, 45), [self modeSwitchButton:@"Pen" mode:DrawModePen]),
                dec(@"Line", F(FVA(10), FVSameAsPrev, FVSameAsPrev, FVSameAsPrev), [self modeSwitchButton:@"Line" mode:DrawModeLine]),
                dec(@"Rect", F(10, FVA(10), FVSameAsPrev, FVSameAsPrev), [self modeSwitchButton:@"Rect" mode:DrawModeRect]),
                dec(@"Circle", F(FVA(10), FVSameAsPrev, FVSameAsPrev, FVSameAsPrev), [self modeSwitchButton:@"Oval" mode:DrawModeOval]),
                dec(@"Path", F(10, FVA(10), FVSameAsPrev, FVSameAsPrev), [self modeSwitchButton:@"Path" mode:DrawModePath]),
                dec(@"Ellipse", F(FVA(10), FVSameAsPrev, FVSameAsPrev, FVSameAsPrev), [self modeSwitchButton:@"Ellipse" mode:DrawModeEllipse]),
                dec(@"Image", F(10, FVA(10), FVSameAsPrev, FVSameAsPrev), [self panelButton:@"Image"]),
                dec(@"Select", F(FVA(10), FVSameAsPrev, FVSameAsPrev, FVSameAsPrev),[self modeSwitchButton:@"Select" mode:DrawModeSelect])
            ]],
            dec(@"shapeProperty", F(0, FVA(10), FVP(1), 35), [self panelSectionTitle:@"Shape"]),
            [dec(@"shapePropertyPanel", F(0, FVA(0), FVP(1), FVAuto)) $:@[
                dec(@"strokeTitle", F(10, 10, 50, 30), ^{
                    UILabel* label = [weakSelf panelSectionTitle:@"Stroke:"];
                    label.backgroundColor = [UIColor colorWithWhite:54/255.f alpha:1.f];
                    return label;
                }()),
                dec(@"stroke", F(FVA(10), FVSameAsPrev, 30, 30), ^{
                    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                    button.backgroundColor = [UIColor colorWithRed:192/255.f green:57/255.f blue:43/255.f alpha:1.f];
                    return button;
                }()),

                dec(@"fillTitle", F(FVP(0.5), FVSameAsPrev, 50, 30), ^{
                    UILabel *label = [weakSelf panelSectionTitle:@"Fill:"];
                    label.backgroundColor = [UIColor colorWithWhite:54/255.f alpha:1.f];
                    return label;
                }()),
                dec(@"fill", F(FVA(10), FVSameAsPrev, 30, 30), ^{
                    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                    button.backgroundColor = [UIColor colorWithRed:192/255.f green:57/255.f blue:43/255.f alpha:1.f];
                    return button;
                }()),

                dec(@"widthTitle", F(10, FVA(10), 50, 30), ^{
                    UILabel *label = [weakSelf panelSectionTitle:@"Width:"];
                    label.backgroundColor = [UIColor colorWithWhite:54/255.f alpha:1.f];
                    return label;
                }()),
                dec(@"width", F(FVA(10), FVSameAsPrev, 30, 30), ^{
                    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                    [button setTitle:@"1" forState:UIControlStateNormal];
                    button.backgroundColor = [UIColor whiteColor];
                    return button;
                }()),

                dec(@"close", F(10, FVA(10), 100, 45), [self panelButton:@"Close"]),
                [dec(@"drop", F(FVA(10), FVSameAsPrev, FVSameAsPrev, FVSameAsPrev), [self panelButton:@"Drop"]) process:^(FVDeclaration *declaration) {
                    UIButton *button = (UIButton*)declaration.object;
                    [button addEventHandler:^(id sender) {
                        [weakSelf.drawView dropCurrentShape];
                    } forControlEvents:UIControlEventTouchUpInside];
                }],
                [dec(@"Push", F(10, FVA(10), FVSameAsPrev, FVSameAsPrev), [self panelButton:@"Send back"]) process:^(FVDeclaration *declaration) {
                    UIButton *button = (UIButton*)declaration.object;
                    [button addEventHandler:^(id sender) {
                        [weakSelf.drawView sendBack:1];
                    } forControlEvents:UIControlEventTouchUpInside];
                }],
                [dec(@"Pull", F(FVA(10), FVSameAsPrev, FVSameAsPrev, FVSameAsPrev), [self panelButton:@"Bring front"]) process:^(FVDeclaration *declaration) {
                    UIButton *button = (UIButton*)declaration.object;
                    [button addEventHandler:^(id sender) {
                        [weakSelf.drawView dropCurrentShape];
                    } forControlEvents:UIControlEventTouchUpInside];
                }],
            ]],

            dec(@"point", F(0, FVA(10), FVP(1), 35), [self panelSectionTitle:@"Point"]),
            [dec(@"pointPanel", F(0, FVA(0), FVP(1), FVAuto)) $:@[
                dec(@"moveTo", F(10, FVA(10), 50, 30), [self pointTypeChangeButton:@"Move" type:PathOperationMoveTo]),
                dec(@"lineTo", F(FVA(5), FVSameAsPrev, FVSameAsPrev, FVSameAsPrev), [self pointTypeChangeButton:@"Line" type:PathOperationLineTo]),
                dec(@"arc", F(FVA(5), FVSameAsPrev, 45, FVSameAsPrev), [self pointTypeChangeButton:@"Arc" type:PathOperationArc]),
                dec(@"close", F(FVA(5), FVSameAsPrev, FVSameAsPrev, FVSameAsPrev), [self pointTypeChangeButton:@"Close" type:PathOperationClose]),
                dec(@"quadCurve", F(10, FVA(5), 100, 30), [self pointTypeChangeButton:@"Quad Curve" type:PathOperationQuadCurveTo]),
                dec(@"curve", F(FVA(5), FVSameAsPrev, FVSameAsPrev, FVSameAsPrev), [self pointTypeChangeButton:@"Curve" type:PathOperationCurveTo]),

                dec(@"location", F(10, FVA(10), 75, 30), [self panelLabel:@"Location:"]),
                dec(@"locationX", F(FVA(20), FVSameAsPrev, 40, 30), [self panelValueButton:@"30.0"]),
                dec(@"locationY", F(FVA(5), FVSameAsPrev, 40, 30), [self panelValueButton:@"30.0"]),

                dec(@"controlPoint1", F(10, FVA(5), 75, 30), [self panelLabel:@"Control 1:"]),
                dec(@"controlPoint1X", F(FVA(20), FVSameAsPrev, 40, 30), [self panelValueButton:@"30.0"]),
                dec(@"controlPoint1Y", F(FVA(5), FVSameAsPrev, 40, 30), [self panelValueButton:@"30.0"]),

                dec(@"location", F(10, FVA(5), 75, 30), [self panelLabel:@"Control 2:"]),
                dec(@"locationX", F(FVA(20), FVSameAsPrev, 40, 30), [self panelValueButton:@"30.0"]),
                dec(@"locationY", F(FVA(5), FVSameAsPrev, 40, 30), [self panelValueButton:@"30.0"]),

                [dec(@"drop", F(10, FVA(10), 100, 45), [self panelButton:@"Drop"]) process:^(FVDeclaration *declaration) {
                    UIButton *button = (UIButton*)declaration.object;
                    [button addEventHandler:^(id sender) {
                        [weakSelf.drawView dropCurrentPathOperation];
                    } forControlEvents:UIControlEventTouchUpInside];
                }],
                dec(@"append", F(FVA(10), FVSameAsPrev, FVSameAsPrev, FVSameAsPrev), [self modeSwitchButton:@"Append" mode:DrawModeInsert]),
            ]],

            [dec(@"undoRedo", F(FVCenter, FVA(20), FVT(20), 44)) $:@[
                dec(@"undo", F(0, 0, FVP(0.5), FVP(1.0)), ^{
                    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                    button.backgroundColor = [UIColor colorWithRed:39/255.f green:174/255.f blue:96/255.f alpha:1.f];
                    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                    [button setTitle:@"Undo" forState:UIControlStateNormal];
                    button.titleLabel.font = [UIFont boldSystemFontOfSize:14];

                    [button addEventHandler:^(id sender) {
                        [weakSelf.drawView undo];
                    } forControlEvents:UIControlEventTouchUpInside];
                    return button;
                }()),
                dec(@"redo", F(FVP(0.5), 0, FVP(0.5), FVP(1.0)), ^{
                    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                    button.backgroundColor = [UIColor colorWithRed:211/255.f green:84/255.f blue:0/255.f alpha:1.f];
                    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                    [button setTitle:@"Redo" forState:UIControlStateNormal];
                    button.titleLabel.font = [UIFont boldSystemFontOfSize:14];

                    [button addEventHandler:^(id sender) {
                        [weakSelf.drawView redo];
                    } forControlEvents:UIControlEventTouchUpInside];
                    return button; }()),
            ]],
        ]],
        [dec(@"drawArea", CGRectMake(FVAfter, 0, FVTillEnd, FVP(1))) $:@[
            dec(@"preview", CGRectMake(30, 30, 150, 150), ^{
                UIImageView *imageView = [[UIImageView alloc] init];
                self.previewView = imageView;
                return imageView;
            }()),
            dec(@"drawBackground", CGRectMake(FVCenter, FVCenter, 500, 500), ^{
                UIView *view = [[UIView alloc] init];
                view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"transparent-checkerboard.png"]];
                return view;
            }()),
            dec(@"drawView", CGRectMake(FVCenter, FVCenter, 500, 500), ^{
                DrawView *drawView = [[DrawView alloc] init];
                self.drawView = drawView;
                drawView.originalSize = CGSizeMake(500, 500);
                drawView.lineWidth = 3.0f;
                drawView.strokeColor = [UIColor redColor];
                drawView.fillColor = [UIColor orangeColor];
                drawView.fill = YES;
                drawView.stroke = YES;
                return drawView;
            }()),
        ]],

        [dec(@"menuBar", CGRectMake(0, FVT(50), FVP(1), 100), ^{
            UIView *view = [[UIView alloc] init];
            view.backgroundColor = [UIColor blackColor];
            return view;
        }()) $:@[
            [dec(@"fillModeButton",F(0, FVA(0), 55, 50), buttonCreateBlock(@"Fill")) process:^(FVDeclaration *declaration) {
                UIButton *button = (UIButton *)declaration.object;
                [button removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
                [button addEventHandler:^(UIButton *btn) {
                    btn.selected = !btn.selected;
                    weakSelf.drawView.fill = btn.selected;
                } forControlEvents:UIControlEventTouchUpInside];
            }],
            [dec(@"strokeModeButton",F(FVA(5), FVSameAsPrev, 55, 50), buttonCreateBlock(@"Stroke")) process:^(FVDeclaration *declaration) {
                UIButton *button = (UIButton *)declaration.object;
                [button removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
                [button addEventHandler:^(UIButton *btn) {
                    btn.selected = !btn.selected;
                    weakSelf.drawView.stroke = btn.selected;
                } forControlEvents:UIControlEventTouchUpInside];
            }],
            [dec(@"clearButton",F(FVA(5), FVSameAsPrev, 55, 50), buttonCreateBlock(@"Clear")) process:^(FVDeclaration *declaration) {
                UIButton *button = (UIButton *)declaration.object;
                [button removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
                [button addEventHandler:^(id sender) {
                    [weakSelf.drawView clear];
                } forControlEvents:UIControlEventTouchUpInside];
            }],
            [dec(@"saveButton",F(FVA(5), FVSameAsPrev, 55, 50), buttonCreateBlock(@"Save")) process:^(FVDeclaration *declaration) {
                UIButton *button = (UIButton *)declaration.object;
                [button removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
                [button addEventHandler:^(id sender) {
                    NSString *path = [[[NSFileManager defaultManager] publicDataPath] stringByAppendingPathComponent:@"a.xxx"];
                    NSLog(@"save to path: %@", path);
                    [[weakSelf.drawView.draw toJSONString] writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:nil];
                } forControlEvents:UIControlEventTouchUpInside];
            }],
            [dec(@"loadButton",F(FVA(5), FVSameAsPrev, 55, 50), buttonCreateBlock(@"Load")) process:^(FVDeclaration *declaration) {
                UIButton *button = (UIButton *)declaration.object;
                [button removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
                [button addEventHandler:^(id sender) {
                    NSString *path = [[[NSFileManager defaultManager] publicDataPath] stringByAppendingPathComponent:@"a.xxx"];
                    NSLog(@"load from path: %@", path);
                    [weakSelf.drawView clear];
                    weakSelf.drawView.draw = [[DrawDocument alloc] initWithString:[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil] error:nil];
                    [weakSelf.drawView refresh];
                } forControlEvents:UIControlEventTouchUpInside];
            }],
        ]],
    ]];

    [_rootDeclare setupViewTreeInto:self.view];
    */
}

-(void)dealloc{
    [self.timer invalidate];
}

-(void)updatePreviewImage{
    self.previewView.image = [[self.drawView viewImage] imageScaledToFitSize:self.previewView.bounds.size];
}

-(UIButton*)modeSwitchButton:(NSString*)title mode:(DrawMode)mode{
    typeof(self) __weak weakSelf = self;
    UIButton* button = [self panelButton:title];
    [_interlockButtonGroup addObject:button];
    [button addEventHandler:^(UIButton *btn) {
        weakSelf.drawView.mode = mode;
        for (UIButton *b in weakSelf.interlockButtonGroup){
            if (![b isEqual:btn]){
                b.selected = NO;
            }
        }
        btn.selected = YES;
    } forControlEvents:UIControlEventTouchUpInside];

    return button;
}

-(UIButton*)panelButton:(NSString*)title{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor blackColor];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithRed:52/255.f green:152/255.f blue:219/255.f alpha:1.f] forState:UIControlStateHighlighted];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [button setTitle:title forState:UIControlStateNormal];
    button.layer.cornerRadius = 5.f;
    return button;
}

-(UIButton*)pointTypeChangeButton:(NSString*)title type:(PathOperationType)type{
    static char key;
    if([self associatedValueForKey:&key] == nil){
        [self associateValue:[NSMutableArray array] withKey:&key];
    }

    NSMutableArray *buttonGroup = [self associatedValueForKey:&key];
    UIButton *button = [self panelButton:title];
    [buttonGroup addObject:button];
    typeof(self) __weak weakSelf = self;
    [button addEventHandler:^(UIButton* btn) {
        [weakSelf.drawView changeCurrentPathOperationType:type];
        for(UIButton* button in buttonGroup){
            button.highlighted = NO;
        }
        btn.highlighted = YES;
    } forControlEvents:UIControlEventTouchUpInside];

    return button;
}

-(UILabel*)panelSectionTitle:(NSString*)title{
    UILabel *label = [[UILabel alloc] init];
    label.backgroundColor = [UIColor colorWithRed:52/255.f green:152/255.f blue:219/255.f alpha:1.0f];
    label.text = title;
    label.font = [UIFont boldSystemFontOfSize:14];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    return label;
}

-(UILabel*)panelLabel:(NSString*)title{
    UILabel *label = [self panelSectionTitle:title];
    label.backgroundColor = [UIColor colorWithWhite:54/255.f alpha:1.f];
    return label;
}

-(UIButton*)panelValueButton:(NSString*)value{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:value forState:UIControlStateNormal];
    button.backgroundColor = [UIColor whiteColor];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:14];
    return button;
}

-(void)viewWillLayoutSubviews {
    /*[super viewWillLayoutSubviews];

    [_rootDeclare resetLayout];
    _rootDeclare.unExpandedFrame = self.view.bounds;
    [_rootDeclare updateViewFrame];
    */
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end