//
// Created by Li Shuo on 13-8-11.
// Copyright (c) 2013 com.menic. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

@class PathOperation;

@protocol PathOperation @end

@interface DrawShape : JSONModel
@property (nonatomic, strong) NSMutableArray<PathOperation> *pathOperations;
@property (nonatomic, assign) CGFloat lineWidth;
@property (nonatomic, assign) BOOL stroke;
@property (nonatomic, assign) BOOL fill;
@property (nonatomic, strong) UIColor* strokeColor;
@property (nonatomic, strong) UIColor* fillColor;
@property (nonatomic, assign) BOOL antiAliasing;

-(void)appendOperation:(PathOperation *)operation;
-(void)generatePath;

-(CGPoint)absolutePointForIndex:(NSInteger)index;
-(NSArray *)operationsWithAbsolutePoint;

-(UIBezierPath *)path;
-(void)setPath:(UIBezierPath *)path;
@end
