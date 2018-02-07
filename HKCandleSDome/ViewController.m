//
//  ViewController.m
//  HKCandleSDome
//
//  Created by caihongguang on 2018/1/17.
//  Copyright © 2018年 caihongguang. All rights reserved.
//

#import "ViewController.h"
#import "HKKLineDataModel.h"
@interface ViewController ()

@property (nonatomic,strong)NSMutableArray *kLineModeldataArray;
@property (nonatomic,strong)NSMutableArray *plotIndexAry;

@property (nonatomic, assign) BOOL candleIsEmpty;             //是否是空心阳线
//@property (nonatomic, assign) NSInteger lastDataCount;
@property (nonatomic, assign) NSInteger candleNum;            //展示蜡烛图数据个数
@property (nonatomic, assign) NSInteger firstNum;              //标记展示数据的第一个下标
@property (nonatomic, assign) NSInteger lastNum;               //标记展示数据的最后一个下标
@property (nonatomic, assign) CGFloat mainIndex_maxValue;      //主指标图最大值
@property (nonatomic, assign) CGFloat mainIndex_minValue;      //主指标图最小值

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //默认展示50组数据
    self.candleNum = 40;
    
    //默认为空心阳线
    self.candleIsEmpty = YES;
    
    self.kLineModeldataArray = [NSMutableArray new];
    [self setupKlineModelArr];
    
    [self drawKLine];
    
}

- (void)drawKLine
{
    //计算FirstNum和LastNum  1
    [self getFirstNumeLastNum:self.kLineModeldataArray];
    //记录mainIndexView最大值和最小值 1
    [self setMainIndexMaxValueMinValue];
    //计算高度 1
    [self setMainIndexHeightWithView:self.view];
    // 画主指标图数据（蜡烛图） 1
    [self drawMainIndexWithSubView:self.view];
    
}

/// 画蜡烛图
- (void)drawCandelViewWith:(MY_Candle_Model *)candelModel
                   subView:(UIView *)subView {
    //画高线
    CAShapeLayer *pathLayer1 = [CAShapeLayer layer];
    pathLayer1.lineCap     = kCALineCapRound;
    pathLayer1.lineJoin    = kCALineJoinBevel;
    pathLayer1.fillColor   = [UIColor clearColor].CGColor;
    UIBezierPath *path1 = [UIBezierPath bezierPath];
    [path1 setLineWidth:1.0];
    [path1 setLineCapStyle:kCGLineCapRound];
    [path1 setLineJoinStyle:kCGLineJoinRound];
    [path1 moveToPoint:CGPointMake(candelModel.width, candelModel.height)];
    [path1 addLineToPoint:CGPointMake(candelModel.width, candelModel.open < candelModel.close ? candelModel.open : candelModel.close)];
    //画低线
    CAShapeLayer *pathLayer2 = [CAShapeLayer layer];
    pathLayer2.lineCap     = kCALineCapRound;
    pathLayer2.lineJoin    = kCALineJoinBevel;
    pathLayer2.fillColor   = [UIColor clearColor].CGColor;
    UIBezierPath *path2 = [UIBezierPath bezierPath];
    [path2 setLineWidth:1.0];
    [path2 setLineCapStyle:kCGLineCapRound];
    [path2 setLineJoinStyle:kCGLineJoinRound];
    [path2 moveToPoint:CGPointMake(candelModel.width, candelModel.low)];
    [path2 addLineToPoint:CGPointMake(candelModel.width, candelModel.open > candelModel.close ? candelModel.open : candelModel.close)];
    //画蜡烛
    CAShapeLayer *pathLayer3 = [CAShapeLayer layer];
    pathLayer3.lineCap     = kCALineCapRound;
    pathLayer3.lineJoin    = kCALineJoinBevel;
    //    pathLayer3.fillColor   = [UIColor clearColor].CGColor;
    UIBezierPath *path3 = [UIBezierPath bezierPath];
    [path3 setLineWidth:1.0];
    [path3 setLineCapStyle:kCGLineCapRound];
    [path3 setLineJoinStyle:kCGLineJoinRound];
    double widths = 0.7 * (subView.frame.size.width - 5) / self
    .candleNum ;
    [path3 moveToPoint:CGPointMake(candelModel.width - widths / 2, candelModel.open < candelModel.close ? candelModel.open : candelModel.close)];
    [path3 addLineToPoint:CGPointMake(candelModel.width + widths / 2, candelModel.open < candelModel.close ? candelModel.open : candelModel.close)];
    [path3 addLineToPoint:CGPointMake(candelModel.width + widths / 2, candelModel.open > candelModel.close ? candelModel.open : candelModel.close)];
    [path3 addLineToPoint:CGPointMake(candelModel.width - widths / 2, candelModel.open > candelModel.close ? candelModel.open : candelModel.close)];
    [path3 addLineToPoint:CGPointMake(candelModel.width - widths / 2, candelModel.open < candelModel.close ? candelModel.open : candelModel.close)];
    //设置颜色
    UIColor *color;
    if (candelModel.open > candelModel.close) {
//        color = MYKLineASK_COLOR;
        color = [UIColor redColor];

    } else if (candelModel.open < candelModel.close) {
//        color = MYKLineBID_COLOR;
        color = [UIColor greenColor];

    } else {
//        color = INDEXGRAY_COLOR;
        color = [UIColor blackColor];
    }
    pathLayer1.strokeColor = color.CGColor;
    pathLayer2.strokeColor = color.CGColor;
    pathLayer3.strokeColor = color.CGColor;
    //设置空心
    if (self.candleIsEmpty == YES) {
        if (candelModel.open > candelModel.close) {  //如果是阳线
            pathLayer3.fillColor   = [UIColor whiteColor].CGColor;
        } else {          //如果是阴线
            pathLayer3.fillColor   = color.CGColor;
        }
    } else {
        pathLayer3.fillColor   = color.CGColor;
    }
    //添加view
    pathLayer1.path = path1.CGPath;
    pathLayer2.path = path2.CGPath;
    pathLayer3.path = path3.CGPath;
    [subView.layer addSublayer:pathLayer1];
    [subView.layer addSublayer:pathLayer2];
    [subView.layer addSublayer:pathLayer3];
    
}

