//
//  ZHHttpBaseManager.m
//  ZHNetWork
//
//  Created by Breeze on 2022/6/22.
//

#import "ZHHttpBaseManager.h"
#import "YYCache.h"
#import "AFNetworkActivityIndicatorManager.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import <CommonCrypto/CommonDigest.h>
#import "NSDictionary+ZHNetwork.h"

//#ifdef DEBUG
#define ATLog(FORMAT, ...) fprintf(stderr,"[%s:%d行] %s\n",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
//#else
//#define ATLog(...)
//#endif

///系统维护通知
#define kSystemUpgradingNotify @"SystemUpgradingNotify"
///系统恢复通知
#define kSystemUpgradeSuccessNotify @"SystemUpgradeSuccessNotify"

@implementation ZHHttpBaseManager

static BOOL _logEnabled;
static BOOL _cacheVersionEnabled;
static NSMutableArray *_allSessionTask;
static NSDictionary *_baseParameters;
static NSArray *_filtrationCacheKey;
static AFHTTPSessionManager *_sessionManager;
static NSString *const NetworkResponseCache = @"ZHNetworkResponseCache";
//static NSString *const specialCharacters = @"/?&.";
static NSString * _baseURL;
static NSString * _cacheVersion;
static YYCache *_dataCache;
static ErrorReduceBlock _errorReduceBlock;
static ResponseReduceBlock _responseReduceBlock;

#pragma mark -- 初始化相关属性
+ (void)initialize{
    
    _sessionManager = [AFHTTPSessionManager manager];
    //设置请求超时时间
    _sessionManager.requestSerializer.timeoutInterval = 30.f;
    //设置服务器返回结果的类型:JSON(AFJSONResponseSerializer,AFHTTPResponseSerializer)
    _sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
    _sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/plain", @"text/javascript", @"text/xml", @"image/*",@"application/pdf",@"multipart/form-data",@"application/x-www-form-urlencoded",@"application/octet-stream",nil];
    //打开状态栏菊花
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    _dataCache = [YYCache cacheWithName:NetworkResponseCache];
    _logEnabled = YES;
    _cacheVersionEnabled = NO;
}

#pragma mark - class

/**
 是否按App版本号缓存网络请求内容(默认关闭)
 */
+ (void)setCacheVersionEnabled:(BOOL)bFlag
{
    _cacheVersionEnabled = bFlag;
    if (bFlag) {
        if (!_cacheVersion.length) {
            _cacheVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        }
        _dataCache = [YYCache cacheWithName:[NSString stringWithFormat:@"%@(%@)",NetworkResponseCache,_cacheVersion]];
    }else{
        _dataCache = [YYCache cacheWithName:NetworkResponseCache];
    }
}

/**
 使用自定义缓存版本号
 */
+ (void)setCacheVersion:(NSString*)version
{
    _cacheVersion = version;
    [self setCacheVersionEnabled:YES];
}


/**
 输出Log信息开关
 */
+ (void)setLogEnabled:(BOOL)bFlag
{
    _logEnabled = bFlag;
}


/**
 过滤缓存Key
 */
+ (void)setFiltrationCacheKey:(NSArray *)filtrationCacheKey
{
    _filtrationCacheKey = filtrationCacheKey;
}

/**
 设置接口根路径, 设置后所有的网络访问都使用相对路径
 */
+ (void)setBaseURL:(NSString *)baseURL
{
    _baseURL = baseURL;
}

/**
 设置接口请求头
 */
+ (void)setHeadr:(NSDictionary *)header
{
    for (NSString * key in header.allKeys) {
        [_sessionManager.requestSerializer setValue:header[key] forHTTPHeaderField:key];
    }
}

/**
 设置接口基本参数
 */
+ (void)setBaseParameters:(NSDictionary *)parameters
{
    _baseParameters = parameters;
}

/**
 设置统一预处理结果
 */
+ (void)setResponseReduceBlock:(ResponseReduceBlock)responseReduceBlock
{
    _responseReduceBlock = responseReduceBlock;
}

/**
 设置统一预处理错误
 */
+ (void)setErrorReduceBlock:(ErrorReduceBlock)errorReduceBlock
{
    _errorReduceBlock = errorReduceBlock;
}

/**
 实时获取网络状态
 */
+ (void)getNetworkStatusWithBlock:(ZHNetworkStatus)networkStatus{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[AFNetworkReachabilityManager sharedManager] startMonitoring];
        [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            
            switch (status) {
                case AFNetworkReachabilityStatusUnknown:
                    networkStatus ? networkStatus(ZHNetworkStatusUnknown) : nil;
                    break;
                case AFNetworkReachabilityStatusNotReachable:
                    networkStatus ? networkStatus(ZHNetworkStatusNotReachable) : nil;
                    break;
                case AFNetworkReachabilityStatusReachableViaWWAN:
                    networkStatus ? networkStatus(ZHNetworkStatusReachableWWAN) : nil;
                    break;
                case AFNetworkReachabilityStatusReachableViaWiFi:
                    networkStatus ? networkStatus(ZHNetworkStatusReachableWiFi) : nil;
                    break;
                default:
                    break;
            }
        }];
    });
}

