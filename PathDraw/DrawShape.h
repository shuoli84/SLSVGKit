//
// Created by Li Shuo on 13-8-11.
// Copyright (c) 2013 com.menic. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@class PathOperation;

@interface DrawShape : NSObject
@property (nonatomic, assign) int identity;
@property (nonatomic, strong) NSMutableArray *pathOperations;
@property (nonatomic, assign) CGFloat lineWidth;
@property (nonatomic, assign) BOOL stroke;
@property (nonatomic, assign) BOOL fill;
@property (nonatomic, strong) UIColor* strokeColor;
@property (nonatomic, strong) UIColor* fillColor;
@property (nonatomic, assign) BOOL antialiasing;

@property (nonatomic, strong) UIBezierPath *path;

-(void)appendOperation:(PathOperation *)operation;
-(void)generatePath;

-(CGPoint)absolutePointForIndex:(NSInteger)index;
-(CGPoint)absolutePointForOperation:(PathOperation *)op;
-(NSArray *)operationsWithAbsolutePoint;
@end