#pragma mark - 画主指标蜡烛图
/// 画主指标蜡烛图
- (void)drawMainIndexWithSubView:(UIView *)subView {
    NSMutableArray *dataArray = self.kLineModeldataArray;
    for (NSInteger i = self.firstNum; i < self.lastNum; i++) {
        //获得数据
        HKKLineDataModel *model = dataArray[i];
        MY_Candle_Model *candleModel = model.Candle;
        [self drawCandelViewWith:candleModel subView:subView];
    }
}

/// 获得宽度
- (double)getWidthWith:(NSInteger)i
                  view:(UIView *)view{
    double width = 0;
    width = i * view.frame.size.width / self.candleNum;
    return width;
}


/// 设置蜡烛图的Height
- (void)setMainIndexHeightWithView:(UIView *)view{
    for (NSInteger i = self.firstNum; i < self.lastNum; i++) {
        //获得数据
        HKKLineDataModel *model = self.kLineModeldataArray[i];
        //设置蜡烛图的高度
        model.Candle = nil;
        model.Candle = [[MY_Candle_Model alloc] init];
        model.Candle.height = [self priceTurnToY:[model.highPrice doubleValue] maxValue:self.mainIndex_maxValue minValue:self.mainIndex_minValue viewHeight:view.frame.size.height];
        model.Candle.low = [self priceTurnToY:[model.lowPrice doubleValue] maxValue:self.mainIndex_maxValue minValue:self.mainIndex_minValue viewHeight:view.frame.size.height];
        model.Candle.open = [self priceTurnToY:[model.openPrice doubleValue] maxValue:self.mainIndex_maxValue minValue:self.mainIndex_minValue viewHeight:view.frame.size.height];
        model.Candle.close = [self priceTurnToY:[model.closePrice doubleValue] maxValue:self.mainIndex_maxValue minValue:self.mainIndex_minValue viewHeight:view.frame.size.height];
        model.Candle.width = [self getWidthWith:i view:view];
        
        
    }
};


// 计算firstNume和lastNume
- (void)getFirstNumeLastNum:(NSMutableArray *)KLineDataArray {
    self.firstNum = 0;
    self.lastNum = 40;
    
}