/**
 判断是否有网
 */
+ (BOOL)isNetwork{
    
    return [AFNetworkReachabilityManager sharedManager].reachable;
}

/**
 是否是手机网络
 */
+ (BOOL)isWWANNetwork{
    
    return [AFNetworkReachabilityManager sharedManager].reachableViaWWAN;
}

/**
 是否是WiFi网络
 */
+ (BOOL)isWiFiNetwork{
    
    return [AFNetworkReachabilityManager sharedManager].reachableViaWiFi;
}

/**
 取消所有Http请求
 */
+ (void)cancelAllRequest{
    @synchronized (self) {
        [[self allSessionTask] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            [task cancel];
        }];
        [[self allSessionTask] removeAllObjects];
    }
}

/**
 取消指定URL的Http请求
 */
+ (void)cancelRequestWithURL:(NSString *)url{
    if (!url) { return; }
    @synchronized (self) {
        [[self allSessionTask] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([task.currentRequest.URL.absoluteString hasPrefix:url]) {
                [task cancel];
                [[self allSessionTask] removeObject:task];
                *stop = YES;
            }
        }];
    }
}

/**
 设置请求超时时间(默认30s)
 */
+ (void)setRequestTimeoutInterval:(NSTimeInterval)time{
    _sessionManager.requestSerializer.timeoutInterval = time;
}

/**
 是否打开网络加载菊花(默认打开)
 */
+ (void)openNetworkActivityIndicator:(BOOL)open{
    [[AFNetworkActivityIndicatorManager sharedManager]setEnabled:open];
}



#pragma mark -- 缓存描述文字
+ (NSString *)cachePolicyStr:(ZHCachePolicy)cachePolicy
{
    switch (cachePolicy) {
        case ZHCachePolicyIgnoreCache:
            return @"只从网络获取数据，且数据不会缓存在本地";
            break;
        case ZHCachePolicyCacheOnly:
            return @"只从缓存读数据，如果缓存没有数据，返回一个空";
            break;
        case ZHCachePolicyNetworkOnly:
            return @"先从网络获取数据，同时会在本地缓存数据";
            break;
        case ZHCachePolicyCacheElseNetwork:
            return @"先从缓存读取数据，如果没有再从网络获取";
            break;
        case ZHCachePolicyNetworkElseCache:
            return @"先从网络获取数据，如果没有再从缓存读取数据";
            break;
        case ZHCachePolicyCacheThenNetwork:
            return @"先从缓存读取数据，然后再从网络获取数据，Block将产生两次调用";
            break;
            
        default:
            return @"未知缓存策略，采用ZHCachePolicyIgnoreCache策略";
            break;
    }
}

