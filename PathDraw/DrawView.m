//
// Created by Li Shuo on 13-7-29.
// Copyright (c) 2013 com.menic. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <QuartzCore/QuartzCore.h>
#import "DrawView.h"
#import "UIGestureRecognizer+BlocksKit.h"
#import "DrawShape.h"
#import "CGUtil.h"
#import "DrawDocument.h"

typedef void (^UndoBlock)();
typedef void (^RedoBlock)();

@interface UndoItem : NSObject{

}
@property (nonatomic, copy) UndoBlock undoBlock;
@property (nonatomic, copy) RedoBlock redoBlock;
@end

@implementation UndoItem
@end

typedef NS_ENUM(NSInteger, PointType){
    PointTypeLocation,
    PointTypeControlPoint1,
    PointTypeControlPoint2,
};

@implementation DrawView {
    NSMutableArray *_undoArray; //Array holds blocks which undo
    NSMutableArray *_redoArray; //Array holds blocks which undo

    DrawShape * __weak _currentShape;
    PathOperation * __weak _currentPathOperation;
    PointType _selectedPointType;

    int _bottomDrawShouldStartFromIndex;
    UIImageView* _bottomImageView;
    UIImageView* _middleImageView;
    UIImageView* _topImageView;
}

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self){
        _fill = NO;
        _stroke = YES;

        _bottomDrawShouldStartFromIndex = 0;

        _draw = [[DrawDocument alloc]init];
        _undoArray = [NSMutableArray array];
        _redoArray = [NSMutableArray array];

        self.clipsToBounds = YES;
        _bottomImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _bottomImageView.userInteractionEnabled = YES;
        _bottomImageView.contentMode = UIViewContentModeScaleAspectFill;
        _bottomImageView.layer.magnificationFilter = kCAFilterNearest;
        [self addSubview:_bottomImageView];

        _middleImageView = [[UIImageView alloc] init];
        _middleImageView.userInteractionEnabled = NO;
        _middleImageView.contentMode = UIViewContentModeScaleAspectFill;
        _middleImageView.layer.magnificationFilter = kCAFilterNearest;
        [self addSubview:_middleImageView];

        _topImageView = [[UIImageView alloc] init];

        _topImageView.userInteractionEnabled = NO;
        _topImageView.contentMode = UIViewContentModeScaleAspectFill;
        _topImageView.layer.magnificationFilter = kCAFilterNearest;
        [self addSubview:_topImageView];

        typeof(self) __weak weakSelf = self;
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
            [weakSelf tap:sender state:state location:location];
        }];
        tapGestureRecognizer.numberOfTouchesRequired = 1;
        [_bottomImageView addGestureRecognizer:tapGestureRecognizer];

        UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
            [weakSelf pan:sender state:state location:location];
        }];
        [panGestureRecognizer setMinimumNumberOfTouches:1];
        [panGestureRecognizer setMaximumNumberOfTouches:1];
        [_bottomImageView addGestureRecognizer:panGestureRecognizer];

        UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
            [weakSelf pinch:(UIPinchGestureRecognizer *)sender state:state location:location];
        }];
        [self addGestureRecognizer:pinchGestureRecognizer];
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    if(CGSizeEqualToSize(CGSizeZero, _bottomImageView.frame.size)){
        _bottomImageView.frame = self.bounds;
    }
    if(CGSizeEqualToSize(CGSizeZero, _middleImageView.frame.size)){
        _middleImageView.frame = self.bounds;
    }
    if(CGSizeEqualToSize(CGSizeZero, _topImageView.frame.size)){
        _topImageView.frame = self.bounds;
    }
}

