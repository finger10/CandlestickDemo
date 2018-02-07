//
//  HKKLineDataModel.h
//  HKeKlineDemo
//
//  Created by caihongguang on 2018/1/17.
//  Copyright © 2018年 caihongguang. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MY_Candle_Model.h"
@interface HKKLineDataModel :NSObject

@property (nonatomic, retain) NSNumber *closePrice;
@property (nonatomic, retain) NSNumber *openPrice;
@property (nonatomic, retain) NSNumber *highPrice;
@property (nonatomic, retain) NSNumber *lowPrice;

/// 蜡烛图
@property (nonatomic, retain) MY_Candle_Model *Candle;

@end