#pragma mark -- GET请求
+ (void)GETWithURL:(NSString *)url
        parameters:(NSDictionary *)parameters
       cachePolicy:(ZHCachePolicy)cachePolicy
           callback:(ZHHttpRequest)callback
{
    [self HTTPGetUrl:url parameters:parameters cachePolicy:cachePolicy callback:callback];
}


#pragma mark -- POST请求
+ (void)POSTWithURL:(NSString *)url
         parameters:(NSDictionary *)parameters
            callback:(ZHHttpRequest)callback
{
    [self HTTPUnCacheWithMethod:ZHRequestMethodPOST url:url parameters:parameters callback:callback];
}

#pragma mark -- HEAD请求
+ (void)HEADWithURL:(NSString *)url
         parameters:(NSDictionary *)parameters
            callback:(ZHHttpRequest)callback
{
    [self HTTPUnCacheWithMethod:ZHRequestMethodHEAD url:url parameters:parameters callback:callback];
}


#pragma mark -- PUT请求
+ (void)PUTWithURL:(NSString *)url
        parameters:(NSDictionary *)parameters
           callback:(ZHHttpRequest)callback
{
    [self HTTPUnCacheWithMethod:ZHRequestMethodPUT url:url parameters:parameters callback:callback];
}


#pragma mark -- PATCH请求
+ (void)PATCHWithURL:(NSString *)url
          parameters:(NSDictionary *)parameters
             callback:(ZHHttpRequest)callback
{
    [self HTTPUnCacheWithMethod:ZHRequestMethodPATCH url:url parameters:parameters callback:callback];
}
#pragma mark -- DELETE请求
+ (void)DELETEInURIWithURL:(NSString *)url
           parameters:(NSDictionary *)parameters
              callback:(ZHHttpRequest)callback
{
    _sessionManager.requestSerializer.HTTPMethodsEncodingParametersInURI = [NSSet setWithArray:@[@""]];
    [self HTTPUnCacheWithMethod:ZHRequestMethodDELETE url:url parameters:parameters callback:callback];
    _sessionManager.requestSerializer.HTTPMethodsEncodingParametersInURI = [NSSet setWithObjects:@"GET", @"HEAD", @"DELETE", nil];
}

#pragma mark -- DELETE请求
+ (void)DELETEWithURL:(NSString *)url
           parameters:(NSDictionary *)parameters
              callback:(ZHHttpRequest)callback
{
    [self HTTPUnCacheWithMethod:ZHRequestMethodDELETE url:url parameters:parameters callback:callback];
}

