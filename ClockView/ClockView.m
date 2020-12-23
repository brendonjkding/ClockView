//
//  ClockView.m
//  ClockView
//
//  Created by changho on 2019/11/30.
//  Copyright © 2019 changho. All rights reserved.
//

//屏幕尺寸
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

#define kScreenWidthCoefficient kScreenWidth * 3 /  720
#define kScreenHeightCoefficient kScreenHeight * 3 / 1280

#import "ClockView.h"
#import <CoreText/CoreText.h>

@interface ClockView ()

//秒针
@property(nonatomic, retain) CAShapeLayer *secondhandLayer;
//分针
@property(nonatomic, retain) CAShapeLayer *minutehandLayer;
//时针
@property(nonatomic, retain) CAShapeLayer *hourhandLayer;
//中心点
@property(nonatomic,retain) CAShapeLayer *dotsLayer;
//最外圈圆的半径
@property(nonatomic,assign) CGFloat outerRingArcRadius;
//对应弦长
@property(nonatomic,assign) CGFloat perChordLength;

@end

@implementation ClockView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor blackColor];
    self.outerRingArcRadius = MIN(self.bounds.size.width, self.bounds.size.height) / 2 - 7 * kScreenHeightCoefficient;
    
    [self drawClock];
    [self setHourhandLayer];
    [self setMinutehandLayer];
    [self setSecondhandLayer];
    