#pragma mark -配置数据
- (void)setupKlineModelArr
{
    for(int i =0 ; i< 90 ; i++)
    {
        HKKLineDataModel *model = [HKKLineDataModel new];
        switch (i) {
            case 0:
                model.closePrice = [NSNumber numberWithDouble:1.17365];
                model.openPrice = [NSNumber numberWithDouble:1.21348];
                model.highPrice = [NSNumber numberWithDouble:1.35384];
                model.lowPrice = [NSNumber numberWithDouble:1.07342];

                
                break;
            case 1:
                model.closePrice = [NSNumber numberWithDouble:0.18365];
                model.openPrice = [NSNumber numberWithDouble:1.18348];
                model.highPrice = [NSNumber numberWithDouble:1.38384];
                model.lowPrice = [NSNumber numberWithDouble:0.08342];
                
                break;
            case 2:
                model.closePrice = [NSNumber numberWithDouble:1.17265];
                model.openPrice = [NSNumber numberWithDouble:1.1148];
                model.highPrice = [NSNumber numberWithDouble:1.37084];
                model.lowPrice = [NSNumber numberWithDouble:1.0042];
                
                break;
            case 3:
                model.closePrice = [NSNumber numberWithDouble:1.17365];
                model.openPrice = [NSNumber numberWithDouble:0.17348];
                model.highPrice = [NSNumber numberWithDouble:2.0421];
                model.lowPrice = [NSNumber numberWithDouble:0.1525];
                
                break;
            case 4:
                model.closePrice = [NSNumber numberWithDouble:1.16533];
                model.openPrice = [NSNumber numberWithDouble:1.10214];
                model.highPrice = [NSNumber numberWithDouble:1.19532];
                model.lowPrice = [NSNumber numberWithDouble:1.02453];
                
                break;
            case 5:
                model.closePrice = [NSNumber numberWithDouble:1.14251];
                model.openPrice = [NSNumber numberWithDouble:1.17451];
                model.highPrice = [NSNumber numberWithDouble:1.21543];
                model.lowPrice = [NSNumber numberWithDouble:1.01234];
                
                break;
            case 6:
                model.closePrice = [NSNumber numberWithDouble:1.13206];
                model.openPrice = [NSNumber numberWithDouble:1.14511];
                model.highPrice = [NSNumber numberWithDouble:1.25137];
                model.lowPrice = [NSNumber numberWithDouble:1.01254];
                
                break;
            case 7:
                model.closePrice = [NSNumber numberWithDouble:1.12154];
                model.openPrice = [NSNumber numberWithDouble:1.10123];
                model.highPrice = [NSNumber numberWithDouble:1.21543];
                model.lowPrice = [NSNumber numberWithDouble:1.026523];
                
                break;
            case 8:
                model.closePrice = [NSNumber numberWithDouble:1.12016];
                model.openPrice = [NSNumber numberWithDouble:1.16543];
                model.highPrice = [NSNumber numberWithDouble:1.21534];
                model.lowPrice = [NSNumber numberWithDouble:1.03562];
                break;
            case 9:
                model.closePrice = [NSNumber numberWithDouble:2.12013];
                model.openPrice = [NSNumber numberWithDouble:1.101235];
                model.highPrice = [NSNumber numberWithDouble:2.17384];
                model.lowPrice = [NSNumber numberWithDouble:1.07342];
                break;
                
            case 10:
                model.closePrice = [NSNumber numberWithDouble:2.12130];
                model.openPrice = [NSNumber numberWithDouble:1.18659];
                model.highPrice = [NSNumber numberWithDouble:1.35103];
                model.lowPrice = [NSNumber numberWithDouble:1.12012];
                break;
            case 11:
                model.closePrice = [NSNumber numberWithDouble:1.17365];
                model.openPrice = [NSNumber numberWithDouble:1.21348];
                model.highPrice = [NSNumber numberWithDouble:1.35384];
                model.lowPrice = [NSNumber numberWithDouble:1.07342];
                
                
                break;
            case 12:
                model.closePrice = [NSNumber numberWithDouble:0.18365];
                model.openPrice = [NSNumber numberWithDouble:1.18348];
                model.highPrice = [NSNumber numberWithDouble:1.38384];
                model.lowPrice = [NSNumber numberWithDouble:0.08342];
                
                break;
            case 13:
                model.closePrice = [NSNumber numberWithDouble:1.17265];
                model.openPrice = [NSNumber numberWithDouble:1.1148];
                model.highPrice = [NSNumber numberWithDouble:1.37084];
                model.lowPrice = [NSNumber numberWithDouble:1.0042];
                
                break;
            case 14:
                model.closePrice = [NSNumber numberWithDouble:1.17365];
                model.openPrice = [NSNumber numberWithDouble:0.17348];
                model.highPrice = [NSNumber numberWithDouble:2.0421];
                model.lowPrice = [NSNumber numberWithDouble:0.1525];
                
                break;
            case 15:
                model.closePrice = [NSNumber numberWithDouble:1.16533];
                model.openPrice = [NSNumber numberWithDouble:1.10214];
                model.highPrice = [NSNumber numberWithDouble:1.19532];
                model.lowPrice = [NSNumber numberWithDouble:1.02453];
                
                break;
            case 16:
                model.closePrice = [NSNumber numberWithDouble:1.14251];
                model.openPrice = [NSNumber numberWithDouble:1.17451];
                model.highPrice = [NSNumber numberWithDouble:1.21543];
                model.lowPrice = [NSNumber numberWithDouble:1.01234];
                
                break;
            case 17:
                model.closePrice = [NSNumber numberWithDouble:1.13206];
                model.openPrice = [NSNumber numberWithDouble:1.14511];
                model.highPrice = [NSNumber numberWithDouble:1.25137];
                model.lowPrice = [NSNumber numberWithDouble:1.01254];
                
                break;
            case 18:
                model.closePrice = [NSNumber numberWithDouble:1.12154];
                model.openPrice = [NSNumber numberWithDouble:1.10123];
                model.highPrice = [NSNumber numberWithDouble:1.21543];
                model.lowPrice = [NSNumber numberWithDouble:1.026523];
                
                break;
            case 19:
                model.closePrice = [NSNumber numberWithDouble:1.12016];
                model.openPrice = [NSNumber numberWithDouble:1.16543];
                model.highPrice = [NSNumber numberWithDouble:1.21534];
                model.lowPrice = [NSNumber numberWithDouble:1.03562];
                break;
            case 20:
                model.closePrice = [NSNumber numberWithDouble:2.12013];
                model.openPrice = [NSNumber numberWithDouble:1.101235];
                model.highPrice = [NSNumber numberWithDouble:2.17384];
                model.lowPrice = [NSNumber numberWithDouble:1.07342];
                break;
                
            case 21:
                model.closePrice = [NSNumber numberWithDouble:2.12130];
                model.openPrice = [NSNumber numberWithDouble:1.18659];
                model.highPrice = [NSNumber numberWithDouble:1.35103];
                model.lowPrice = [NSNumber numberWithDouble:1.12012];
                break;
            case 22:
                model.closePrice = [NSNumber numberWithDouble:1.17265];
                model.openPrice = [NSNumber numberWithDouble:1.1148];
                model.highPrice = [NSNumber numberWithDouble:1.37084];
                model.lowPrice = [NSNumber numberWithDouble:1.0042];
                
                break;
            case 23:
                model.closePrice = [NSNumber numberWithDouble:1.17365];
                model.openPrice = [NSNumber numberWithDouble:0.17348];
                model.highPrice = [NSNumber numberWithDouble:2.0421];
                model.lowPrice = [NSNumber numberWithDouble:0.1525];
                
                break;
            case 24:
                model.closePrice = [NSNumber numberWithDouble:1.16533];
                model.openPrice = [NSNumber numberWithDouble:1.10214];
                model.highPrice = [NSNumber numberWithDouble:1.19532];
                model.lowPrice = [NSNumber numberWithDouble:1.02453];
                
                break;
            case 25:
                model.closePrice = [NSNumber numberWithDouble:1.14251];
                model.openPrice = [NSNumber numberWithDouble:1.17451];
                model.highPrice = [NSNumber numberWithDouble:1.21543];
                model.lowPrice = [NSNumber numberWithDouble:1.01234];
                
                break;
            case 26:
                model.closePrice = [NSNumber numberWithDouble:1.13206];
                model.openPrice = [NSNumber numberWithDouble:1.14511];
                model.highPrice = [NSNumber numberWithDouble:1.25137];
                model.lowPrice = [NSNumber numberWithDouble:1.01254];
                
                break;
            case 27:
                model.closePrice = [NSNumber numberWithDouble:1.12154];
                model.openPrice = [NSNumber numberWithDouble:1.10123];
                model.highPrice = [NSNumber numberWithDouble:1.21543];
                model.lowPrice = [NSNumber numberWithDouble:1.026523];
                
                break;
            case 28:
                model.closePrice = [NSNumber numberWithDouble:1.12016];
                model.openPrice = [NSNumber numberWithDouble:1.16543];
                model.highPrice = [NSNumber numberWithDouble:1.21534];
                model.lowPrice = [NSNumber numberWithDouble:1.03562];
                break;
            case 29:
                model.closePrice = [NSNumber numberWithDouble:2.12013];
                model.openPrice = [NSNumber numberWithDouble:1.101235];
                model.highPrice = [NSNumber numberWithDouble:2.17384];
                model.lowPrice = [NSNumber numberWithDouble:1.07342];
                break;
            case 30:
                model.closePrice = [NSNumber numberWithDouble:1.16533];
                model.openPrice = [NSNumber numberWithDouble:1.10214];
                model.highPrice = [NSNumber numberWithDouble:1.19532];
                model.lowPrice = [NSNumber numberWithDouble:1.02453];
                
                break;
            case 31:
                model.closePrice = [NSNumber numberWithDouble:1.14251];
                model.openPrice = [NSNumber numberWithDouble:1.17451];
                model.highPrice = [NSNumber numberWithDouble:1.21543];
                model.lowPrice = [NSNumber numberWithDouble:1.01234];
                
                break;
            case 32:
                model.closePrice = [NSNumber numberWithDouble:1.17265];
                model.openPrice = [NSNumber numberWithDouble:1.1148];
                model.highPrice = [NSNumber numberWithDouble:1.37084];
                model.lowPrice = [NSNumber numberWithDouble:1.0042];
                
                break;
            case 33:
                model.closePrice = [NSNumber numberWithDouble:1.17365];
                model.openPrice = [NSNumber numberWithDouble:0.17348];
                model.highPrice = [NSNumber numberWithDouble:2.0421];
                model.lowPrice = [NSNumber numberWithDouble:0.1525];
                
                break;
            case 34:
                model.closePrice = [NSNumber numberWithDouble:1.16533];
                model.openPrice = [NSNumber numberWithDouble:1.10214];
                model.highPrice = [NSNumber numberWithDouble:1.19532];
                model.lowPrice = [NSNumber numberWithDouble:1.02453];
                
                break;
            case 35:
                model.closePrice = [NSNumber numberWithDouble:1.14251];
                model.openPrice = [NSNumber numberWithDouble:1.17451];
                model.highPrice = [NSNumber numberWithDouble:1.21543];
                model.lowPrice = [NSNumber numberWithDouble:1.01234];
                
                break;
            case 36:
                model.closePrice = [NSNumber numberWithDouble:1.13206];
                model.openPrice = [NSNumber numberWithDouble:1.14511];
                model.highPrice = [NSNumber numberWithDouble:1.25137];
                model.lowPrice = [NSNumber numberWithDouble:1.01254];
                
                break;
            case 37:
                model.closePrice = [NSNumber numberWithDouble:1.12154];
                model.openPrice = [NSNumber numberWithDouble:1.10123];
                model.highPrice = [NSNumber numberWithDouble:1.21543];
                model.lowPrice = [NSNumber numberWithDouble:1.026523];
                
                break;
            case 38:
                model.closePrice = [NSNumber numberWithDouble:1.12016];
                model.openPrice = [NSNumber numberWithDouble:1.16543];
                model.highPrice = [NSNumber numberWithDouble:1.21534];
                model.lowPrice = [NSNumber numberWithDouble:1.03562];
                break;
            case 39:
                model.closePrice = [NSNumber numberWithDouble:2.12013];
                model.openPrice = [NSNumber numberWithDouble:1.101235];
                model.highPrice = [NSNumber numberWithDouble:2.17384];
                model.lowPrice = [NSNumber numberWithDouble:1.07342];
                break;
                
                
            default:
                break;
        }
        
        [self.kLineModeldataArray addObject:model];
    }
}