+ (void)HTTPGetUrl:(NSString *)url
            parameters:(NSDictionary *)parameters
           cachePolicy:(ZHCachePolicy)cachePolicy
              callback:(ZHHttpRequest)callback{

    if (_baseURL.length) {
        url = [NSString stringWithFormat:@"%@%@",_baseURL,url];
    }

    if (_logEnabled) {
        ATLog(@"\n请求参数 = %@\n请求URL = %@\n请求方式 = %@\n缓存策略 = %@\n版本缓存 = %@",parameters ? [self jsonToString:parameters]:@"空", url, [self getMethodStr:ZHRequestMethodGET], [self cachePolicyStr:cachePolicy], _cacheVersionEnabled? @"启用":@"未启用");
    }
    
    if (cachePolicy == ZHCachePolicyIgnoreCache) {
        //只从网络获取数据，且数据不会缓存在本地
        [self httpWithMethod:ZHRequestMethodGET url:url parameters:parameters callback:callback];
    }else if (cachePolicy == ZHCachePolicyCacheOnly){
        //只从缓存读数据，如果缓存没有数据，返回一个空。
        [self httpCacheForURL:url parameters:parameters withBlock:^(id<NSCoding> object) {
            callback ? callback(object, nil, YES) : nil;
        }];
    }else if (cachePolicy == ZHCachePolicyNetworkOnly){
        //先从网络获取数据，同时会在本地缓存数据
        [self httpWithMethod:ZHRequestMethodGET url:url parameters:parameters callback:^(id responseObject, NSError *error, BOOL isFromCache) {
            callback ? callback(responseObject, error, NO) : nil;
            [self setHttpCache:responseObject url:url parameters:parameters];
        }];
        
    }else if (cachePolicy == ZHCachePolicyCacheElseNetwork){
        //先从缓存读取数据，如果没有再从网络获取
        [self httpCacheForURL:url parameters:parameters withBlock:^(id<NSCoding> object) {
            if (object) {
                callback ? callback(object, nil, YES) : nil;
            }else{
                [self httpWithMethod:ZHRequestMethodGET url:url parameters:parameters callback:^(id responseObject, NSError *error, BOOL isFromCache) {
                    callback ? callback(responseObject, error, NO) : nil;
                }];
            }
        }];
    }else if (cachePolicy == ZHCachePolicyNetworkElseCache){
        //先从网络获取数据，如果没有，此处的没有可以理解为访问网络失败，再从缓存读取
        [self httpWithMethod:ZHRequestMethodGET url:url parameters:parameters callback:^(id responseObject, NSError *error, BOOL isFromCache) {
            if (responseObject && !error) {
                callback ? callback(responseObject, error, NO) : nil;
                [self setHttpCache:responseObject url:url parameters:parameters];
            }else{
                [self httpCacheForURL:url parameters:parameters withBlock:^(id<NSCoding> object) {
                    callback ? callback(object, nil, YES) : nil;
                }];
            }
        }];
    }else if (cachePolicy == ZHCachePolicyCacheThenNetwork){
        //先从缓存读取数据，然后在本地缓存数据，无论结果如何都会再次从网络获取数据，在这种情况下，Block将产生两次调用
        [self httpCacheForURL:url parameters:parameters withBlock:^(id<NSCoding> object) {
            callback ? callback(object, nil, YES) : nil;
            [self httpWithMethod:ZHRequestMethodGET url:url parameters:parameters callback:^(id responseObject, NSError *error, BOOL isFromCache) {
                callback ? callback(responseObject, error, NO) : nil;
                [self setHttpCache:responseObject url:url parameters:parameters];
            }];
        }];
    }else{
        //缓存策略错误，将采取 ZHCachePolicyIgnoreCache 策略
        ATLog(@"缓存策略错误");
        [self httpWithMethod:ZHRequestMethodGET url:url parameters:parameters callback:callback];
    }
}

+ (void)HTTPUnCacheWithMethod:(ZHRequestMethod)method
                   url:(NSString *)url
            parameters:(NSDictionary *)parameters
              callback:(ZHHttpRequest)callback{
    if (_baseURL.length) {
        url = [NSString stringWithFormat:@"%@%@",_baseURL,url];
    }
    if (_baseParameters.count) {
        NSMutableDictionary * mutableBaseParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
        [mutableBaseParameters addEntriesFromDictionary:_baseParameters];
        parameters = [mutableBaseParameters copy];
        
    }
    if (_logEnabled) {
        ATLog(@"\n请求参数 = %@\n请求URL = %@\n请求方式 = %@\n缓存策略 = %@\n版本缓存 = %@",parameters ? [self jsonToString:parameters]:@"空", url, [self getMethodStr:method], [self cachePolicyStr:ZHCachePolicyIgnoreCache], _cacheVersionEnabled? @"启用":@"未启用");
    }
    [self httpWithMethod:method url:url parameters:parameters callback:callback];
}

