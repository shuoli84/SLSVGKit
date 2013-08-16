//
//  ViewController.m
//  PathDraw
//
//  Created by Li Shuo on 13-7-29.
//  Copyright (c) 2013 com.menic. All rights reserved.
//

#import "ViewController.h"
#import "DrawView.h"
#import "FVDeclareHelper.h"
#import "UIImage+FlatUI.h"
#import "UIControl+BlocksKit.h"

@interface ViewController ()
@property (nonatomic, strong) FVDeclaration *rootDeclare;
@property (nonatomic, strong) DrawView *drawView;
@property (nonatomic, strong) NSMutableArray *interlockButtonGroup;
@end

@implementation ViewController

#define F CGRectMake

- (void)viewDidLoad {
    [super viewDidLoad];
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
            backgroundView.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
            return backgroundView;
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
        [dec(@"menuBar", CGRectMake(0, FVT(100), FVP(1), 100), ^{
            UIView *view = [[UIView alloc] init];
            view.backgroundColor = [UIColor blackColor];
            return view;
        }()) $:@[
            [dec(@"selectModeButton",F(FVA(0), 0, 55, 50), buttonCreateBlock(@"Select")) process:^(FVDeclaration *declaration) {
                UIButton *button = (UIButton *)declaration.object;
                [_interlockButtonGroup addObject:button];
                [button addEventHandler:^(UIButton *btn) {
                    weakSelf.drawView.mode = DrawModeSelect;
                } forControlEvents:UIControlEventTouchUpInside];
            }],
            [dec(@"PenButton",F(FVA(0), 0, 55, 50), buttonCreateBlock(@"Pen")) process:^(FVDeclaration *declaration) {
                UIButton *button = (UIButton *)declaration.object;
                [_interlockButtonGroup addObject:button];
                [button addEventHandler:^(UIButton *btn) {
                    weakSelf.drawView.mode = DrawModePen;
                } forControlEvents:UIControlEventTouchUpInside];
            }],
            [dec(@"lineButton",F(FVA(0), 0, 55, 50), buttonCreateBlock(@"Line")) process:^(FVDeclaration *declaration) {
                UIButton *button = (UIButton *)declaration.object;
                [_interlockButtonGroup addObject:button];
                [button addEventHandler:^(id sender) {
                    weakSelf.drawView.mode = DrawModeLine;
                } forControlEvents:UIControlEventTouchUpInside];
            }],
            [dec(@"PathButton",F(FVA(0), 0, 55, 50), buttonCreateBlock(@"Path")) process:^(FVDeclaration *declaration) {
                UIButton *button = (UIButton *)declaration.object;
                [_interlockButtonGroup addObject:button];
                [button addEventHandler:^(id sender) {
                    weakSelf.drawView.mode = DrawModePath;
                } forControlEvents:UIControlEventTouchUpInside];
            }],
            [dec(@"ArcButton",F(FVA(0), 0, 55, 50), buttonCreateBlock(@"Arc")) process:^(FVDeclaration *declaration) {
                UIButton *button = (UIButton *)declaration.object;
                [_interlockButtonGroup addObject:button];
                [button addEventHandler:^(id sender) {
                    weakSelf.drawView.mode = DrawModeArc;
                } forControlEvents:UIControlEventTouchUpInside];
            }],
            [dec(@"RectButton",F(FVA(0), 0, 55, 50), buttonCreateBlock(@"Rect")) process:^(FVDeclaration *declaration) {
                UIButton *button = (UIButton *)declaration.object;
                [_interlockButtonGroup addObject:button];
                [button addEventHandler:^(id sender) {
                    weakSelf.drawView.mode = DrawModeRect;
                } forControlEvents:UIControlEventTouchUpInside];
            }],
            [dec(@"EllipseButton",F(FVA(0), 0, 60, 50), buttonCreateBlock(@"Ellipse")) process:^(FVDeclaration *declaration) {
                UIButton *button = (UIButton *)declaration.object;
                [_interlockButtonGroup addObject:button];
                [button addEventHandler:^(id sender) {
                    weakSelf.drawView.mode = DrawModeEllipse;
                } forControlEvents:UIControlEventTouchUpInside];
            }],
            [dec(@"antiAliasingButton",F(0, FVA(0), 55, 50), buttonCreateBlock(@"AA")) process:^(FVDeclaration *declaration) {
                UIButton *button = (UIButton *)declaration.object;
                [button removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
                [button addEventHandler:^(UIButton *btn) {
                    btn.selected = !btn.selected;
                    weakSelf.drawView.antialiasing = btn.selected;
                } forControlEvents:UIControlEventTouchUpInside];
            }],
            [dec(@"fillModeButton",F(FVA(5), FVSameAsPrev, 55, 50), buttonCreateBlock(@"Fill")) process:^(FVDeclaration *declaration) {
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

            [dec(@"undoButton",F(FVA(5), FVSameAsPrev, 55, 50), buttonCreateBlock(@"Undo")) process:^(FVDeclaration *declaration) {
                UIButton *button = (UIButton *)declaration.object;
                [button removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
                [button addEventHandler:^(id sender) {
                    [weakSelf.drawView undo];
                } forControlEvents:UIControlEventTouchUpInside];
            }],
            [dec(@"redoButton",F(FVA(5), FVSameAsPrev, 55, 50), buttonCreateBlock(@"Redo")) process:^(FVDeclaration *declaration) {
                UIButton *button = (UIButton *)declaration.object;
                [button removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
                [button addEventHandler:^(id sender) {
                    [weakSelf.drawView redo];
                } forControlEvents:UIControlEventTouchUpInside];
            }],
            [dec(@"deleteSelected",F(FVA(5), FVSameAsPrev, 55, 50), buttonCreateBlock(@"delete")) process:^(FVDeclaration *declaration) {

                UIButton *button = (UIButton *)declaration.object;
                [button removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
                [button addEventHandler:^(id sender) {
                    [weakSelf.drawView removeSelected];
                } forControlEvents:UIControlEventTouchUpInside];
            }],
            [dec(@"clearButton",F(FVA(5), FVSameAsPrev, 55, 50), buttonCreateBlock(@"Clear")) process:^(FVDeclaration *declaration) {
                UIButton *button = (UIButton *)declaration.object;
                [button removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
                [button addEventHandler:^(id sender) {
                    [weakSelf.drawView clear];
                } forControlEvents:UIControlEventTouchUpInside];
            }],
        ]]
    ]];

    [_rootDeclare setupViewTreeInto:self.view];
}

-(void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    [_rootDeclare resetLayout];
    _rootDeclare.unExpandedFrame = self.view.bounds;
    [_rootDeclare updateViewFrame];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end