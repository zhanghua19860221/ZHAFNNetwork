//
//  ZHNetwork+Network.h
//  ZHAFNNetwork_Example
//
//  Created by Breeze on 2022/6/23.
//  Copyright © 2022 zhanghua. All rights reserved.
//

#import "ZHNetwork.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZHNetwork (Network)
/**
 * 配置网络相关请求
 */
+ (void)initNetWork;


+ (NSError *)showError:(NSError *)error task:(NSURLSessionDataTask *)task;

/**
 * 设置请求头
 */
+ (void)setDefaultHeaderWithUser:(NSDictionary *)dic;
@end

NS_ASSUME_NONNULL_END