#pragma mark -- 网络请求处理
+(void)httpWithMethod:(ZHRequestMethod)method url:(NSString *)url parameters:(NSDictionary *)parameters callback:(ZHHttpRequest)callback{
    
    [self dataTaskWithHTTPMethod:method url:url parameters:parameters callback:^(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject) {
        NSURLRequest *currentRequest= (NSURLRequest*)task.currentRequest;
        NSDictionary *dic = currentRequest.allHTTPHeaderFields;
        NSString * url = currentRequest.URL.absoluteString;
        NSLog(@"网络请求url->>>%@",url);
        NSLog(@"网络请求Headr->>>%@",dic.toString);
        if (_logEnabled) {
            ATLog(@"请求结果 = %@",[self jsonToString:responseObject]);
        }
        [[self allSessionTask] removeObject:task];
        if (responseObject == nil) {
            responseObject = @"";
        }
        callback ? callback(_responseReduceBlock?_responseReduceBlock(task,responseObject):responseObject, nil, NO) : nil;
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSURLRequest *currentRequest= (NSURLRequest*)task.currentRequest;
        NSDictionary *dic = currentRequest.allHTTPHeaderFields;
        NSString * url = currentRequest.URL.absoluteString;
        NSLog(@"网络请求url->>>%@",url);
        NSLog(@"网络请求Headr->>>%@",dic.toString);
        if (_logEnabled) {
            ATLog(@"错误内容 = %@",error);
        }
        callback ? callback(nil, _errorReduceBlock?_errorReduceBlock(task,error):error, NO) : nil;
        [[self allSessionTask] removeObject:task];
    }];
}
#pragma mark -- 未处理的网络请求
+ (void)untreatedHttpWithMethod:(ZHRequestMethod)method url:(NSString *)url parameters:(NSDictionary *)parameters callback:(ZHHttpRequest)callback{
    
    [self dataTaskWithHTTPMethod:method url:url parameters:parameters callback:^(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject) {
        NSURLRequest *currentRequest= (NSURLRequest*)task.currentRequest;
        NSDictionary *dic = currentRequest.allHTTPHeaderFields;
        NSString * url = currentRequest.URL.absoluteString;
        NSLog(@"参数->>>%@",parameters);
        NSLog(@"网络请求url->>>%@",url);
        NSLog(@"网络请求Headr->>>%@",dic.toString);
        if (_logEnabled) {
            ATLog(@"请求结果 = %@",[self jsonToString:responseObject]);
        }
        [[self allSessionTask] removeObject:task];
        if (responseObject == nil) {
            responseObject = @"";
        }
        //系统维护通知 - 系统恢复通知 根据后台约定的错误码 进行判断
        //if ([responseObject[@"code"] integerValue] == 10000) {
        //    [[NSNotificationCenter defaultCenter] postNotificationName:kSystemUpgradeSuccessNotify object:nil];
        //}
        //else if ([responseObject[@"code"] integerValue] == 70000) {
        //    [[NSNotificationCenter defaultCenter] postNotificationName:kSystemUpgradingNotify object:responseObject];
        //}
        callback ? callback(responseObject, nil, NO) : nil;
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSURLRequest *currentRequest= (NSURLRequest*)task.currentRequest;
        NSDictionary *dic = currentRequest.allHTTPHeaderFields;
        NSString * url = currentRequest.URL.absoluteString;
        NSLog(@"参数->>>%@",parameters);
        NSLog(@"网络请求url->>>%@",url);
        NSLog(@"网络请求Headr->>>%@",dic.toString);
        if (_logEnabled) {
            ATLog(@"错误内容 = %@",error);
        }
        callback ? callback(nil, _errorReduceBlock?_errorReduceBlock(task,error):error, NO) : nil;
        [[self allSessionTask] removeObject:task];
    }];
}

+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString{
    if (jsonString == nil) {
        return nil;
    }
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
    if(err) {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}
+(void)dataTaskWithHTTPMethod:(ZHRequestMethod)method url:(NSString *)url parameters:(NSDictionary *)parameters
                      callback:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))callback
                      failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure
{
    NSLog(@"%@",url);
    NSURLSessionTask *sessionTask;
    if (method == ZHRequestMethodGET){
        sessionTask = [_sessionManager GET:url parameters:parameters headers:@{} progress:nil success:callback failure:failure];
    }else if (method == ZHRequestMethodPOST) {
        sessionTask = [_sessionManager POST:url parameters:parameters headers:@{} progress:nil success:callback failure:failure];
    }else if (method == ZHRequestMethodHEAD) {
        sessionTask = [_sessionManager HEAD:url parameters:parameters headers:@{} success:nil failure:failure];
    }else if (method == ZHRequestMethodPUT) {
        sessionTask = [_sessionManager PUT:url parameters:parameters headers:@{} success:callback failure:failure];
    }else if (method == ZHRequestMethodPATCH) {
        sessionTask = [_sessionManager PATCH:url parameters:parameters headers:@{} success:callback failure:failure];
    }else if (method == ZHRequestMethodDELETE) {
        sessionTask = [_sessionManager DELETE:url parameters:parameters headers:@{} success:callback failure:failure];
    }
    //添加最新的sessionTask到数组
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil;
}

