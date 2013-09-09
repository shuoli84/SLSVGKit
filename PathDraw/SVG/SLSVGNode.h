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

+(SLSVGNode *)node:(NSString*)type attr:(NSString*)attr;
+(SLSVGNode *)node:(NSString*)type attributeDictionary:(NSDictionary *)dictionary;

-(SLSVGNode *)insertChild:(SLSVGNode *)newNode beforeNode:(SLSVGNode*)refChild;
-(SLSVGNode *)replaceChild:(SLSVGNode *)newNode oldNode:(SLSVGNode *)oldNode;
-(SLSVGNode *)removeChild:(SLSVGNode *)oldNode;
-(SLSVGNode *)appendChild:(SLSVGNode *)newNode;
-(BOOL) hasChildNodes;

-(SLSVGNode *)getNodeById:(NSString*)id;

-(SLSVGNode*)setAttributeDictionary:(NSDictionary *)dictionary;

- (id)objectForKeyedSubscript:(id <NSCopying>)key;
- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key;

-(SLSVGNode*)node:(NSString *)type attr:(NSString*)attrString;
@end