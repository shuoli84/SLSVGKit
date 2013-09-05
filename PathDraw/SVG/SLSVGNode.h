//
// Created by Li Shuo on 13-8-30.
// Copyright (c) 2013 com.menic. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@interface SLSVGNode : NSObject
@property (nonatomic, strong) NSString* type;
@property (nonatomic, strong) NSString* id;

@property (nonatomic, strong) NSMutableDictionary *attributes;

@property (nonatomic, weak) SLSVGNode* parentNode;
@property (nonatomic, strong) NSMutableArray *childNodes;

@property (nonatomic, readonly) SLSVGNode *firstChild;
@property (nonatomic, readonly) SLSVGNode *lastChild;
@property (nonatomic, weak) SLSVGNode *previousSibling;
@property (nonatomic, weak) SLSVGNode *nextSibling;

-(SLSVGNode *)insertChild:(SLSVGNode *)newNode beforeNode:(SLSVGNode*)refChild;
-(SLSVGNode *)replaceChild:(SLSVGNode *)newNode oldNode:(SLSVGNode *)oldNode;
-(SLSVGNode *)removeChild:(SLSVGNode *)oldNode;
-(SLSVGNode *)appendChild:(SLSVGNode *)newNode;
-(BOOL) hasChildNodes;
-(SLSVGNode *)cloneNode:(BOOL)deep;

-(NSString*)attribute:(NSString*)name;
-(void)setAttribute:(NSString *)name value:(NSString*)value;
-(void)removeAttribute:(NSString*)name;

-(SLSVGNode*)attr:(NSDictionary *)attr;

- (id)objectForKeyedSubscript:(id <NSCopying>)key;
- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key;


-(SLSVGNode*)g;
-(SLSVGNode*)rect:(CGRect)rect;
-(SLSVGNode*)circle:(CGPoint)center radius:(float)radius;
-(SLSVGNode*)path:(NSString *)d; // "M0,0 l30,50 20,60"
-(SLSVGNode*)polygon:(NSString *)points; //points="350,75 379,161 469,161 397,215 423,301 350,250 277,301 303,215 231,161 321,161"

+(NSArray *)parseDString:(NSString*)d;
-(NSArray *)parseTransform:(NSString*)transform;
-(UIColor *)parseColor:(NSString*)colorString;
-(NSArray *)parsePoints:(NSString*)points;
-(NSDictionary *)parseStyle:(NSString*)style;

-(CGAffineTransform)transformMatrix:(NSString*)transform;

+(CGPoint)pointOnPathStart:(CGPoint)p1 control1:(CGPoint)c1 control2:(CGPoint)c2 end:(CGPoint)p2 t:(float)t;
+(CGPoint)derivativeOnPathStart:(CGPoint)p1 control1:(CGPoint)c1 control2:(CGPoint)c2 end:(CGPoint)p2 t:(float)t;

+(CGRect)bboxForPathStart:(CGPoint)p1 control1:(CGPoint)c1 control2:(CGPoint)c2 end:(CGPoint)p2;
+(CGRect)bboxForPath:(NSString *)d;
@end