#pragma mark -- 上传文件
+ (void)uploadFileWithURL:(NSString *)url parameters:(NSDictionary *)parameters name:(NSString *)name filePath:(NSString *)filePath progress:(ZHHttpProgress)progress callback:(ZHHttpRequest)callback
{
    NSURLSessionTask *sessionTask = [_sessionManager POST:url parameters:parameters headers:@{} constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        //添加-文件
        NSError *error = nil;
        [formData appendPartWithFileURL:[NSURL URLWithString:filePath] name:name error:&error];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        //上传进度
        dispatch_sync(dispatch_get_main_queue(), ^{
            progress ? progress(uploadProgress) : nil;
        });
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [[self allSessionTask] removeObject:task];
        callback ? callback(responseObject, nil, NO) : nil;
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        [[self allSessionTask] removeObject:task];
        callback ? callback(nil, error, NO) : nil;
    }];
    //添加最新的sessionTask到数组
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil;
}


#pragma mark -- 上传图片文件
+ (void)uploadImageURL:(NSString *)url parameters:(NSDictionary *)parameters images:(NSArray<UIImage *> *)images name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType progress:(ZHHttpProgress)progress callback:(ZHHttpRequest)callback
{
    NSURLSessionTask *sessionTask = [_sessionManager POST:url parameters:parameters headers:@{} constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        //压缩-添加-上传图片
        [images enumerateObjectsUsingBlock:^(UIImage * _Nonnull image, NSUInteger idx, BOOL * _Nonnull stop) {
            NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
            [formData appendPartWithFileData:imageData name:name fileName:[NSString stringWithFormat:@"%@%lu.%@",fileName,(unsigned long)idx,mimeType ? mimeType : @"jpeg"] mimeType:[NSString stringWithFormat:@"image/%@",mimeType ? mimeType : @"jpeg"]];
        }];
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        //上传进度
        dispatch_sync(dispatch_get_main_queue(), ^{
            progress ? progress(uploadProgress) : nil;
        });
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [[self allSessionTask] removeObject:task];
        callback ? callback(responseObject, nil, NO) : nil;
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        [[self allSessionTask] removeObject:task];
        callback ? callback(nil, error, NO) : nil;
    }];
    //添加最新的sessionTask到数组
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil;
}

#pragma mark -- 下载文件
+(void)downloadWithURL:(NSString *)url fileDir:(NSString *)fileDir request:(NSMutableURLRequest *_Nullable)request progress:(ZHHttpProgress)progress callback:(ZHHttpDownload)callback
{

    __block NSURLSessionDownloadTask *downloadTask = [_sessionManager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        if (_logEnabled) {
            ATLog(@"下载进度:%.2f%%",100.0*downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);
        }

        dispatch_sync(dispatch_get_main_queue(), ^{
            progress ? progress(downloadProgress) : nil;
        });

    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        //拼接缓存目录
        NSString *downloadDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]stringByAppendingPathComponent:fileDir ? fileDir : @"Download"];

        //打开文件管理器
        NSFileManager *fileManager = [NSFileManager defaultManager];
        //创建DownLoad目录
        [fileManager createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:nil];
        //拼接文件路径
        NSString *filePath = [downloadDir stringByAppendingPathComponent:response.suggestedFilename];

        return [NSURL fileURLWithPath:filePath];

    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        [[self allSessionTask] removeObject:downloadTask];
        if (callback && error) {
            callback ? callback(nil, error) : nil;
            return;
        }
        callback ? callback(filePath.absoluteString, nil) : nil;
    }];
    //开始下载
    [downloadTask resume];

    //添加sessionTask到数组
    downloadTask ? [[self allSessionTask] addObject:downloadTask] : nil;
}

