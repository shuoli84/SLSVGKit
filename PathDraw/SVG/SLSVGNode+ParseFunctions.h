//
// Created by Li Shuo on 13-9-6.
// Copyright (c) 2013 com.menic. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "SLSVGNode.h"
@interface SLSVGNode (ParseFunctions)

+(NSArray *)parseDString:(NSString*)d;
+(NSArray *)parseTransform:(NSString*)transform;
+(UIColor *)parseColor:(NSString*)colorString;
+(NSArray *)parsePoints:(NSString*)points;
+(NSDictionary *)parseStyle:(NSString*)style;
+(NSDictionary *)parseCSS:(NSString*)css;
+(NSArray *)parseDashArray:(NSString*)dashArray;

+(NSString*)parseUrlId:(NSString*)url;

+(CGAffineTransform)transformMatrix:(NSString*)transform;

@end