-(PathOperation *)pathOperationWithLocation:(CGPoint)location controlPoint:(CGPoint)controlPoint operationType:(PathOperationType)operationType{
    PathOperation *op = [[PathOperation alloc]init];
    if (_currentShape.pathOperations.count == 0){
        op.operationType = PathOperationMoveTo;
        op.location = location;
        op.controlPoint1 = op.location;
        op.controlPoint2 = op.location;
    }
    else{
        op.locationType = LocationTypeRelativeToFirst;
        CGPoint firstPoint = [_currentShape absolutePointForIndex:0];
        op.location = CGPointMake(location.x - firstPoint.x, location.y - firstPoint.y);
        op.controlPoint1 = CGPointMake(controlPoint.x - firstPoint.x, controlPoint.y - firstPoint.y);
        op.controlPoint2 = op.controlPoint1;

        op.operationType = operationType;

        if(pointIsNearPoint(location, [(PathOperation*)_currentShape.pathOperations[0] location])){
            op.operationType = PathOperationClose;
            op.location = CGPointMake(CGFLOAT_MAX, CGFLOAT_MAX);
        }
    }
    return op;
}

-(void)tap:(UIGestureRecognizer *)sender state:(UIGestureRecognizerState)state location:(CGPoint)location{
    CGFloat scale = self.frame.size.width / _bottomImageView.frame.size.width;
    location = CGPointMake(location.x * scale, location.y * scale);
    location = CGPointMake(floorf(location.x), floorf(location.y));

    if(_mode == DrawModeSelect){
        _currentPathOperation = nil;
        if(_currentShape != nil){
            CGFloat minDistance = 10000;
            int resultIndex = NSNotFound;
            int shapeCount = _currentShape.operationsWithAbsolutePoint.count;
            PointType selectedPointType = PointTypeLocation;
            for(int index = 0; index < shapeCount; ++index){
                PathOperation *op = _currentShape.operationsWithAbsolutePoint[index];
                if(pointIsNearPoint(op.location, location)){
                    CGFloat distance = distanceBetweenPoints(op.location, location);
                    if(minDistance > distance){
                        minDistance = distance;
                        resultIndex = index;
                        selectedPointType = PointTypeLocation;
                    }
                }

                switch (op.operationType){
                    case PathOperationQuadCurveTo:{
                        if(pointIsNearPoint(op.controlPoint1, location)){
                            CGFloat distance = distanceBetweenPoints(op.controlPoint1, location);
                            if(minDistance > distance){
                                minDistance = distance;
                                resultIndex = index;
                                selectedPointType = PointTypeControlPoint1;
                            }
                        }
                        break;
                    }

                    case PathOperationArc:
                    case PathOperationRect:
                    case PathOperationOval:
                    case PathOperationEllipse:
                    case PathOperationCurveTo:{
                        CGFloat distance;
                        if(pointIsNearPoint(op.controlPoint1, location)){
                            distance = distanceBetweenPoints(op.controlPoint1, location);
                            if(minDistance > distance){
                                minDistance = distance;
                                resultIndex = index;
                                selectedPointType = PointTypeControlPoint1;
                            }
                        }

                        if(pointIsNearPoint(op.controlPoint2, location)){
                            distance = distanceBetweenPoints(op.controlPoint2, location);
                            if(minDistance > distance){
                                minDistance = distance;
                                resultIndex = index;
                                selectedPointType = PointTypeControlPoint2;
                            }
                        }
                        break;
                    }
                    default:
                       break;
                }
            }

            if(resultIndex != NSNotFound){
                _currentPathOperation = _currentShape.pathOperations[resultIndex];
                _selectedPointType = selectedPointType;
            }
        }
        if(_currentPathOperation == nil){
            _currentShape = nil;
            for(DrawShape *shape in _draw.shapes){
                if(pointIsNearPoint([(PathOperation *)shape.pathOperations[0] location], location)){
                    _currentShape = shape;
                    _currentPathOperation = shape.pathOperations[0];
                }
            }
        }
    }
    else if(_mode == DrawModePath){
        if(_currentShape && [_currentShape.pathOperations.lastObject operationType] == PathOperationClose){
            _currentShape = nil;
        }

        if(!_currentShape){
            [self setupCurrentShape];
        }
        PathOperation *op = [self pathOperationWithLocation:location controlPoint:location operationType:PathOperationLineTo];
        [self appendOperationToCurrentShape:op undoable:_currentShape.pathOperations.count > 0 ? YES : NO];
    }
    else if(_mode == DrawModeInsert){
        if(_currentShape && _currentPathOperation){
            PathOperation *op = [self pathOperationWithLocation:location controlPoint:location operationType:PathOperationLineTo];
            NSUInteger index = [_currentShape.pathOperations indexOfObject:_currentPathOperation];
            if (index != NSNotFound){
                int indexToBeInsert = index + 1;
                [_currentShape.pathOperations insertObject:op atIndex:indexToBeInsert];

                UndoItem *undo = [[UndoItem alloc]init];
                DrawShape *shape = _currentShape;
                undo.undoBlock = ^{
                    [shape.pathOperations removeObject:op];
                };
                undo.redoBlock = ^{
                    [shape.pathOperations insertObject:op atIndex:indexToBeInsert];
                };
                [self addUndoItem:undo];

                _currentPathOperation = op;

                self.mode = DrawModeSelect;
            }
            else{
                NSLog(@"Error, not able to find index of the current point");
            }
        }
    }
    [self drawImage];
}