//    [self setTransform];
    [self fire];
}
- (UIBezierPath *)getStringLayer:(NSString *)str{
    //创建可变path
    CGMutablePathRef letters = CGPathCreateMutable();
    //设置字体
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           [UIFont systemFontOfSize:25], kCTFontAttributeName,
                           nil];
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:str
                                                                     attributes:attrs];
    //根据字符串创建 line
    CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)attrString);
    //获取每一个字符作为数组
    CFArrayRef runArray = CTLineGetGlyphRuns(line);

    // 遍历字符数组
    for (CFIndex runIndex = 0; runIndex < CFArrayGetCount(runArray); runIndex++)
    {
        // Get FONT for this run
        CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(runArray, runIndex);
        CTFontRef runFont = CFDictionaryGetValue(CTRunGetAttributes(run), kCTFontAttributeName);

        // for each GLYPH in run
        for (CFIndex runGlyphIndex = 0; runGlyphIndex < CTRunGetGlyphCount(run); runGlyphIndex++)
        {
            // get Glyph & Glyph-data
            CFRange thisGlyphRange = CFRangeMake(runGlyphIndex, 1);
            CGGlyph glyph;
            CGPoint position;
            CTRunGetGlyphs(run, thisGlyphRange, &glyph);
            CTRunGetPositions(run, thisGlyphRange, &position);

            // Get PATH of outline
            {
                CGPathRef letter = CTFontCreatePathForGlyph(runFont, glyph, NULL);
                CGAffineTransform t = CGAffineTransformMakeTranslation(position.x, position.y);
                CGPathAddPath(letters, &t, letter);
                CGPathRelease(letter);
            }
        }
    }
    CFRelease(line);
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointZero];
    [path appendPath:[UIBezierPath bezierPathWithCGPath:letters]];
    CGPathRelease(letters);
    return path;
}
- (void)drawClock {
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.fillColor = [UIColor greenColor].CGColor;
    shapeLayer.strokeColor = [UIColor greenColor].CGColor;
    
    CGFloat perAngle = M_PI * 2 / 60;
    CGPoint newCenter = CGPointMake(self.center.x - self.frame.origin.x, self.center.y - self.frame.origin.y);
    
    //画表盘中心点
    self.dotsLayer = [self getDotsShapeLayer];
    [self.layer addSublayer:self.dotsLayer];
    
    CALayer *_hourLayer=[CALayer layer];
    CALayer *_hourLayerMask=[CALayer layer];
    _hourLayer.mask=_hourLayerMask;

    CALayer *_secondLayer=[CALayer layer];
    CALayer *_secondLayerMask=[CALayer layer];
    _secondLayer.mask=_secondLayerMask;

    [_hourLayer setFrame:self.layer.bounds];
    [_hourLayerMask setFrame:self.layer.bounds];
    [_secondLayer setFrame:self.layer.bounds];
    [_secondLayerMask setFrame:self.layer.bounds];

    [self.layer addSublayer:_hourLayer];
    [self.layer addSublayer:_secondLayer];
    [_hourLayer setBackgroundColor:[UIColor greenColor].CGColor];
    [_secondLayer setBackgroundColor:[UIColor yellowColor].CGColor];

    double duration=24.;
    NSMutableArray<NSNumber*> *keyTimes=[NSMutableArray new];
    NSMutableArray *colors = [NSMutableArray array];

    // hour/dots 
    for (int deg = 0; deg <= 360; deg += 5) {
        int degg = (deg+0)%361;
        if(degg==200) {
            deg+=80;
            continue;
        }
        // NSLog(@"%d",degg);
        UIColor *color;
        color = [UIColor colorWithHue:1.0 * degg / 360.0
                           saturation:1.0
                           brightness:1.0
                                alpha:1.0];
        [colors addObject:(id)[color CGColor]];

        if(deg>210) [keyTimes addObject:@((deg-60)/279.)];
        else [keyTimes addObject:@(deg/279.)];
    }


    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"backgroundColor"];
    animation.keyTimes = keyTimes;
    animation.values = colors;
    animation.duration = duration;
    animation.calculationMode = kCAAnimationLinear;
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    animation.repeatCount = DBL_MAX;
    [_hourLayer addAnimation:animation forKey:@"hourColor"];
    [_dotsLayer addAnimation:animation forKey:@"dotsColor"];

    // second
    colors = [NSMutableArray array];

    for (int deg = 0; deg <= 360; deg += 5) {
        int degg = (deg+140)%360;
        if(degg==200) {
            deg+=80;
            continue;
        }
        // NSLog(@"%d",degg);
        UIColor *color;
        color = [UIColor colorWithHue:1.0 * degg / 360.0
                           saturation:1.0
                           brightness:1.0
                                alpha:1.0];
        [colors addObject:(id)[color CGColor]];
    }

    animation = [CAKeyframeAnimation animationWithKeyPath:@"backgroundColor"];
    animation.keyTimes = keyTimes;
    animation.values = colors;
    animation.duration = duration;
    animation.calculationMode = kCAAnimationLinear;
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    animation.repeatCount = DBL_MAX;
    [_secondLayer addAnimation:animation forKey:@"secondColor"];



    //画表盘边缘刻度
    for (int i = 0; i < 60; i++) {
        CGFloat startAngle = perAngle * i;
        CGFloat endAngle = startAngle + perAngle / 5;
        
        UIBezierPath *bezierPath = [UIBezierPath bezierPathWithArcCenter:newCenter radius:self.outerRingArcRadius startAngle:startAngle endAngle:endAngle clockwise:YES];
        CAShapeLayer *perLayer = [CAShapeLayer layer];
        
        if (i % 5 == 0) {
            perLayer.strokeColor = [UIColor greenColor].CGColor;
            perLayer.lineWidth   = 9 * kScreenWidthCoefficient;
            self.perChordLength   = 2 * self.outerRingArcRadius * sin(perAngle / 5 / 2); // 对应弦长 公式=为2rsin（a/2)
        } else {
            perLayer.strokeColor = [UIColor yellowColor].CGColor;
            perLayer.lineWidth   = 5 * kScreenWidthCoefficient;
        }
        
        perLayer.path = bezierPath.CGPath;
        
        //添加刻度说明
        if (i % 5 == 0){
            NSString *tickText = [NSString stringWithFormat:@"%d", (i / 5)];
            if (i == 0) {
                tickText = @"12";
            }
            
            CGFloat textAngel = (M_PI_2 - startAngle) * (180 / M_PI);//记得在这里换算成角度
            
            CGPoint point = [self calcCircleCoordinateWithCenter:newCenter andWithAngle:textAngel andWithRadius:self.outerRingArcRadius - 16 * kScreenHeightCoefficient];
//            UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(point.x, point.y, 25 * kScreenWidthCoefficient, 19 * kScreenWidthCoefficient)];
//            label.center = point;
//            label.text = tickText;
//            label.textColor = [UIColor greenColor];
//            label.font = [UIFont systemFontOfSize:25];
//            label.textAlignment = NSTextAlignmentCenter;
//            [self addSubview:label];
            

            CAShapeLayer*layer=[CAShapeLayer layer];
            layer.geometryFlipped = YES;
            [layer setFrame:CGRectMake(point.x - 25 * kScreenWidthCoefficient/2, point.y - 19 * kScreenWidthCoefficient/2, 25 * kScreenWidthCoefficient, 19 * kScreenWidthCoefficient)];
            UIBezierPath* path=[self getStringLayer:tickText];
            layer.path = path.CGPath;
            layer.bounds=CGPathGetBoundingBox(path.CGPath);

            [_hourLayerMask addSublayer:layer];


            [_hourLayerMask addSublayer:perLayer];
        }
        else{
            [_secondLayerMask addSublayer:perLayer];
        }
    }
    
    [self.layer addSublayer:shapeLayer];
}

