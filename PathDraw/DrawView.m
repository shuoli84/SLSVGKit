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
    int _cacheIndex;
    UIImageView* _contentImageView;
    UIImageView* _editingTopImageView;
    UIImageView* _selectImageView;
}

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self){
        _fill = NO;
        _stroke = YES;

        _shapeArray = [NSMutableArray array];
        _undoArray = [NSMutableArray array];
        _redoArray = [NSMutableArray array];

        self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"transparent-checkerboard.png"]];
        self.clipsToBounds = YES;
        _contentImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _contentImageView.userInteractionEnabled = YES;
        _contentImageView.contentMode = UIViewContentModeScaleAspectFill;
        _contentImageView.layer.magnificationFilter = kCAFilterNearest;
        [self addSubview:_contentImageView];

        _editingTopImageView = [[UIImageView alloc] init];
        _editingTopImageView.userInteractionEnabled = NO;
        _editingTopImageView.contentMode = UIViewContentModeScaleAspectFill;
        _editingTopImageView.layer.magnificationFilter = kCAFilterNearest;
        [self addSubview:_editingTopImageView];

        _selectImageView = [[UIImageView alloc] init];

        _selectImageView.userInteractionEnabled = NO;
        _selectImageView.contentMode = UIViewContentModeScaleAspectFill;
        _selectImageView.layer.magnificationFilter = kCAFilterNearest;
        [self addSubview:_selectImageView];

        typeof(self) __weak weakSelf = self;
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
            [weakSelf tap:sender state:state location:location];
        }];
        tapGestureRecognizer.numberOfTouchesRequired = 1;
        [_contentImageView addGestureRecognizer:tapGestureRecognizer];

        UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
            [weakSelf pan:sender state:state location:location];
        }];
        [panGestureRecognizer setMinimumNumberOfTouches:1];
        [panGestureRecognizer setMaximumNumberOfTouches:1];
        [_contentImageView addGestureRecognizer:panGestureRecognizer];

        UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
            [weakSelf pinch:sender state:state location:location];
        }];
        [self addGestureRecognizer:pinchGestureRecognizer];
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    if(CGSizeEqualToSize(CGSizeZero, _contentImageView.frame.size)){
        _contentImageView.frame = self.bounds;
    }
    if(CGSizeEqualToSize(CGSizeZero, _editingTopImageView.frame.size)){
        _editingTopImageView.frame = self.bounds;
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
    CGFloat scale = self.frame.size.width / _contentImageView.frame.size.width;
    location = CGPointMake(location.x * scale, location.y * scale);
    location = CGPointMake(floorf(location.x), floorf(location.y));

    if(_mode == DrawModeSelect){
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
    CGFloat scale = self.frame.size.width / _contentImageView.frame.size.width;
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
            PathOperation *op = [[PathOperation alloc]init];
            op.operationType = PathOperationLineTo;
            op.locationType = LocationTypeRelativeToFirst;
            CGPoint firstPoint = [_currentShape.pathOperations[0] location];
            op.location = CGPointMake(location.x - firstPoint.x, location.y - firstPoint.y);
            [self appendOperationToCurrentShape:op undoable:NO];
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

    _contentImageView.bounds = CGRectMake(0, 0, MIN(_contentImageView.bounds.size.width * scale, maxSize.width), MIN(_contentImageView.bounds.size.height * scale, maxSize.height));

    BOOL maximized = _contentImageView.bounds.size.width == maxSize.width;

    if(!maximized){
        CGPoint prevCenter = _contentImageView.center;
        _contentImageView.center = CGPointMake(prevCenter.x - (location.x - prevCenter.x) * (scale -1), prevCenter.y - (location.y-prevCenter.y)*(scale-1));
    }

    _contentImageView.center = CGPointMake(_contentImageView.center.x + (location.x - prevLocation.x), _contentImageView.center.y + (location.y - prevLocation.y));

    _editingTopImageView.frame = _contentImageView.frame;

    pinchGestureRecognizer.scale = 1.0;

    prevLocation = location;
}

-(void)drawImage{
    _cacheIndex = 0; //always redraw everything to make things easier. Will tune this later
    _contentImageView.image = nil;
    if(_cacheIndex < _shapeArray.count){
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0f);
        if (_contentImageView.image){
            [_contentImageView.image drawAtPoint:CGPointZero];
        }
        else{
            [[UIColor clearColor] setFill];
            [[UIBezierPath bezierPathWithRect:self.bounds] fill];
        }

        for(int index = _cacheIndex; index < _shapeArray.count; ++index){
            [self drawShape:_shapeArray[index]];
        }
        _cacheIndex = _shapeArray.count;
        _contentImageView.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }

    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0f);
    // [self drawShape:_currentShape];

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
    _editingTopImageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

-(void)drawShape:(DrawShape*)shape{
    [shape generatePath];
    UIBezierPath *path = shape.path;
    CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), shape.antialiasing);
    if (shape.stroke){
        [shape.strokeColor setStroke];
        path.lineWidth = shape.lineWidth;
        path.lineCapStyle = kCGLineCapRound;
        [path stroke];
    }

    if (shape.fill){
        PathOperation *op = shape.pathOperations.lastObject;
        if(op.operationType == PathOperationClose || op.operationType == PathOperationRect || op.operationType == PathOperationArc){
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
    _contentImageView.image = nil;
    _editingTopImageView.image = nil;
    _currentShape = nil;
    _cacheIndex = 0;
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
    _cacheIndex = 0;
    _contentImageView.image = nil;
    _editingTopImageView.image = nil;

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
        }
    }
}

-(void)addUndoItem:(UndoItem*)undoItem{
    [_undoArray addObject:undoItem];
    [_redoArray removeAllObjects];
}
@end