-(void)pan:(UIGestureRecognizer *)sender state:(UIGestureRecognizerState)state location:(CGPoint)location{
    static CGPoint prevAbsolutePoint;
    CGFloat scale = self.frame.size.width / _bottomImageView.frame.size.width;
    location = CGPointMake(location.x * scale, location.y * scale);
    if(_mode == DrawModeSelect){
        static CGPoint locationToRestore;
        if(state == UIGestureRecognizerStateBegan){
            if (_currentPathOperation){
                switch (_selectedPointType){
                    case PointTypeLocation:
                        locationToRestore = _currentPathOperation.location;
                        break;
                    case PointTypeControlPoint1:
                        locationToRestore = _currentPathOperation.controlPoint1;
                        break;
                    case PointTypeControlPoint2:
                        locationToRestore = _currentPathOperation.controlPoint2;
                        break;
                };
            }
        }
        else{
            if(_currentPathOperation){
                switch (_selectedPointType){
                    case PointTypeLocation:
                        _currentPathOperation.location = CGPointMake(_currentPathOperation.location.x + location.x - prevAbsolutePoint.x, _currentPathOperation.location.y + location.y - prevAbsolutePoint.y);
                        break;
                    case PointTypeControlPoint1:
                        _currentPathOperation.controlPoint1 = CGPointMake(_currentPathOperation.controlPoint1.x + location.x - prevAbsolutePoint.x, _currentPathOperation.controlPoint1.y + location.y - prevAbsolutePoint.y);
                        break;
                    case PointTypeControlPoint2:
                        _currentPathOperation.controlPoint2 = CGPointMake(_currentPathOperation.controlPoint2.x + location.x - prevAbsolutePoint.x, _currentPathOperation.controlPoint2.y + location.y - prevAbsolutePoint.y);
                        break;
                }

                if(state == UIGestureRecognizerStateEnded){
                    CGPoint l = locationToRestore;
                    CGPoint newLocation;
                    PathOperation *op = _currentPathOperation;
                    UndoItem *undo = [[UndoItem alloc]init];

                    switch (_selectedPointType){
                        case PointTypeLocation: {
                            newLocation = _currentPathOperation.location;
                            undo.undoBlock = ^{
                                op.location = l;
                            };
                            undo.redoBlock = ^{
                                op.location = newLocation;
                            };
                            break;
                        }
                        case PointTypeControlPoint1:{
                            newLocation = _currentPathOperation.controlPoint1;
                            undo.undoBlock = ^{
                                op.controlPoint1 = l;
                            };
                            undo.redoBlock = ^{
                                op.controlPoint1 = newLocation;
                            };
                            break;
                        }
                        case PointTypeControlPoint2:{
                            newLocation = _currentPathOperation.controlPoint2;
                            undo.undoBlock = ^{
                                op.controlPoint2 = l;
                            };
                            undo.redoBlock = ^{
                                op.controlPoint2 = newLocation;
                            };
                            break;
                        }
                    }
                    [self addUndoItem:undo];
                }
            }
        }
    }
    else if(_mode == DrawModePen){
        if(state == UIGestureRecognizerStateBegan){
            [self setupCurrentShape];
            PathOperation *op = [[PathOperation alloc]init];
            op.operationType = PathOperationMoveTo;
            op.location = location;
            op.controlPoint1 = location;
            op.controlPoint2 = location;
            [self appendOperationToCurrentShape:op undoable:NO];
        }
        else{
            if(!CGPointEqualToPoint(prevAbsolutePoint, location)){
                PathOperation *op = [[PathOperation alloc]init];
                op.operationType = PathOperationLineTo;
                op.locationType = LocationTypeRelativeToFirst;
                CGPoint firstPoint = [(PathOperation *)_currentShape.pathOperations[0] location];
                op.location = CGPointMake(location.x - firstPoint.x, location.y - firstPoint.y);
                op.controlPoint1 = op.location;
                op.controlPoint2 = op.location;
                [self appendOperationToCurrentShape:op undoable:NO];
            }
        }
    }
    else if (_mode == DrawModeLine){
        if(state == UIGestureRecognizerStateBegan){
            [self setupCurrentShape];

            PathOperation *op = [[PathOperation alloc]init];
            op.operationType = PathOperationMoveTo;
            op.location = location;
            op.controlPoint1 = op.location;
            op.controlPoint2 = op.location;
            [self appendOperationToCurrentShape:op undoable:NO];
        }
        else{
            PathOperation *op = nil;
            if (_currentShape.pathOperations.count == 2){
                op = _currentShape.pathOperations[1];
            }
            else{
                op = [[PathOperation alloc]init];
                op.operationType = PathOperationLineTo;
                [self appendOperationToCurrentShape:op undoable:NO];
                op.locationType = LocationTypeRelativeToFirst;
            }
            CGPoint firstLocation = [(PathOperation *)_currentShape.pathOperations[0] location];
            op.location = CGPointMake(location.x - firstLocation.x, location.y - firstLocation.y);
            op.controlPoint1 = op.location;
            op.controlPoint2 = op.location;
        }
    }
    else if (_mode == DrawModePath){
        if(state == UIGestureRecognizerStateBegan){
            if(_currentShape && [_currentShape.pathOperations.lastObject operationType] == PathOperationClose){
                _currentShape = nil;
            }
            if (!_currentShape){
                [self setupCurrentShape];
            }
            PathOperation *op = [self pathOperationWithLocation:location controlPoint:location operationType:PathOperationQuadCurveTo];
            [self appendOperationToCurrentShape:op undoable:_currentShape.pathOperations.count > 0 ? YES : NO];
        }
        else{
            PathOperation *op = [_currentShape.pathOperations lastObject];
            CGPoint absoluteLocation = [_currentShape absolutePointForIndex:_currentShape.pathOperations.count-1];
            op.controlPoint1 = CGPointMake(op.location.x + absoluteLocation.x - location.x, op.location.y + absoluteLocation.y - location.y);
        }
    }
    else if(_mode == DrawModeOval){
        if(state == UIGestureRecognizerStateBegan){
            [self setupCurrentShape];

            PathOperation *op = [[PathOperation alloc]init];
            op.operationType = PathOperationArc;
            op.location = location;
            //op.controlPoint1 = CGPointMake(0, 0);
            op.controlPoint1 = op.location;
            op.controlPoint2 = op.location;
            [self appendOperationToCurrentShape:op undoable:NO];
        }
        else{
            PathOperation *op = _currentShape.pathOperations.lastObject;
            op.controlPoint1 = location;
            op.controlPoint2 = location;
        }
    }
    else if (_mode == DrawModeRect){
        if(state == UIGestureRecognizerStateBegan){
            [self setupCurrentShape];

            PathOperation *op = [[PathOperation alloc]init];
            op.operationType = PathOperationRect;
            op.location = location;
            op.controlPoint1 = op.location;
            op.controlPoint2 = op.location;
            [self appendOperationToCurrentShape:op undoable:NO];
        }
        else{
            PathOperation *op = _currentShape.pathOperations.lastObject;
            op.controlPoint1 = location;
        }
    }
    else if(_mode == DrawModeEllipse){
        if(state == UIGestureRecognizerStateBegan){
            [self setupCurrentShape];

            PathOperation *op = [[PathOperation alloc] init];
            op.operationType = PathOperationEllipse;
            op.location = location;
            op.controlPoint1 = location;
            op.controlPoint2 = location;

            [self appendOperationToCurrentShape:op undoable:NO];
        }
        else{
            PathOperation *op = _currentShape.pathOperations.lastObject;
            op.controlPoint1 = location;
        }
    }
    [self drawImage];

    prevAbsolutePoint = location;
}

