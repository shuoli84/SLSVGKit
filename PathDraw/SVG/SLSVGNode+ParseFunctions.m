//
// Created by Li Shuo on 13-9-6.
// Copyright (c) 2013 com.menic. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "SLSVGNode+ParseFunctions.h"


@implementation SLSVGNode (ParseFunctions)


float parseFloat(char const * string, unsigned int index, int* length){
    float result = 0.f;
    float power = 1;
    BOOL fraction = NO;
    BOOL positive = YES;
    unsigned int i = index;
    if(string[i] == '-'){
        positive = NO;
        i++;
    }
    else if(string[i] == '+'){
        positive = YES;
        i++;
    }

    while (string[i] && (string[i] == '.' || isdigit(string[i]))){
        char c = string[i++];
        if(c == '.'){
            if (fraction){
                break;
            }
            fraction = YES;
        }
        else{
            int v = c - '0';
            if(!fraction){
                result = result * 10 + v;
            }
            else{
                power = power / 10;
                result += v * power;
            }
        }
    }

    *length = i - index;
    return positive ? result : -result;
}

/**
* output the array which holds parsed element of absolute positions and types
*/
+(NSArray *)parseDString:(NSString*)d{

#define SKIPSPACE  while (index < length && isspace(string[index])){ index++; }
#define SKIPNONDIGITAL while (index < length && !isdigit(string[index]) && string[index] != '-' && string[index] != '+'){index++;}

    NSMutableArray *parsedCommands = [NSMutableArray array];

    char const *string = d.UTF8String;
    unsigned int length = d.length;
    float last_x = 0.f, last_y = 0.f;
    char lastCommand = 'M';

    for (unsigned int index = 0; index < d.length;){
        SKIPSPACE
        char c = string[index];

        if(isdigit(c) || c == '-' || c == '.' || c == '+'){
            c = lastCommand;
            index--;
        }
        else{
            index++;
        }

        SKIPSPACE

        if (c == 'm' || c == 'M' || c =='L' || c =='l' || c == 't' || c == 'T'){
            // x y
            float x, y;
            int l = 0;

            SKIPSPACE
            x = parseFloat(string, index, &l);
            index += l;

            SKIPNONDIGITAL

            y = parseFloat(string, index, &l);
            index += l;

            if(c >= 'a'){
                last_x = x = last_x + x;
                last_y = y = last_y + y;
            }
            else{
                last_x = x;
                last_y = y;
            }

            NSString *command = [NSString stringWithFormat:@"%c", toupper(c)];
            [parsedCommands addObject:@[command, @[@(x), @(y)]]];
        }
        else if (c == 'h' || c == 'H' || c == 'v' || c =='V'){
            // x | y
            SKIPSPACE
            int len;
            float v = parseFloat(string, index, &len);

            if(c >= 'a'){
                if(c == 'h'){
                    last_x = v = last_x + v;
                }
                else if (c=='v'){
                    last_y = v = last_y + v;
                }
            }
            else{
                if(c=='H'){
                    last_x = v;
                }
                else{
                    last_y = v;
                }
            }

            NSString *command = [NSString stringWithFormat:@"%c", toupper(c)];
            [parsedCommands addObject:@[command, @[@(v)]]];
        }
        else if (c == 'c' || c == 'C'){
            // x1 y1 x2 y2 x y
            float x1, y1, x2, y2, x, y;
            int len;
            SKIPSPACE
            x1 = parseFloat(string, index, &len);
            index+=len;

            SKIPNONDIGITAL
            y1 = parseFloat(string, index, &len);
            index+=len;

            SKIPNONDIGITAL
            x2 = parseFloat(string, index, &len);
            index += len;

            SKIPNONDIGITAL
            y2 = parseFloat(string, index, &len);
            index+=len;

            SKIPNONDIGITAL
            x = parseFloat(string, index, &len);
            index += len;

            SKIPNONDIGITAL
            y = parseFloat(string, index, &len);
            index += len;

            if(c >= 'a'){
                x1 += last_x;
                y1 += last_y;
                x2 += last_x;
                y2 += last_y;
                last_x = x = x + last_x;
                last_y = y = y + last_y;
            }
            else{
                last_x = x;
                last_y = y;
            }

            NSString *command = [NSString stringWithFormat:@"%c", toupper(c)];
            [parsedCommands addObject:@[command, @[@(x1), @(y1), @(x2), @(y2), @(x), @(y)]]];
        }
        else if (c == 's' || c == 'S' || c == 'q' || c == 'Q'){
            // x2 y2 x y
            float x2, y2, x, y;
            int len;
            SKIPSPACE
            x2 = parseFloat(string, index, &len);
            index += len;
            SKIPNONDIGITAL
            y2 = parseFloat(string, index, &len);
            index += len;
            SKIPNONDIGITAL

            x = parseFloat(string, index, &len);
            index += len;
            SKIPNONDIGITAL

            y = parseFloat(string, index, &len);
            index += len;

            if(c >= 'a'){
                x2 += last_x;
                y2 += last_y;
                last_x = x = x + last_x;
                last_y = y = y + last_y;
            }
            else{
                last_x = x;
                last_y = y;
            }

            NSString *command = [NSString stringWithFormat:@"%c", toupper(c)];
            [parsedCommands addObject:@[command, @[@(x2), @(y2), @(x), @(y)]]];
        }
        else if (c == 'a' || c == 'A'){
            // rx ry x-axis-rotation large-arc-flag sweep-flag x y
            SKIPNONDIGITAL
            float rx, ry, xAxisRotation, largeFlag, sweepFlag, x, y;
            int len;
            rx = parseFloat(string, index, &len);
            index+=len;
            SKIPNONDIGITAL;
            ry = parseFloat(string, index, &len);
            index+=len;
            SKIPNONDIGITAL
            xAxisRotation = parseFloat(string, index, &len);
            index+=len;
            SKIPNONDIGITAL
            largeFlag = parseFloat(string, index, &len);
            index+=len;
            SKIPNONDIGITAL
            sweepFlag = parseFloat(string, index, &len);
            index+=len;
            SKIPNONDIGITAL
            x = parseFloat(string, index, &len);
            index+=len;
            SKIPNONDIGITAL
            y = parseFloat(string, index, &len);
            index+=len;

            if(c >= 'a'){
                x += last_x;
                y += last_y;
            }
            else{
                last_x = x;
                last_y = y;
            }

            NSString *command = [NSString stringWithFormat:@"%c", toupper(c)];
            [parsedCommands addObject:@[command, @[@(rx), @(ry), @(xAxisRotation), @(largeFlag), @(sweepFlag), @(x), @(y)]]];
        }
        else if (c == 'z' || c == 'Z'){
            [parsedCommands addObject:@[@"Z"]];
        }
        else{
            NSLog(@"got unsupported command %c", c);
        }

        lastCommand = c;
    }

    return parsedCommands;
}

