//
// Created by Li Shuo on 13-8-30.
// Copyright (c) 2013 com.menic. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "SLSVGNode.h"
#import "NSArray+BlocksKit.h"
#import "SLSVGNode+ParseFunctions.h"


@implementation SLSVGNode {

}

-(id)init{
    self = [super init];

    if (self){
        self.attributes = [NSMutableDictionary dictionary];
        self.childNodes = [NSMutableArray array];
    }

    return self;
}


+(SLSVGNode *)node:(NSString*)type attr:(NSString*)attr{
    return [SLSVGNode node:type attributeDictionary:[SLSVGNode parseStyle:attr]];
}

+(SLSVGNode *)node:(NSString*)type attributeDictionary:(NSDictionary *)dictionary{
    SLSVGNode *node = [[SLSVGNode alloc]init];
    node.type = type;
    [node setAttributeDictionary:dictionary];
    return node;}

-(SLSVGNode *)insertChild:(SLSVGNode *)newNode beforeNode:(SLSVGNode *)refChild {
    NSUInteger index = [self.childNodes indexOfObject:refChild];
    if (index != NSNotFound){
        [self.childNodes insertObject:newNode atIndex:index];
    }
    return self;
}

-(SLSVGNode *)appendChild:(SLSVGNode *)newNode{
    [self.childNodes addObject:newNode];
    newNode.parentNode = self;

    return self;
}

-(SLSVGNode *)removeChild:(SLSVGNode *)oldNode {
    [self.childNodes removeObject:oldNode];
    return self;
}

-(SLSVGNode *)previousSibling {
    if(self.parentNode){
        int index = [self.parentNode.childNodes indexOfObject:self];
        if(index > 0){
            return self.parentNode.childNodes[index - 1];
        }
    }
    return nil;
}

-(SLSVGNode *)nextSibling {
    if(self.parentNode){
        NSUInteger index = [self.parentNode.childNodes indexOfObject:self];
        if (index < self.parentNode.childNodes.count - 1){
            return self.parentNode.childNodes[index+1];
        }
    }
    return nil;
}

-(SLSVGNode *)replaceChild:(SLSVGNode *)newNode oldNode:(SLSVGNode *)oldNode {
    NSUInteger index = [self.childNodes indexOfObject:oldNode];
    if(index != NSNotFound){
        [self.childNodes replaceObjectAtIndex:index withObject:newNode];
    }
    return self;
}

-(BOOL) hasChildNodes{
    return self.childNodes.count > 0;
}

-(NSString*)id{
    return [self attribute:@"id"];
}

-(void)setId:(NSString*)id{
    [self setAttribute:@"id" value:id];
}

-(SLSVGNode *)getNodeById:(NSString*)id{
    SLSVGNode* result;
    for(SLSVGNode *child in self.childNodes){
        if([child.id isEqualToString:id]){
            result = child;
            break;
        }
        else{
            result = [child getNodeById:id];
            if(result){
                break;
            }
        }
    }

    return result;
}

-(SLSVGNode *)firstChild {
    if(self.childNodes.count > 0){
        return self.childNodes[0];
    }
    return nil;
}

-(SLSVGNode *)lastChild {
    if(self.childNodes.count > 0){
        return self.childNodes[self.childNodes.count-1];
    }
    return nil;
}

-(id)attribute:(NSString *)name {
    static NSDictionary *defaultPropertyValues;
    static NSSet *propertyAbleToInherit;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        defaultPropertyValues = @{
            @"color" : @"white",
            @"stroke" : @"none",
            @"fill" : @"none",
            @"fill-opacity" : @"1",
            @"stroke-width" : @"1",
            @"stroke-linecap" : @"butt",
            @"stroke-linejoin" : @"miter",
            @"stroke-miterlimit" : @"4",
            @"stroke-dashoffset" : @"0",
            @"stroke-opacity" : @"1",
        };

        propertyAbleToInherit = [NSSet setWithObjects:
            @"fill",
            @"stroke-width",
            @"stroke",
            @"stroke-opacity",
            @"stroke-miterlimit",
            @"fill-rule",
            @"fill-opacity",
            nil];
    });

    NSString *value = self.attributes[name];

    if( value != nil){
        return value;
    }

    SLSVGNode *svgRoot = self;
    while (svgRoot.parentNode){
        svgRoot = svgRoot.parentNode;
    }

    NSDictionary *cssRules = svgRoot.attributes[@"css"];
    NSString *selector;

    if(_attributes[@"id"]){
        selector = [NSString stringWithFormat:@"#%@", _attributes[@"id"]];

        value = cssRules[selector][name];
        if(value){return value;}
    }

    if(_attributes[@"class"]){
        selector = [NSString stringWithFormat:@".%@", _attributes[@"class"]];

        value = cssRules[selector][name];
        if(value){return value;}
    }

    value = cssRules[self.type][name];
    if (value){return value;}

    if([propertyAbleToInherit containsObject:name] && self.parentNode){
        value = [self.parentNode attribute:name];
        if (value){
            return value;
        }
    }

    value = defaultPropertyValues[name];
    if(value != nil){
        return value;
    }

    return nil;
}

-(void)setAttribute:(NSString *)name value:(NSString*)value{
    [self.attributes setObject:value forKey:name];
}

-(void)removeAttribute:(NSString *)name {
    [self.attributes removeObjectForKey:name];
}

-(SLSVGNode*)setAttributeDictionary:(NSDictionary *)dictionary {
    [self.attributes addEntriesFromDictionary:dictionary];
    return self;
}

- (id)objectForKeyedSubscript:(id <NSCopying>)key{
    return [self attribute:(NSString *)key];
}

- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key{
    if(obj != nil){
        [self setAttribute:(NSString *)key value:obj];
    }
    else{
        [self removeAttribute:key];
    }
}

-(SLSVGNode*)node:(NSString *)type attr:(NSString*)attrString{
    SLSVGNode *node = [[SLSVGNode alloc] init];
    node.type = type;
    [node setAttributeDictionary:[SLSVGNode parseStyle:attrString]];
    [self appendChild:node];
    return node;
}

-(SLSVGNode*)attr:(NSString*)attr{
    [self setAttributeDictionary:[SLSVGNode parseStyle:attr]];
    return self;
}
@end