+ (NSString *)getMethodStr:(ZHRequestMethod)method{
    switch (method) {
        case ZHRequestMethodGET:
            return @"GET";
            break;
        case ZHRequestMethodPOST:
            return @"POST";
            break;
        case ZHRequestMethodHEAD:
            return @"HEAD";
            break;
        case ZHRequestMethodPUT:
            return @"PUT";
            break;
        case ZHRequestMethodPATCH:
            return @"PATCH";
            break;
        case ZHRequestMethodDELETE:
            return @"DELETE";
            break;
            
        default:
            break;
    }
}

#pragma mark -- 网络缓存
+ (YYCache *)getYYCache
{
    return _dataCache;
}

+ (void)setHttpCache:(id)httpData url:(NSString *)url parameters:(NSDictionary *)parameters
{
    if (httpData) {
        NSString *cacheKey = [self cacheKeyWithURL:url parameters:parameters];
        [_dataCache setObject:httpData forKey:cacheKey withBlock:nil];
    }
}

+ (void)httpCacheForURL:(NSString *)url parameters:(NSDictionary *)parameters withBlock:(void(^)(id responseObject))block
{
    NSString *cacheKey = [self cacheKeyWithURL:url parameters:parameters];
    [_dataCache objectForKey:cacheKey withBlock:^(NSString * _Nonnull key, id<NSCoding>  _Nonnull object) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_logEnabled) {
                //ATLog(@"缓存结果 = %@",[self jsonToString:object]);
                ATLog(@"缓存结果 = %@",@"已经注释");
            }
            block(object);
        });
    }];
}


+ (void)setCostLimit:(NSInteger)costLimit
{
    [_dataCache.diskCache setCostLimit:costLimit];//磁盘最大缓存开销
}

+ (NSInteger)getAllHttpCacheSize
{
    return [_dataCache.diskCache totalCost];
}

+ (void)getAllHttpCacheSizeBlock:(void(^)(NSInteger totalCount))block
{
    return [_dataCache.diskCache totalCountWithBlock:block];
}

+ (void)removeAllHttpCache
{
    [_dataCache.diskCache removeAllObjects];
}

+ (void)removeAllHttpCacheBlock:(void(^)(int removedCount, int totalCount))progress
                       endBlock:(void(^)(BOOL error))end
{
    [_dataCache.diskCache removeAllObjectsWithProgressBlock:progress endBlock:end];
}

+ (NSString *)cacheKeyWithURL:(NSString *)url parameters:(NSDictionary *)parameters
{
    if(!parameters){return url;};
    
    if (_filtrationCacheKey.count) {
        NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
        [mutableParameters removeObjectsForKeys:_filtrationCacheKey];
        parameters =  [mutableParameters copy];
    }

    
    // 将参数字典转换成字符串
    NSData *stringData = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil];
    NSString *paraString = [[NSString alloc] initWithData:stringData encoding:NSUTF8StringEncoding];
    
    // 将URL与转换好的参数字符串拼接在一起,成为最终存储的KEY值
    NSString *cacheKey = [NSString stringWithFormat:@"%@%@",url,paraString];
    
    return [self md5StringFromString:cacheKey];
}

/**
 MD5加密URL
 */
+ (NSString *)md5StringFromString:(NSString *)string {
    NSParameterAssert(string != nil && [string length] > 0);
    
    const char *value = [string UTF8String];
    
    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(value, (CC_LONG)strlen(value), outputBuffer);
    
    NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++){
        [outputString appendFormat:@"%02x",outputBuffer[count]];
    }
    
    return outputString;
}


/**
 json转字符串
 */
+ (NSString *)jsonToString:(id)data
{
    if(!data || [data isEqual:[NSNull class]]){ return @"空"; }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
}


/************************************重置AFHTTPSessionManager相关属性**************/