+(NSArray *)parseTransform:(NSString*)transform{
    //translate(-10, -20) scale(2) rotate(45) translate(5,10) skewX(30) skewY(20) matrix( 1, 2, 3, 4, 5, 6)
    NSMutableArray *commands = [NSMutableArray array];
    char const *string = transform.UTF8String;
    unsigned int index = 0;
    unsigned int length = transform.length;

#undef SKIPSPACE
#define SKIPSPACE  while (index < length && isspace(string[index])){ index++;}

    SKIPSPACE
    char *buf = malloc(transform.length);

    while (index < length){
        int bufIndex = 0;
        SKIPSPACE
        while (index < length && isalpha(string[index])){
            buf[bufIndex++] = string[index++];
        }

        buf[bufIndex] = 0;
        NSString *name = [NSString stringWithUTF8String:buf];

        SKIPSPACE
        while (string[index] != '('){index++;}

        if (string[index] == '('){
            ++index;//skip (
            SKIPSPACE

            NSMutableArray *params = [NSMutableArray array];

            while (isnumber(string[index]) || string[index] == '+' || string[index] == '-' || string[index] == '.'){
                int len;
                float param = parseFloat(string, index, &len);
                index += len;
                SKIPSPACE

                [params addObject:@(param)];

                if(string[index] == ','){
                    index++;
                    SKIPSPACE
                }
            }

            if (string[index] ==')'){
                index++;
                SKIPSPACE

                [commands addObject:@[name, params.copy]];
            }
        }
        else{
            index++;
        }
    }
    free(buf);

    return commands;
}