-(void)pinch:(UIPinchGestureRecognizer *)sender state:(UIGestureRecognizerState)state location:(CGPoint)location{
    static CGPoint prevLocation;
    if(state == UIGestureRecognizerStateBegan){
        prevLocation = location;
        return;
    }

    if (state == UIGestureRecognizerStateEnded){
        return;
    }

    UIPinchGestureRecognizer *pinchGestureRecognizer = sender;
    CGFloat scale = pinchGestureRecognizer.scale;

    CGSize maxSize = CGSizeMake(_originalSize.width * 40, _originalSize.height * 40);

    _bottomImageView.bounds = CGRectMake(0, 0, MIN(_bottomImageView.bounds.size.width * scale, maxSize.width), MIN(_bottomImageView.bounds.size.height * scale, maxSize.height));

    BOOL maximized = _bottomImageView.bounds.size.width == maxSize.width;

    if(!maximized){
        CGPoint prevCenter = _bottomImageView.center;
        _bottomImageView.center = CGPointMake(prevCenter.x - (location.x - prevCenter.x) * (scale -1), prevCenter.y - (location.y-prevCenter.y)*(scale-1));
    }

    _bottomImageView.center = CGPointMake(_bottomImageView.center.x + (location.x - prevLocation.x), _bottomImageView.center.y + (location.y - prevLocation.y));

    _middleImageView.frame = _bottomImageView.frame;
    _topImageView.frame = _bottomImageView.frame;

    pinchGestureRecognizer.scale = 1.0;

    prevLocation = location;
}

