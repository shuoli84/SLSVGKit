//
// Created by Li Shuo on 13-7-29.
// Copyright (c) 2013 com.menic. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "DrawView.h"
#import "UIGestureRecognizer+BlocksKit.h"
#import "FVDeclareHelper.h"
#import "DrawCacheImage.h"
#import "PathOperation.h"
#import "DrawShape.h"
#import "CGUtil.h"

typedef void (^UndoBlock)();
typedef void (^RedoBlock)();

@interface UndoItem : NSObject{

}
@property (nonatomic, copy) UndoBlock undoBlock;
@property (nonatomic, copy) RedoBlock redoBlock;
@end

@implementation UndoItem
@end

@implementation DrawView {
    NSMutableArray *_shapeArray; //point array holds all points sets
    NSMutableArray *_undoArray; //Array holds blocks which undo
    NSMutableArray *_redoArray; //Array holds blocks which undo

    DrawShape * __weak _currentShape;
    PathOperation * __weak _currentPathOperation;
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

        _shapeArray = [NSMutableArray array];
        _undoArray = [NSMutableArray array];
        _redoArray = [NSMutableArray array];

        self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"transparent-checkerboard.png"]];
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
            [weakSelf pinch:sender state:state location:location];
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
    }
    else{
        op.locationType = LocationTypeRelativeToFirst;
        CGPoint firstPoint = [_currentShape absolutePointForIndex:0];
        op.location = CGPointMake(location.x - firstPoint.x, location.y - firstPoint.y);
        op.controlPoint1 = CGPointMake(controlPoint.x - firstPoint.x, controlPoint.y - firstPoint.y);

        op.operationType = operationType;

        if(pointIsNearPoint(location, [_currentShape.pathOperations[0] location])){
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
        _currentShape = nil;
        for(DrawShape *shape in _shapeArray){
            if(pointIsNearPoint([shape.pathOperations[0] location], location)){
                _currentShape = shape;
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
    [self drawImage];
}

-(void)pan:(UIGestureRecognizer *)sender state:(UIGestureRecognizerState)state location:(CGPoint)location{
    static CGPoint prevAbsolutePoint;
    CGFloat scale = self.frame.size.width / _bottomImageView.frame.size.width;
    location = CGPointMake(location.x * scale, location.y * scale);
    if(_mode == DrawModeSelect){
        static CGPoint locationToRestore;
        if(state == UIGestureRecognizerStateBegan){
            _currentPathOperation = nil;
            for(PathOperation *op in _currentShape.pathOperations){
                if(pointIsNearPoint([_currentShape absolutePointForOperation:op], location)){
                    _currentPathOperation = op;
                }
            }
            if (_currentPathOperation){
                locationToRestore = _currentPathOperation.location;
            }
        }
        else{
            if(_currentPathOperation){
                if(_currentPathOperation.locationType == LocationTypeAbsolute){
                    _currentPathOperation.location = location;
                }
                else{
                    _currentPathOperation.location = CGPointMake(_currentPathOperation.location.x + location.x - prevAbsolutePoint.x, _currentPathOperation.location.y + location.y - prevAbsolutePoint.y);
                }

                if(state == UIGestureRecognizerStateEnded){
                    CGPoint l = locationToRestore;
                    CGPoint newLocation = _currentPathOperation.location;
                    PathOperation *op = _currentPathOperation;
                    UndoItem *undo = [[UndoItem alloc]init];
                    undo.undoBlock = ^{
                        op.location = l;
                    };
                    undo.redoBlock = ^{
                        op.location = newLocation;
                    };
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
            [self appendOperationToCurrentShape:op undoable:NO];
        }
        else{
            if(!CGPointEqualToPoint(prevAbsolutePoint, location)){
                PathOperation *op = [[PathOperation alloc]init];
                op.operationType = PathOperationLineTo;
                op.locationType = LocationTypeRelativeToFirst;
                CGPoint firstPoint = [_currentShape.pathOperations[0] location];
                op.location = CGPointMake(location.x - firstPoint.x, location.y - firstPoint.y);
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
            CGPoint firstLocation = [_currentShape.pathOperations[0] location];
            op.location = CGPointMake(location.x - firstLocation.x, location.y - firstLocation.y);
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
    else if(_mode == DrawModeArc){
        if(state == UIGestureRecognizerStateBegan){
            [self setupCurrentShape];

            PathOperation *op = [[PathOperation alloc]init];
            op.operationType = PathOperationArc;
            op.location = location;
            op.controlPoint1 = CGPointMake(0, 0);
            [self appendOperationToCurrentShape:op undoable:NO];
        }
        else{
            PathOperation *op = _currentShape.pathOperations.lastObject;
            op.controlPoint1 = CGPointMake(distanceBetweenPoints(op.location, location), 0);
        }
    }
    else if (_mode == DrawModeRect){
        if(state == UIGestureRecognizerStateBegan){
            [self setupCurrentShape];

            PathOperation *op = [[PathOperation alloc]init];
            op.operationType = PathOperationRect;
            op.location = location;
            op.controlPoint1 = CGPointZero;
            [self appendOperationToCurrentShape:op undoable:NO];
        }
        else{
            PathOperation *op = _currentShape.pathOperations.lastObject;
            op.controlPoint1 = CGPointMake(location.x - op.location.x, location.y - op.location.y);
        }
    }
    else if(_mode == DrawModeEllipse){
        if(state == UIGestureRecognizerStateBegan){
            [self setupCurrentShape];

            PathOperation *op = [[PathOperation alloc] init];
            op.operationType = PathOperationEllipse;
            op.location = location;
            op.controlPoint1 = CGPointZero;

            [self appendOperationToCurrentShape:op undoable:NO];
        }
        else{
            PathOperation *op = _currentShape.pathOperations.lastObject;
            op.controlPoint1 = CGPointMake(location.x - op.location.x, location.y - op.location.y);
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
    int currentShapeIndex = _shapeArray.count - 1;
    if(_currentShape != nil){
        int indexOfCurrent = [_shapeArray indexOfObject:_currentShape];
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
            [self drawShape:_shapeArray[index]];
        }
        _bottomDrawShouldStartFromIndex = currentShapeIndex;

        _bottomImageView.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }

    if(_bottomDrawShouldStartFromIndex >= 0 && _bottomDrawShouldStartFromIndex < _shapeArray.count){
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0f);
        [self drawShape:_shapeArray[_bottomDrawShouldStartFromIndex]];

        if(_mode == DrawModeSelect){
            [[UIColor blueColor] setStroke];
            for(PathOperation *op in _currentShape.operationsWithAbsolutePoint){
                [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(op.location.x - 2.5, op.location.y - 2.5, 5, 5)] stroke];
                if(op.operationType == PathOperationQuadCurveTo){
                    [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(op.controlPoint1.x - 2.5, op.controlPoint1.y - 2.5, 5, 5)] stroke];

                    UIBezierPath *path = [UIBezierPath bezierPath];
                    [path moveToPoint:op.location] ;
                    [path addLineToPoint:op.controlPoint1];
                    [path stroke];
                }
            }

            [[UIColor colorWithRed:52.f/255.f green:152.f/255.f blue:219.f/255.f alpha:0.7f] setFill];
            for (DrawShape *shape in _shapeArray){
                PathOperation *op = shape.pathOperations[0];
                [[UIBezierPath bezierPathWithArcCenter:op.location radius:10 startAngle:0 endAngle:M_PI*2 clockwise:YES] fill];
            }
        }
        _middleImageView.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }

    if(currentShapeIndex == _shapeArray.count - 1){
        _topImageView.image = nil;
    }
    else{
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0f);
        [[UIColor clearColor] setFill];
        [[UIBezierPath bezierPathWithRect:self.bounds] fill];

        for(int index = currentShapeIndex + 1; index < _shapeArray.count; ++index){
            [self drawShape:_shapeArray[index]];
        }
        _topImageView.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
}

-(void)drawShape:(DrawShape*)shape{
    [shape generatePath];
    UIBezierPath *path = shape.path;
    CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), shape.antialiasing);
    if(shape.antialiasing){
        CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), kCGInterpolationHigh);
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
            [path fill];
        }
    }
}

-(void)setupCurrentShape{
    DrawShape *shape = [[DrawShape alloc]init];
    shape.lineWidth = _lineWidth;
    shape.antialiasing = _antialiasing;
    shape.fill = _fill;
    shape.stroke = _stroke;
    shape.fillColor = _fillColor;
    shape.strokeColor = _strokeColor;

    [_shapeArray addObject:shape];
    int index = _shapeArray.count - 1;
    UndoItem *undo = [[UndoItem alloc]init];
    undo.undoBlock = ^{
        [_shapeArray removeObject:shape];
    };
    undo.redoBlock = ^{
        [_shapeArray insertObject:shape atIndex:index];
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
    [_shapeArray removeAllObjects];
    [_undoArray removeAllObjects];
    [_redoArray removeAllObjects];
    _bottomImageView.image = nil;
    _middleImageView.image = nil;
    _currentShape = nil;
    _bottomDrawShouldStartFromIndex = 0;
}

-(void)setMode:(DrawMode)mode {
    _currentShape = nil;
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

-(void)removeSelected{
    if(_mode == DrawModeSelect){
        if(_currentShape){
            DrawShape *shape = _currentShape;
            int index = [_shapeArray indexOfObject:shape];
            [_shapeArray removeObjectAtIndex:index];

            typeof(self) __weak weakSelf = self;
            UndoItem *undo = [[UndoItem alloc]init];
            undo.undoBlock = ^{
                typeof(weakSelf) __strong strongSelf = weakSelf;
                [strongSelf->_shapeArray insertObject:shape atIndex:index];
            };
            undo.redoBlock = ^{
                typeof(weakSelf) __strong strongSelf = weakSelf;
                [strongSelf->_shapeArray removeObject:shape];
            };
            [self addUndoItem:undo];

            [self refresh];

            _currentShape = nil;
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