- (void)setTransform {
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSUInteger units = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents *components = [calendar components:units fromDate:[NSDate date]];
    
    CGFloat secsAngle = (components.second / 60.0) * M_PI * 2.0;
    CGFloat minusAngle = ((components.minute + components.second / 60.0) / 60.0 ) * M_PI * 2.0;
    CGFloat hourAngle = ((components.hour + components.minute / 60.0) / 12.0) * M_PI * 2.0;
    
    self.secondhandLayer.transform = CATransform3DMakeRotation(secsAngle, 0, 0, 1);
    self.minutehandLayer.transform = CATransform3DMakeRotation(minusAngle, 0, 0, 1);
    self.hourhandLayer.transform = CATransform3DMakeRotation(hourAngle, 0, 0, 1);
}

-(void)fire{
    [self.secondhandLayer removeAllAnimations];
    [self.minutehandLayer removeAllAnimations];
    [self.hourhandLayer removeAllAnimations];

    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSUInteger units = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents *components = [calendar components:units fromDate:[NSDate date]];
    
    CGFloat secsAngle = (components.second / 60.0) * M_PI * 2.0;
    CGFloat minusAngle = ((components.minute + components.second / 60.0) / 60.0 ) * M_PI * 2.0;
    CGFloat hourAngle = ((components.hour + components.minute / 60.0) / 12.0) * M_PI * 2.0;
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    animation.duration = 60.;// 1 min = 60 sec
    animation.fromValue = @(0.+secsAngle);
    animation.toValue = @(M_PI * 2.0+secsAngle);
    animation.repeatCount= DBL_MAX;
    [self.secondhandLayer addAnimation:animation forKey:@"second"];
    
    animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    animation.duration = 60.*60.;// 1 h = 60 min
    animation.fromValue = @(0.+minusAngle);
    animation.toValue = @(M_PI * 2.0+minusAngle);
    animation.repeatCount= DBL_MAX;
    [self.minutehandLayer addAnimation:animation forKey:@"minute"];
    
    animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    animation.duration = 60.*60.*12.;// 12h
    animation.fromValue = @(0.+hourAngle);
    animation.toValue = @(M_PI * 2.0+hourAngle);
    animation.repeatCount= DBL_MAX;
    [self.hourhandLayer addAnimation:animation forKey:@"hour"];
    
}
#pragma mark - 设置指针

- (void)setSecondhandLayer {
    NSArray *poinsArray = [NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(self.perChordLength / 2, 2 * kScreenHeightCoefficient)],
                           [NSValue valueWithCGPoint:CGPointMake(-1 * kScreenWidthCoefficient, self.outerRingArcRadius * 0.95)],
                           [NSValue valueWithCGPoint:CGPointMake(0, self.outerRingArcRadius * 1.1)],
                           [NSValue valueWithCGPoint:CGPointMake(1 * kScreenWidthCoefficient, self.outerRingArcRadius * 0.95)], nil];
    
    self.secondhandLayer = [self getShapeLayerWithStartPoints:poinsArray anchorYRate:0.9 fillColor:[UIColor redColor]];
    
    [self.layer insertSublayer:self.secondhandLayer below:self.dotsLayer];
}