-(void)drawImage{
    int currentShapeIndex = _draw.shapes.count - 1;
    if(_currentShape != nil){
        int indexOfCurrent = [_draw.shapes indexOfObject:_currentShape];
        if(indexOfCurrent != NSNotFound){
            currentShapeIndex = indexOfCurrent;
        }
    }

    if(_bottomDrawShouldStartFromIndex > currentShapeIndex){
        _bottomDrawShouldStartFromIndex = 0;
        _bottomImageView.image = nil;
    }
    if(_bottomDrawShouldStartFromIndex < currentShapeIndex){
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0f);
        if (_bottomImageView.image){
            [_bottomImageView.image drawAtPoint:CGPointZero];
        }
        else{
            [[UIColor clearColor] setFill];
            [[UIBezierPath bezierPathWithRect:self.bounds] fill];
        }

        for(int index = _bottomDrawShouldStartFromIndex; index < currentShapeIndex; ++index){
            [self drawShape:_draw.shapes[index]];
        }
        _bottomDrawShouldStartFromIndex = currentShapeIndex;

        _bottomImageView.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }

    if(_bottomDrawShouldStartFromIndex >= 0 && _bottomDrawShouldStartFromIndex < _draw.shapes.count){
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0f);
        [self drawShape:_draw.shapes[_bottomDrawShouldStartFromIndex]];

        if(_mode == DrawModeSelect || _mode == DrawModeInsert){
            [[UIColor blueColor] setStroke];
            PathOperation *prevOp = nil;
            for(PathOperation *op in _currentShape.operationsWithAbsolutePoint){
                [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(op.location.x - 2.5, op.location.y - 2.5, 5, 5)] stroke];
                if(op.operationType == PathOperationQuadCurveTo){
                    [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(op.controlPoint1.x - 2.5, op.controlPoint1.y - 2.5, 5, 5)] stroke];

                    UIBezierPath *path = [UIBezierPath bezierPath];
                    [path moveToPoint:op.location] ;
                    [path addLineToPoint:op.controlPoint1];
                    [path stroke];
                }
                else if(op.operationType == PathOperationCurveTo){
                    [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(op.controlPoint1.x - 2.5, op.controlPoint1.y - 2.5, 5, 5)] stroke];
                    [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(op.controlPoint2.x - 2.5, op.controlPoint2.y - 2.5, 5, 5)] stroke];

                    UIBezierPath *path = [UIBezierPath bezierPath];
                    [path moveToPoint:op.location] ;
                    [path addLineToPoint:op.controlPoint2];
                    [path moveToPoint:op.controlPoint1];
                    [path addLineToPoint:prevOp.location];
                    [path stroke];
                }
                else if(op.operationType == PathOperationArc){
                    [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(op.controlPoint1.x - 2.5, op.controlPoint1.y - 2.5, 5, 5)] stroke];
                    [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(op.controlPoint2.x - 2.5, op.controlPoint2.y - 2.5, 5, 5)] stroke];
                }
                else if(op.operationType == PathOperationEllipse || op.operationType == PathOperationOval || op.operationType == PathOperationRect){
                    [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(op.controlPoint1.x - 2.5, op.controlPoint1.y - 2.5, 5, 5)] stroke];
                }
                prevOp = op;
            }

            if(_currentPathOperation != nil){
                [[UIColor greenColor] setStroke];
                CGPoint location = _currentPathOperation.location;

                if(_selectedPointType == PointTypeControlPoint1){
                    location = _currentPathOperation.controlPoint1;
                }
                else if(_selectedPointType == PointTypeControlPoint2){
                    location = _currentPathOperation.controlPoint2;
                }

                if(_currentPathOperation.locationType == LocationTypeRelativeToFirst){
                    location.x = location.x + [(PathOperation *)_currentShape.pathOperations[0] location].x;
                    location.y = location.y + [(PathOperation *)_currentShape.pathOperations[0] location].y;
                }
                UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(location.x - 5, location.y - 5, 10, 10)];
                [path stroke];
            }

            [[UIColor colorWithRed:52.f/255.f green:152.f/255.f blue:219.f/255.f alpha:0.7f] setFill];
            for (DrawShape *shape in _draw.shapes){
                if(shape.pathOperations.count > 0){
                    PathOperation *op = shape.pathOperations[0];
                    [[UIBezierPath bezierPathWithArcCenter:op.location radius:10 startAngle:0 endAngle:M_PI*2 clockwise:YES] fill];
                }
            }
        }
        _middleImageView.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }

    if(currentShapeIndex == _draw.shapes.count - 1){
        _topImageView.image = nil;
    }
    else{
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0f);
        [[UIColor clearColor] setFill];
        [[UIBezierPath bezierPathWithRect:self.bounds] fill];

        for(int index = currentShapeIndex + 1; index < _draw.shapes.count; ++index){
            [self drawShape:_draw.shapes[index]];
        }
        _topImageView.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
}