#pragma mark -- 重置AFHTTPSessionManager相关属性

+ (AFHTTPSessionManager *)getAFHTTPSessionManager
{
    return _sessionManager;
}

+ (void)setRequestSerializer:(ZHRequestSerializer)requestSerializer{
    _sessionManager.requestSerializer = requestSerializer==ZHRequestSerializerHTTP ? [AFHTTPRequestSerializer serializer] : [AFJSONRequestSerializer serializer];
}

+ (void)setResponseSerializer:(ZHResponseSerializer)responseSerializer{
    _sessionManager.responseSerializer = responseSerializer==ZHResponseSerializerHTTP ? [AFHTTPResponseSerializer serializer] : [AFJSONResponseSerializer serializer];
}


+ (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field{
    [_sessionManager.requestSerializer setValue:value forHTTPHeaderField:field];
}


+ (void)setSecurityPolicyWithCerPath:(NSString *)cerPath validatesDomainName:(BOOL)validatesDomainName{
    
    NSData *cerData = [NSData dataWithContentsOfFile:cerPath];
    //使用证书验证模式
    AFSecurityPolicy *securitypolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    //如果需要验证自建证书(无效证书)，需要设置为YES
    securitypolicy.allowInvalidCertificates = YES;
    //是否需要验证域名，默认为YES
    securitypolicy.validatesDomainName = validatesDomainName;
    securitypolicy.pinnedCertificates = [[NSSet alloc]initWithObjects:cerData, nil];
    [_sessionManager setSecurityPolicy:securitypolicy];
}

/**
 图片表单上传
 @param url 上传地址
 @param dic 上传参数
 @param name 文件名称
 @param type 文件类型
 @param progress 进度
 @param successBlock 成功回调
 */
+(void)upLoadFormImageUrl:(NSString *)url parameters:(NSDictionary *)dic name:(NSString *)name typy:(NSString *)type imageData:(NSData *)imageData imageNum:(NSInteger )num progress:(ZHHttpProgress)progress success:(ZHHttpRequest)successBlock{

    [_sessionManager POST:url parameters:dic headers:@{} constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        //按照表单格式把二进制文件写入formData表单
        [formData appendPartWithFileData:imageData name:name fileName:[NSString stringWithFormat:@"%ld.png", (long)num] mimeType:type];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"发送成功");
            successBlock(responseObject,nil,NO);

    } failure:^(NSURLSessionDataTask *task, NSError *error) {
           successBlock? successBlock(nil, _errorReduceBlock?_errorReduceBlock(task,error):error, NO) : nil;
           NSLog(@"发送失败");
            
    }];
}

/**
 视频表单上传
 @param url 上传地址
 @param dic 上传参数
 @param name 文件名称
 @param type 文件类型
 @param videoData 视频二进制文件
 @param progress 上传进度
 @param successBlock 成功回调
*/
+(void)upLoadFormVideoUrl:(NSString *)url parameters:(NSDictionary *)dic name:(NSString *)name typy:(NSString *)type videoData:(NSData *)videoData progress:(ZHHttpProgress)progress success:(ZHHttpRequest)successBlock fail:(ZHHttpRequest)failBlock{
    [_sessionManager POST:url parameters:dic headers:@{} constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat   = @"yyyyMMddHHmmss";
        NSString *str = [formatter stringFromDate:[NSDate date]];
        NSString *fileName = [NSString stringWithFormat:@"%@.mp4", str];
        //NSLog(@"视频地址是====%@",videoUrl);
        [formData appendPartWithFileData:videoData name:@"file" fileName:fileName mimeType:@"VIDEO_IMAGE_GIF"];
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        progress(uploadProgress);
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        successBlock(responseObject,nil,NO);

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failBlock(nil, error, NO);
    }];

}

#pragma mark -- lazy --

/**
 所有的请求task数组
 */
+ (NSMutableArray *)allSessionTask{
    if (!_allSessionTask) {
        _allSessionTask = [NSMutableArray array];
    }
    return _allSessionTask;
}


@end