- (void)setMinutehandLayer {
    NSArray *poinsArray = [NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(self.perChordLength / 2, 2 * kScreenHeightCoefficient)],
                           [NSValue valueWithCGPoint:CGPointMake(-2 * kScreenWidthCoefficient, self.outerRingArcRadius * 0.7)],
                           [NSValue valueWithCGPoint:CGPointMake(0, self.outerRingArcRadius * 0.8)],
                           [NSValue valueWithCGPoint:CGPointMake(2 * kScreenWidthCoefficient, self.outerRingArcRadius * 0.7)], nil];
    self.minutehandLayer = [self getShapeLayerWithStartPoints:poinsArray anchorYRate:0.9 fillColor:[UIColor blueColor]];
    
    [self.layer insertSublayer:self.minutehandLayer below:self.dotsLayer];
}

- (void)setHourhandLayer {
    NSArray *poinsArray = [NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(self.perChordLength / 2, 0)],
                           [NSValue valueWithCGPoint:CGPointMake(-3 * kScreenWidthCoefficient, self.outerRingArcRadius * 0.45)],
                           [NSValue valueWithCGPoint:CGPointMake(0, self.outerRingArcRadius * 0.5)],
                           [NSValue valueWithCGPoint:CGPointMake(3 * kScreenWidthCoefficient, self.outerRingArcRadius * 0.45)], nil];
    self.hourhandLayer = [self getShapeLayerWithStartPoints:poinsArray anchorYRate:0.9
                                                  fillColor:[UIColor whiteColor]];
    
    [self.layer insertSublayer:self.hourhandLayer below:self.dotsLayer];
}

#pragma mark 计算圆圈上点的坐标

- (CGPoint)calcCircleCoordinateWithCenter:(CGPoint) center  andWithAngle: (CGFloat) angle andWithRadius: (CGFloat) radius {
    CGFloat x = center.x + radius * cosf(angle * M_PI / 180);
    CGFloat y = center.y - radius * sinf(angle * M_PI / 180);
    return CGPointMake(x, y);
}

- (CAShapeLayer *)getDotsShapeLayer {
    CGFloat width = 2 * kScreenWidthCoefficient;
    CGRect frame = CGRectMake(self.bounds.size.width / 2 - width / 2, self.bounds.size.height / 2 , width, width);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect: frame byRoundingCorners:UIRectCornerAllCorners cornerRadii:frame.size];
    
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    
    shapeLayer.frame = frame;
    
    shapeLayer.path = path.CGPath;
    shapeLayer.cornerRadius = width / 2;
    shapeLayer.backgroundColor = [UIColor grayColor].CGColor;
    shapeLayer.anchorPoint = CGPointMake(0.5, 0.9);
    
    return shapeLayer;
}

- (CAShapeLayer *)getShapeLayerWithStartPoints:(NSArray <NSValue *> *)pointsArray anchorYRate:(CGFloat)anchorYRate fillColor:(UIColor *)fillColor {
    
    UIBezierPath *secondHandPath = [UIBezierPath bezierPath];
    for (NSInteger i = 0; i < pointsArray.count; i++) {
        CGPoint point = [[pointsArray objectAtIndex:i] CGPointValue];
        if (i == 0) {
            [secondHandPath moveToPoint:point];
        } else {
            [secondHandPath addLineToPoint:point];
        }
    }
    [secondHandPath closePath];
    
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = secondHandPath.CGPath;
    [shapeLayer setFillColor:fillColor.CGColor];
    
    /*
     anchorPoint和position共同决定了frame,
     frame.origin.x = position.x - anchorPoint.x * bounds.size.width;
     frame.origin.y = position.y - anchorPoint.y * bounds.size.height;
     */
    
    shapeLayer.anchorPoint = CGPointMake(0.5, anchorYRate);
    shapeLayer.position = CGPointMake(self.bounds.size.width * 0.5, self.bounds.size.height * 0.5);
    
    CGFloat maxHeight = [[pointsArray objectAtIndex:2] CGPointValue].y - [[pointsArray objectAtIndex:0] CGPointValue].y;
    [shapeLayer setBounds:CGRectMake(0, 0, 0, maxHeight)];
    
    return shapeLayer;
}


@end