+(CGAffineTransform)transformMatrix:(NSString*)transform{
    CGAffineTransform matrix = CGAffineTransformIdentity;

    NSArray *transforms = [self parseTransform:transform];
    for (NSArray *transform in transforms){
        NSString *command = transform[0];
        NSArray *params = transform[1];
        CGAffineTransform m;
        if([command isEqualToString:@"matrix"]){
            m = CGAffineTransformMake([params[0] floatValue], [params[1] floatValue], [params[2] floatValue], [params[3] floatValue], [params[4] floatValue], [params[5] floatValue]);
        }
        else if ([command isEqualToString:@"translate"]){
            m = CGAffineTransformMakeTranslation([params[0] floatValue], [params[1] floatValue]);
        }
        else if ([command isEqualToString:@"rotate"]){
            m = CGAffineTransformMakeRotation([params[0] floatValue] / 180.f * (float)M_PI);
        }
        else if([command isEqualToString:@"scale"]){
            m = CGAffineTransformMakeScale([params[0] floatValue], [params[0] floatValue]);
        }
        else if ([command isEqualToString:@"skewX"]){
            m = CGAffineTransformIdentity;
            m.c = tanf([params[0] floatValue] / 180.f * (float)M_PI);
        }
        else if ([command isEqualToString:@"skewY"]){
            m = CGAffineTransformIdentity;
            m.b = tanf([params[0] floatValue] / 180.f * (float)M_PI);
        }
        matrix = CGAffineTransformConcat(m, matrix);
    }

    return matrix;
}