-(void)drawShape:(DrawShape*)shape{
    [shape generatePath];
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIBezierPath *path = shape.path;
    CGContextSetAllowsAntialiasing(context, shape.antiAliasing);
    if(shape.antiAliasing){
        CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    }
    if (shape.stroke){
        [shape.strokeColor setStroke];
        path.lineWidth = shape.lineWidth;
        path.lineCapStyle = kCGLineCapRound;
        [path stroke];
    }

    if (shape.fill){
        PathOperation *op = shape.pathOperations.lastObject;
        if(op.operationType == PathOperationClose || op.operationType == PathOperationRect || op.operationType == PathOperationArc ||
            op.operationType == PathOperationEllipse){
            [shape.fillColor setFill];
            CGContextSaveGState(context);
            [path addClip];
            CGContextFillRect(context, CGRectMake(0, 0, 500, 500));
            CGContextRestoreGState(context);
        }
    }
}

-(void)setupCurrentShape{
    DrawShape *shape = [[DrawShape alloc]init];
    shape.lineWidth = _lineWidth;
    shape.fill = _fill;
    shape.stroke = _stroke;
    shape.fillColor = _fillColor;
    shape.strokeColor = _strokeColor;

    [_draw.shapes addObject:shape];
    int index = _draw.shapes.count - 1;
    UndoItem *undo = [[UndoItem alloc]init];
    undo.undoBlock = ^{
        [_draw.shapes removeObject:shape];
    };
    undo.redoBlock = ^{
        [_draw.shapes insertObject:shape atIndex:index];
    };
    [self addUndoItem:undo];

    _currentShape = shape;
}

