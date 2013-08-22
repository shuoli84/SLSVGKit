//
// Created by Li Shuo on 13-8-22.
// Copyright (c) 2013 com.menic. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "JSONModel.h"

@protocol DrawShape @end

@interface DrawDocument : JSONModel
@property (nonatomic, strong) NSMutableArray<DrawShape> *shapes;
@end