+(UIColor *)parseColor:(NSString*)colorString{
    static NSDictionary *colorNameDictionary;
    static dispatch_once_t predicate;

    dispatch_once(&predicate, ^{
        colorNameDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
            @"rgb(240, 248, 255)", @"aliceblue",
            @"rgb(250, 235, 215)", @"antiquewhite",
            @"rgb( 0, 255, 255)", @"aqua",
            @"rgb(127, 255, 212)", @"aquamarine",
            @"rgb(240, 255, 255)", @"azure",
            @"rgb(245, 245, 220)", @"beige",
            @"rgb(255, 228, 196)", @"bisque",
            @"rgb( 0, 0, 0)", @"black",
            @"rgb(255, 235, 205)", @"blanchedalmond",
            @"rgb( 0, 0, 255)", @"blue",
            @"rgb(138, 43, 226)", @"blueviolet",
            @"rgb(165, 42, 42)", @"brown",
            @"rgb(222, 184, 135)", @"burlywood",
            @"rgb( 95, 158, 160)", @"cadetblue",
            @"rgb(127, 255, 0)", @"chartreuse",
            @"rgb(210, 105, 30)", @"chocolate",
            @"rgb(255, 127, 80)", @"coral",
            @"rgb(100, 149, 237)", @"cornflowerblue",
            @"rgb(255, 248, 220)", @"cornsilk",
            @"rgb(220, 20, 60)", @"crimson",
            @"rgb( 0, 255, 255)", @"cyan",
            @"rgb( 0, 0, 139)", @"darkblue",
            @"rgb( 0, 139, 139)", @"darkcyan",
            @"rgb(184, 134, 11)", @"darkgoldenrod",
            @"rgb(169, 169, 169)", @"darkgray",
            @"rgb( 0, 100, 0)", @"darkgreen",
            @"rgb(169, 169, 169)", @"darkgrey",
            @"rgb(189, 183, 107)", @"darkkhaki",
            @"rgb(139, 0, 139)", @"darkmagenta",
            @"rgb( 85, 107, 47)", @"darkolivegreen",
            @"rgb(255, 140, 0)", @"darkorange",
            @"rgb(153, 50, 204)", @"darkorchid",
            @"rgb(139, 0, 0)", @"darkred",
            @"rgb(233, 150, 122)", @"darksalmon",
            @"rgb(143, 188, 143)", @"darkseagreen",
            @"rgb( 72, 61, 139)", @"darkslateblue",
            @"rgb( 47, 79, 79)", @"darkslategray",
            @"rgb( 47, 79, 79)", @"darkslategrey",
            @"rgb( 0, 206, 209)", @"darkturquoise",
            @"rgb(148, 0, 211)", @"darkviolet",
            @"rgb(255, 20, 147)", @"deeppink",
            @"rgb( 0, 191, 255)", @"deepskyblue",
            @"rgb(105, 105, 105)", @"dimgray",
            @"rgb(105, 105, 105)", @"dimgrey",
            @"rgb( 30, 144, 255)", @"dodgerblue",
            @"rgb(178, 34, 34)", @"firebrick",
            @"rgb(255, 250, 240)", @"floralwhite",
            @"rgb( 34, 139, 34)", @"forestgreen",
            @"rgb(255, 0, 255)", @"fuchsia",
            @"rgb(220, 220, 220)", @"gainsboro",
            @"rgb(248, 248, 255)", @"ghostwhite",
            @"rgb(255, 215, 0)", @"gold",
            @"rgb(218, 165, 32)", @"goldenrod",
            @"rgb(128, 128, 128)", @"gray",
            @"rgb(128, 128, 128)", @"grey",
            @"rgb( 0, 128, 0)", @"green",
            @"rgb(173, 255, 47)", @"greenyellow",
            @"rgb(240, 255, 240)", @"honeydew",
            @"rgb(255, 105, 180)", @"hotpink",
            @"rgb(205, 92, 92)", @"indianred",
            @"rgb( 75, 0, 130)", @"indigo",
            @"rgb(255, 255, 240)", @"ivory",
            @"rgb(240, 230, 140)", @"khaki",
            @"rgb(230, 230, 250)", @"lavender",
            @"rgb(255, 240, 245)", @"lavenderblush",
            @"rgb(124, 252, 0)", @"lawngreen",
            @"rgb(255, 250, 205)", @"lemonchiffon",
            @"rgb(173, 216, 230)", @"lightblue",
            @"rgb(240, 128, 128)", @"lightcoral",
            @"rgb(224, 255, 255)", @"lightcyan",
            @"rgb(250, 250, 210)", @"lightgoldenrodyellow",
            @"rgb(211, 211, 211)", @"lightgray",
            @"rgb(144, 238, 144)", @"lightgreen",
            @"rgb(211, 211, 211)", @"lightgrey",
            @"rgb(255, 182, 193)", @"lightpink",
            @"rgb(255, 160, 122)", @"lightsalmon",
            @"rgb( 32, 178, 170)", @"lightseagreen",
            @"rgb(135, 206, 250)", @"lightskyblue",
            @"rgb(119, 136, 153)", @"lightslategray",
            @"rgb(119, 136, 153)", @"lightslategrey",
            @"rgb(176, 196, 222)", @"lightsteelblue",
            @"rgb(255, 255, 224)", @"lightyellow",
            @"rgb( 0, 255, 0)", @"lime",
            @"rgb( 50, 205, 50)", @"limegreen",
            @"rgb(250, 240, 230)", @"linen",
            @"rgb(255, 0, 255)", @"magenta",
            @"rgb(128, 0, 0)", @"maroon",
            @"rgb(102, 205, 170)", @"mediumaquamarine",
            @"rgb( 0, 0, 205)", @"mediumblue",
            @"rgb(186, 85, 211)", @"mediumorchid",
            @"rgb(147, 112, 219)", @"mediumpurple",
            @"rgb( 60, 179, 113)", @"mediumseagreen",
            @"rgb(123, 104, 238)", @"mediumslateblue",
            @"rgb( 0, 250, 154)", @"mediumspringgreen",
            @"rgb( 72, 209, 204)", @"mediumturquoise",
            @"rgb(199, 21, 133)", @"mediumvioletred",
            @"rgb( 25, 25, 112)", @"midnightblue",
            @"rgb(245, 255, 250)", @"mintcream",
            @"rgb(255, 228, 225)", @"mistyrose",
            @"rgb(255, 228, 181)", @"moccasin",
            @"rgb(255, 222, 173)", @"navajowhite",
            @"rgb( 0, 0, 128)", @"navy",
            @"rgb(253, 245, 230)", @"oldlace",
            @"rgb(128, 128, 0)", @"olive",
            @"rgb(107, 142, 35)", @"olivedrab",
            @"rgb(255, 165, 0)", @"orange",
            @"rgb(255, 69, 0)", @"orangered",
            @"rgb(218, 112, 214)", @"orchid",
            @"rgb(238, 232, 170)", @"palegoldenrod",
            @"rgb(152, 251, 152)", @"palegreen",
            @"rgb(175, 238, 238)", @"paleturquoise",
            @"rgb(219, 112, 147)", @"palevioletred",
            @"rgb(255, 239, 213)", @"papayawhip",
            @"rgb(255, 218, 185)", @"peachpuff",
            @"rgb(205, 133, 63)", @"peru",
            @"rgb(255, 192, 203)", @"pink",
            @"rgb(221, 160, 221)", @"plum",
            @"rgb(176, 224, 230)", @"powderblue",
            @"rgb(128, 0, 128)", @"purple",
            @"rgb(255, 0, 0)", @"red",
            @"rgb(188, 143, 143)", @"rosybrown",
            @"rgb( 65, 105, 225)", @"royalblue",
            @"rgb(139, 69, 19)", @"saddlebrown",
            @"rgb(250, 128, 114)", @"salmon",
            @"rgb(244, 164, 96)", @"sandybrown",
            @"rgb( 46, 139, 87)", @"seagreen",
            @"rgb(255, 245, 238)", @"seashell",
            @"rgb(160, 82, 45)", @"sienna",
            @"rgb(192, 192, 192)", @"silver",
            @"rgb(135, 206, 235)", @"skyblue",
            @"rgb(106, 90, 205)", @"slateblue",
            @"rgb(112, 128, 144)", @"slategray",
            @"rgb(112, 128, 144)", @"slategrey",
            @"rgb(255, 250, 250)", @"snow",
            @"rgb( 0, 255, 127)", @"springgreen",
            @"rgb( 70, 130, 180)", @"steelblue",
            @"rgb(210, 180, 140)", @"tan",
            @"rgb( 0, 128, 128)", @"teal",
            @"rgb(216, 191, 216)", @"thistle",
            @"rgb(255, 99, 71)", @"tomato",
            @"rgb( 64, 224, 208)", @"turquoise",
            @"rgb(238, 130, 238)", @"violet",
            @"rgb(245, 222, 179)", @"wheat",
            @"rgb(255, 255, 255)", @"white",
            @"rgb(245, 245, 245)", @"whitesmoke",
            @"rgb(255, 255, 0)", @"yellow",
            nil];
    });

    colorString = [colorString lowercaseString];
    colorString = [colorString stringByReplacingOccurrencesOfString:@" " withString:@""];

    UIColor *result;

    if(![colorString hasPrefix:@"#"] && ![colorString hasPrefix:@"rgb"]){
        colorString = colorNameDictionary[colorString];
    }

    if([colorString hasPrefix:@"#"]){
        colorString = [colorString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"#"]];
        if(colorString.length == 3){
            colorString = [NSString stringWithFormat:@"%c%c%c%c%c%c", [colorString characterAtIndex:0], [colorString characterAtIndex:0], [colorString characterAtIndex:1], [colorString characterAtIndex:1], [colorString characterAtIndex:2], [colorString characterAtIndex:2]];
        }

        unsigned int colorComponents[3];
        for (unsigned int i = 0, j = 0; i < colorString.length; i+=2, j+=1){
            NSString *hexString = [colorString substringWithRange:NSMakeRange(i, 2)];
            NSScanner* scanner = [NSScanner scannerWithString:hexString];
            [scanner scanHexInt:colorComponents+j];
        }

        colorString = [NSString stringWithFormat:@"rgb(%d,%d,%d)",colorComponents[0], colorComponents[1], colorComponents[2]];
    }

    if ([colorString hasPrefix:@"rgb"]){
        colorString = [colorString stringByReplacingOccurrencesOfString:@"rgb" withString:@""];
        colorString = [colorString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"()"]];
        NSArray *components = [colorString componentsSeparatedByString:@","];
        if(components.count == 3){
#define colorValue(str) [(str) hasSuffix:@"%"]?  \
                                    [[(str) stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"%"]] floatValue] \
                                    : \
                                    [(str) floatValue] / 255

            float red = colorValue(components[0]);
            float green = colorValue(components[1]);
            float blue = colorValue(components[2]);

            result = [UIColor colorWithRed:red green:green blue:blue alpha:1.f];
        }
    }

    return result;
}