-(void)appendOperationToCurrentShape:(PathOperation *)op undoable:(BOOL)undoable{
    if(_currentShape){
        [_currentShape appendOperation:op];
        if(undoable){
            DrawShape *shape = _currentShape;
            UndoItem *undo = [[UndoItem alloc]init];
            undo.undoBlock = ^{
                [shape.pathOperations removeObject:op];
            };
            undo.redoBlock = ^{
                [shape.pathOperations addObject:op];
            };
            [self addUndoItem:undo];
        }
    }
}

-(void)clear{
    [_draw.shapes removeAllObjects];
    [_undoArray removeAllObjects];
    [_redoArray removeAllObjects];
    _bottomImageView.image = nil;
    _middleImageView.image = nil;
    _currentShape = nil;
    _bottomDrawShouldStartFromIndex = 0;
}

-(void)setMode:(DrawMode)mode {
    _mode = mode;
    [self drawImage];
}

-(void)undo{
    if(_undoArray.count > 0){
        _currentShape = nil;

        UndoItem *undo = _undoArray.lastObject;
        if(undo.undoBlock){
            undo.undoBlock();
        }
        [_undoArray removeLastObject];

        [_redoArray addObject:undo];
        [self refresh];
    }
}

-(void)redo{
    if(_redoArray.count > 0){
        _currentShape = nil;

        UndoItem *undo = _redoArray.lastObject;
        if(undo.redoBlock){
            undo.redoBlock();
        }
        [_redoArray removeLastObject];

        [_undoArray addObject:undo];

       [self refresh];
    }
}

-(void)refresh{
    _bottomDrawShouldStartFromIndex = 0;
    _bottomImageView.image = nil;
    _middleImageView.image = nil;

    [self drawImage];
}

-(void)dropCurrentShape {
    if(_currentShape){
        DrawShape *shape = _currentShape;
        int index = [_draw.shapes indexOfObject:shape];
        [_draw.shapes removeObjectAtIndex:index];

        typeof(self) __weak weakSelf = self;
        UndoItem *undo = [[UndoItem alloc]init];
        undo.undoBlock = ^{
            typeof(weakSelf) __strong strongSelf = weakSelf;
            [strongSelf->_draw.shapes insertObject:shape atIndex:index];
        };
        undo.redoBlock = ^{
            typeof(weakSelf) __strong strongSelf = weakSelf;
            [strongSelf->_draw.shapes removeObject:shape];
        };
        [self addUndoItem:undo];

        _currentShape = nil;
        [self refresh];
    }
}