#pragma mark - 计算主指标参数


/// 设置主指标最大值和最小值
- (void)setMainIndexMaxValueMinValue {
    double maxValue = 0;
    double minValue = MAXFLOAT;
    self.mainIndex_maxValue = 0;
    self.mainIndex_minValue = MAXFLOAT;
    for (NSInteger i = self.firstNum ; i < self.lastNum ; i++) {
        HKKLineDataModel *model = self.kLineModeldataArray[i];
        maxValue = maxValue > [model.openPrice doubleValue] ? maxValue : [model.openPrice doubleValue];
        maxValue = maxValue > [model.closePrice doubleValue] ? maxValue : [model.closePrice doubleValue];
        maxValue = maxValue > [model.highPrice doubleValue] ? maxValue : [model.highPrice doubleValue];
        maxValue = maxValue > [model.lowPrice doubleValue] ? maxValue : [model.lowPrice doubleValue];
        minValue = minValue < [model.openPrice doubleValue] ? minValue : [model.openPrice doubleValue];
        minValue = minValue < [model.closePrice doubleValue] ? minValue : [model.closePrice doubleValue];
        minValue = minValue < [model.highPrice doubleValue] ? minValue : [model.highPrice doubleValue];
        minValue = minValue < [model.lowPrice doubleValue] ? minValue : [model.lowPrice doubleValue];
    }
    self.mainIndex_maxValue = maxValue;
    self.mainIndex_minValue = minValue;
};

/// 根据price转换成对应的y点
- (CGFloat)priceTurnToY:(double)price
               maxValue:(double)maxValue
               minValue:(double)minValue
             viewHeight:(double)viewHeight{
    double resule = 0;
    if ((maxValue - minValue) != 0) {
        resule = (maxValue - price) * viewHeight / (maxValue - minValue);
    } else {
        resule = viewHeight / 2;
    }
    return resule;
}

@end
