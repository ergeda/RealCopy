
#import "RadarView.h"

#define scanBorderW 0.7 * self.frame.size.width
#define scanBorderX 0.5 * (1 - 0.7) * self.frame.size.width
#define scanBorderY 0.5 * (self.frame.size.height - scanBorderW)

@interface RadarView ()

@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic, strong) UIColor *cornerColor;
@property (nonatomic, assign) CGFloat cornerWidth;
@property (nonatomic, assign) CGFloat backgroundAlpha;

@end

@implementation RadarView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        
        [self initialization];
    }
    return self;
}

- (void)initialization {
    _borderColor = [UIColor whiteColor];
    _cornerColor = [UIColor colorWithRed:85/255.0f green:183/255.0 blue:55/255.0 alpha:1.0];
    _cornerWidth = 2.0;
    _backgroundAlpha = 0.5;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    /// frame
    CGFloat borderW = scanBorderW;
    CGFloat borderH = borderW;
    CGFloat borderX = scanBorderX;
    CGFloat borderY = scanBorderY;
    CGFloat borderLineW = 0.2;

    /// 空白区域设置
    [[[UIColor blackColor] colorWithAlphaComponent:self.backgroundAlpha] setFill];
    UIRectFill(rect);
    // 获取上下文，并设置混合模式 -> kCGBlendModeDestinationOut
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetBlendMode(context, kCGBlendModeDestinationOut);
    // 设置空白区
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRect:CGRectMake(borderX + 0.5 * borderLineW, borderY + 0.5 *borderLineW, borderW - borderLineW, borderH - borderLineW)];
    [bezierPath fill];
    // 执行混合模式
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    
    /// 边框设置
    UIBezierPath *borderPath = [UIBezierPath bezierPathWithRect:CGRectMake(borderX, borderY, borderW, borderH)];
    borderPath.lineCapStyle = kCGLineCapButt;
    borderPath.lineWidth = borderLineW;
    [self.borderColor set];
    [borderPath stroke];
    
    CGFloat cornerLenght = 20;
    /// 左上角小图标
    UIBezierPath *leftTopPath = [UIBezierPath bezierPath];
    leftTopPath.lineWidth = self.cornerWidth;
    [self.cornerColor set];
    [leftTopPath moveToPoint:CGPointMake(borderX, borderY + cornerLenght)];
    [leftTopPath addLineToPoint:CGPointMake(borderX, borderY)];
    [leftTopPath addLineToPoint:CGPointMake(borderX + cornerLenght, borderY)];
    [leftTopPath stroke];
    
    /// 左下角小图标
    UIBezierPath *leftBottomPath = [UIBezierPath bezierPath];
    leftBottomPath.lineWidth = self.cornerWidth;
    [self.cornerColor set];
    [leftBottomPath moveToPoint:CGPointMake(borderX + cornerLenght, borderY + borderH)];
    [leftBottomPath addLineToPoint:CGPointMake(borderX, borderY + borderH)];
    [leftBottomPath addLineToPoint:CGPointMake(borderX, borderY + borderH - cornerLenght)];
    [leftBottomPath stroke];
    
    /// 右上角小图标
    UIBezierPath *rightTopPath = [UIBezierPath bezierPath];
    rightTopPath.lineWidth = self.cornerWidth;
    [self.cornerColor set];
    [rightTopPath moveToPoint:CGPointMake(borderX + borderW - cornerLenght, borderY)];
    [rightTopPath addLineToPoint:CGPointMake(borderX + borderW, borderY)];
    [rightTopPath addLineToPoint:CGPointMake(borderX + borderW, borderY + cornerLenght)];
    [rightTopPath stroke];
    
    /// 右下角小图标
    UIBezierPath *rightBottomPath = [UIBezierPath bezierPath];
    rightBottomPath.lineWidth = self.cornerWidth;
    [self.cornerColor set];
    [rightBottomPath moveToPoint:CGPointMake(borderX + borderW, borderY + borderH - cornerLenght)];
    [rightBottomPath addLineToPoint:CGPointMake(borderX + borderW, borderY + borderH)];
    [rightBottomPath addLineToPoint:CGPointMake(borderX + borderW - cornerLenght, borderY + borderH)];
    [rightBottomPath stroke];
}

@end

