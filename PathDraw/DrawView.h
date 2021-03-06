//
// Created by Li Shuo on 13-7-29.
// Copyright (c) 2013 com.menic. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "PathOperation.h"

@class DrawDocument;

typedef NS_ENUM(NSInteger, DrawMode){
    DrawModeSelect,
    DrawModePen,
    DrawModeLine,
    DrawModePath,
    DrawModeOval,
    DrawModeRect,
    DrawModeEllipse,
    DrawModeInsert,
};

@interface DrawView : UIView

@property (nonatomic, assign) DrawMode mode;
@property (nonatomic, assign) BOOL fill;
@property (nonatomic, assign) BOOL stroke;
@property (nonatomic, assign) CGFloat lineWidth;
@property (nonatomic, strong) UIColor* strokeColor;
@property (nonatomic, strong) UIColor* fillColor;
@property (nonatomic, assign) CGSize originalSize;

@property (nonatomic, strong) DrawDocument *draw;

@property (nonatomic, copy) void (^fillChangeBlock)(BOOL fill);
@property (nonatomic, copy) void (^strokeChangeBlock)(BOOL fill);

-(void)clear;
-(void)undo;
-(void)redo;
-(void)refresh;
-(void)dropCurrentShape;
-(void)dropCurrentPathOperation;
-(void)changeCurrentPathOperationType:(PathOperationType)operationType;
-(void)sendBack:(int)far;
@end