+(NSArray *)parsePoints:(NSString*)points{
    NSMutableArray *result = [NSMutableArray array];

    points = [points stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSArray *coordinates = [points componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" ,;"]];

    coordinates = [coordinates filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *evaluatedObject, NSDictionary *bindings) {
        if(evaluatedObject.length == 0){
            return NO;
        }
        return YES;
    }]];

    if(coordinates.count % 2 != 0){
        NSLog(@"odd number of coordinates, error");
        return nil;
    }

    for(unsigned int i = 0; i < coordinates.count; i+=2){
        [result addObject:@[coordinates[i], coordinates[i+1]]];
    }

    return result;
}

+(NSDictionary *)parseStyle:(NSString*)style{
    //fill: red; stroke: blue; stroke-width: 3
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    NSArray *rules = [style componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@";"]];
    for (NSString *rule in rules){
        NSArray *keyValuePair = [rule componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@":"]];
        if(keyValuePair.count == 2){
            [dictionary setObject:[keyValuePair[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:[keyValuePair[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
        }
    }

    return dictionary;
}

+(NSString *)parseUrlId:(NSString *)url {
    if([url hasPrefix:@"url"]){
        return [[url substringFromIndex:3]stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" ()#"]];
    }
    return nil;
}

NSString* parseSelector(char const *string, unsigned int index, int* len){
    unsigned int startPos = index;
    while(string[index] && string[index] != '{'){
        index++;
    }

    *len = index - startPos;
    char* nameBuf = malloc(index-startPos+1);
    strncpy(nameBuf, string + startPos, index-startPos);
    nameBuf[index-startPos] = 0;

    NSString *selector = [NSString stringWithUTF8String:nameBuf];

    free(nameBuf);

    return selector;
}

NSString* parseRules(char const *string, unsigned int index, int* len){
    unsigned int startPos = index;
    while (string[index] && string[index] != '}'){
        index++;
    }

    *len = index - startPos;
    char *strBuf = malloc(index-startPos+1);
    strncpy(strBuf, string + startPos, index - startPos);
    strBuf[index-startPos] = 0;

    NSString *rules = [NSString stringWithUTF8String:strBuf];
    free(strBuf);
    return rules;
}

+(NSDictionary *)parseCSS:(NSString*)css{
    //.st3{fill:none;stroke:#231F20;stroke-miterlimit:10;}
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    char const *string = css.UTF8String;
    int length = css.length;
    int len;
    unsigned int index = 0;

    for (;index < length;){
        SKIPSPACE
        NSString *selector = parseSelector(string, index, &len);
        index+=len;

        SKIPSPACE
        if (string[index] == '{'){
            index++;

            SKIPSPACE
            NSString *rules = parseRules(string, index, &len);
            [dictionary setObject:[SLSVGNode parseStyle:rules] forKey:selector];
            index += len;

            SKIPSPACE
            if(string[index] == '}'){
                index++;
            }
        }
        else{
            SKIPSPACE
            index++;
        }
    }

    return dictionary;
}

+(NSArray *)parseDashArray:(NSString*)dashArray{
    NSArray *components = [dashArray componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" ,;"]];
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:components.count];
    for(NSString *num in components){
        if (num.length > 0){
            [results addObject:@(num.floatValue)];
        }
    }
    return results;
}
@end