-(void)dropCurrentPathOperation {
    if(_currentPathOperation){
        if(_currentShape.pathOperations.count == 1){
            [self dropCurrentShape];
            return;
        }
        NSInteger index = [_currentShape.pathOperations indexOfObject:_currentPathOperation];
        [_currentShape.pathOperations removeObjectAtIndex:index];

        UndoItem *undo = [[UndoItem alloc]init];

        DrawShape *shape = _currentShape;
        PathOperation *op = _currentPathOperation;
        undo.undoBlock = ^{
            [shape.pathOperations insertObject:op atIndex:index];
        };

        undo.redoBlock = ^{
            [shape.pathOperations removeObjectAtIndex:index];
        };

        [self addUndoItem:undo];
        _currentPathOperation = nil;
        [self refresh];
    }
}

-(void)changeCurrentPathOperationType:(PathOperationType)operationType{
    if(_currentPathOperation){
        _currentPathOperation.operationType = operationType;

        PathOperation *op = _currentPathOperation;
        PathOperationType prevType = op.operationType;

        UndoItem *undo = [[UndoItem alloc]init];

        undo.undoBlock = ^{
            op.operationType = prevType;
        };

        undo.redoBlock = ^{
            op.operationType = operationType;
        };

        [self addUndoItem:undo];

        [self refresh];
    }
}

-(void)sendBack:(int)far{
    if(_currentShape){
        int prevIndex = [_draw.shapes indexOfObject:_currentShape];
        int targetIndex = prevIndex - far;
        if(targetIndex < 0){
            targetIndex = 0;
        }
        else if(targetIndex >= _draw.shapes.count){
            targetIndex = _draw.shapes.count - 1;
        }
        if(prevIndex != targetIndex){
            [_draw.shapes removeObjectAtIndex:prevIndex];
            [_draw.shapes insertObject:_currentShape atIndex:targetIndex];

            DrawShape *shape = _currentShape;
            NSMutableArray *shapeArray = _draw.shapes;
            UndoItem *undo = [[UndoItem alloc]init];
            undo.undoBlock = ^{
                [shapeArray removeObjectAtIndex:targetIndex];
                [shapeArray insertObject:shape atIndex:prevIndex];
            };

            undo.redoBlock = ^{
                [shapeArray removeObjectAtIndex:prevIndex];
                [shapeArray insertObject:shape atIndex:targetIndex];
            };
            [self addUndoItem:undo];

            [self refresh];
        }
    }
}

-(void)addUndoItem:(UndoItem*)undoItem{
    [_undoArray addObject:undoItem];
    [_redoArray removeAllObjects];
}

-(void)setFill:(BOOL)fill {
    if(_fill != fill){
        _fill = fill;
        if(_currentShape && _currentShape.fill != fill){
            BOOL oldValue = _currentShape.fill;
            DrawShape *shape = _currentShape;

            _currentShape.fill = fill;

            UndoItem *undo = [[UndoItem alloc]init];

            undo.undoBlock = ^{
                shape.fill = oldValue;
            };

            undo.redoBlock = ^{
                shape.fill = fill;
            };

            [_undoArray addObject:undo];

            [self drawImage];
        }

        if(_fillChangeBlock){
            _fillChangeBlock(fill);
        }
    }
}

-(void)setStroke:(BOOL)stroke{
    if(_stroke != stroke){
        _stroke = stroke;
        if(_currentShape){
            _currentShape.stroke = stroke;
            [self drawImage];
        }

        if(_strokeChangeBlock){
            _strokeChangeBlock(stroke);
        }
    }
}
@end