//
//  ZHHttpBaseConfig.h
//  ZHNetWork
//
//  Created by Breeze on 2022/6/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSUInteger, ZHCachePolicy){
    /**只从网络获取数据，且数据不会缓存在本地*/
    ZHCachePolicyIgnoreCache = 0,
    /**只从缓存读数据，如果缓存没有数据，返回一个空*/
    ZHCachePolicyCacheOnly = 1,
    /**先从网络获取数据，同时会在本地缓存数据*/
    ZHCachePolicyNetworkOnly = 2,
    /**先从缓存读取数据，如果没有再从网络获取*/
    ZHCachePolicyCacheElseNetwork = 3,
    /**先从网络获取数据，如果没有再从缓存获取，此处的没有可以理解为访问网络失败，再从缓存读取*/
    ZHCachePolicyNetworkElseCache = 4,
    /**先从缓存读取数据，然后再从网络获取并且缓存，在这种情况下，Block将产生两次调用*/
    ZHCachePolicyCacheThenNetwork = 5
};

/**请求方式*/
typedef NS_ENUM(NSUInteger, ZHRequestMethod){
    /**GET请求方式*/
    ZHRequestMethodGET = 0,
    /**POST请求方式*/
    ZHRequestMethodPOST,
    /**HEAD请求方式*/
    ZHRequestMethodHEAD,
    /**PUT请求方式*/
    ZHRequestMethodPUT,
    /**PATCH请求方式*/
    ZHRequestMethodPATCH,
    /**DELETE请求方式*/
    ZHRequestMethodDELETE
};

typedef NS_ENUM(NSUInteger, ZHNetworkStatusType){
    /**未知网络*/
    ZHNetworkStatusUnknown,
    /**无网路*/
    ZHNetworkStatusNotReachable,
    /**手机网络*/
    ZHNetworkStatusReachableWWAN,
    /**WiFi网络*/
    ZHNetworkStatusReachableWiFi
};

typedef NS_ENUM(NSUInteger, ZHRequestSerializer){
    /**设置请求数据为JSON格式*/
    ZHRequestSerializerJSON,
    /**设置请求数据为二进制格式*/
    ZHRequestSerializerHTTP
};

typedef NS_ENUM(NSUInteger, ZHResponseSerializer) {
    /**设置响应数据为JSON格式*/
    ZHResponsetSerializerJSON,
    /**设置响应数据为二进制格式*/
    ZHResponseSerializerHTTP
};

FOUNDATION_EXPORT const NSInteger ZHHttpRequestTimeOut;

@interface ZHHttpBaseConfig : NSObject

@end

NS_ASSUME_NONNULL_END
