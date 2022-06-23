//
//  ZHViewController.m
//  ZHAFNNetwork
//
//  Created by zhanghua on 06/23/2022.
//  Copyright (c) 2022 zhanghua. All rights reserved.
//

#import "ZHViewController.h"
#import "ZHNetwork+Network.h"

@interface ZHViewController ()

@end

@implementation ZHViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    //获取当前网络状态
    [ZHNetwork getNetworkStatusWithBlock:^(ZHNetworkStatusType status) {
          
        NSLog(@"status --  %lu" ,(unsigned long)status);
    }];
    
    //初始化网络配置
    [ZHNetwork initNetWork];
    
    //下面介绍两种常用的 请求方式
    
    //GET网络请求
    [ZHNetwork GETWithURL:@"url" parameters:@{} cachePolicy:0 callback:^(id  _Nonnull responseObject, NSError * _Nonnull error, BOOL isFromCache) {

    }];
    
    //POST网络请求
    [ZHNetwork POSTWithURL:@"url" parameters:@{} callback:^(id  _Nullable responseObject, NSError * _Nullable error, BOOL isFromCache) {
            
    }];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
