//
//  ZHNetwork+Network.m
//  ZHAFNNetwork_Example
//
//  Created by Breeze on 2022/6/23.
//  Copyright © 2022 zhanghua. All rights reserved.
//

#import "ZHNetwork+Network.h"

@implementation ZHNetwork (Network)
+ (void)initNetWork {
    //设置请求头
    [self setDefaultHeaderWithUser:@{}];

    //设置请求超时时间
    [self setRequestTimeoutInterval:60];

    //错误统一处理
    [self setErrorReduceBlock:^NSError *(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {

       return [self showError:error task:task];
    }];
    
    //返回结果统一处理
    [self setResponseReduceBlock:^id(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {

        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dic = responseObject;
            NSString *code = dic[@"code"];
            if (code) {
                //错误统一处理
                if (code.integerValue != 10000) {
                    
                    if (code.integerValue == 50000 && [task.currentRequest.URL.absoluteString containsString:@"checkout/select_shipping_method"]) {
                        //此处添加处理业务代码
                        return nil;
                    }
                    else{
                        //此处添加处理业务代码
                        return nil;
                    }

                }else{
                    // data 返回 指定数据
                    if (dic[@"data"] && ![dic[@"data"] isKindOfClass:[NSNull class]]) {
                        return dic[@"data"];
                    }else{
                        
                        return nil;
                    }
                }
                
            }else{
                return responseObject;
            }
        }else{
            return responseObject;
        }

    }
    ];
}


+ (NSError *)showError:(NSError *)error task:(NSURLSessionDataTask *)task{

    NSHTTPURLResponse *responses = (NSHTTPURLResponse *)task.response;
    
    if (error.code == NSURLErrorTimedOut) {
        //超时错误提示
        return error;
    } else if (error.code == NSURLErrorNotConnectedToInternet) {
        //没有可用网络错误提示
        return error;
    }
    if (responses.statusCode == 401) {
        //401错误逻辑处理
        return error;

    }else {
        //其他错误逻辑分析处理
    }
    return error;
}


+ (void)setDefaultHeaderWithUser:(NSDictionary *)dic{
    NSMutableDictionary *headDic = [NSMutableDictionary dictionary];

    headDic[@"Content-Type"] = @"application/json";
    headDic[@"uid"] = @"";
    headDic[@"token"] = @"";
    headDic[@"platform"] = @"9";
    headDic[@"api_version"] = @"2.0.0";
    headDic[@"loc_id"] = @"";
    headDic[@"device_name"] = @"iOS";
    headDic[@"os_version"] = @"15.0";
    headDic[@"app_version"] = @"2.0.0";
    headDic[@"app_build"] = @"74";

    [ZHNetwork setHeadr:headDic];
    
}

@end
