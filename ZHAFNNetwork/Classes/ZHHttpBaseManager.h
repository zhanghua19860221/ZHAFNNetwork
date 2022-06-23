//
//  ZHHttpBaseManager.h
//  ZHNetWork
//
//  Created by Breeze on 2022/6/22.
//

#import <Foundation/Foundation.h>
#import "ZHHttpBaseConfig.h"
#import <AFNetworking/AFNetworking.h>

NS_ASSUME_NONNULL_BEGIN

@class YYCache, AFHTTPSessionManager;

/**网络请求的Block*/
typedef void(^ZHHttpRequest)(id _Nullable responseObject, NSError *_Nullable error, BOOL isFromCache);

/**文件下载的Block
 * path 文件下载后的存储路径
 */
typedef void(^ZHHttpDownload)(NSString * _Nullable path, NSError   * _Nullable error);

/**文件上传或者下载进度Block*/
typedef void(^ZHHttpProgress)(NSProgress   * _Nullable progress);

/**当前网络状态Block*/
typedef void(^ZHNetworkStatus)(ZHNetworkStatusType status);

/**错误统一拦截处理Block*/
typedef NSError *_Nullable(^ErrorReduceBlock)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error);

/**返回请求结果统一拦截处理Block*/
typedef id _Nullable (^ResponseReduceBlock)(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject);


@interface ZHHttpBaseManager : NSObject

/**是否按App版本号缓存网络请求内容(默认关闭)*/
+ (void)setCacheVersionEnabled:(BOOL)bFlag;

/**使用自定义缓存版本号*/
+ (void)setCacheVersion:(NSString *_Nullable)version;

/**输出Log信息开关(默认打开)*/
+ (void)setLogEnabled:(BOOL)bFlag;

/**过滤缓存Key*/
+ (void)setFiltrationCacheKey:(NSArray *_Nullable)filtrationCacheKey;

/**设置接口根路径, 设置后所有的网络访问都使用相对路径 尽量以"/"结束*/
+ (void)setBaseURL:(NSString *_Nullable)baseURL;

/**设置接口请求头 */
+ (void)setHeadr:(NSDictionary *_Nullable)header;

/**设置接口基本参数(如:用户ID, Token)*/
+ (void)setBaseParameters:(NSDictionary *_Nullable)parameters;

/**设置统一预处理结果*/
+ (void)setResponseReduceBlock:(ResponseReduceBlock _Nullable )responseReduceBlock;

/**设置统一预处理错误*/
+ (void)setErrorReduceBlock:(ErrorReduceBlock _Nullable )errorReduceBlock;

/**实时获取网络状态*/
+ (void)getNetworkStatusWithBlock:(ZHNetworkStatus _Nullable )networkStatus;

/**判断是否有网*/
+ (BOOL)isNetwork;

/**是否是手机网络*/
+ (BOOL)isWWANNetwork;

/**是否是WiFi网络*/
+ (BOOL)isWiFiNetwork;

/**取消所有Http请求*/
+ (void)cancelAllRequest;

/**取消指定URL的Http请求*/
+ (void)cancelRequestWithURL:(NSString *_Nullable)url;

/**设置请求超时时间(默认30s) */
+ (void)setRequestTimeoutInterval:(NSTimeInterval)time;

/**是否打开网络加载菊花(默认打开)*/
+ (void)openNetworkActivityIndicator:(BOOL)open;


/**
 GET请求
 
 @param url 请求地址
 @param parameters 请求参数
 @param cachePolicy 缓存策略
 @param callback 请求回调
 */
+ (void)GETWithURL:(NSString *_Nullable)url
        parameters:(NSDictionary *_Nullable)parameters
       cachePolicy:(ZHCachePolicy)cachePolicy
          callback:(ZHHttpRequest _Nullable )callback;


/**
 POST请求
 
 @param url 请求地址
 @param parameters 请求参数
 @param callback 请求回调
 */
+ (void)POSTWithURL:(NSString *_Nullable)url
         parameters:(NSDictionary *_Nullable)parameters
           callback:(ZHHttpRequest _Nullable )callback;

/**
 HEAD请求
 
 @param url 请求地址
 @param parameters 请求参数
 @param callback 请求回调
 */
+ (void)HEADWithURL:(NSString *_Nullable)url
         parameters:(NSDictionary *_Nullable)parameters
           callback:(ZHHttpRequest _Nullable )callback;


/**
 PUT请求
 
 @param url 请求地址
 @param parameters 请求参数
 @param callback 请求回调
 */
+ (void)PUTWithURL:(NSString *_Nullable)url
        parameters:(NSDictionary *_Nullable)parameters
          callback:(ZHHttpRequest _Nullable )callback;



/**
 PATCH请求
 
 @param url 请求地址
 @param parameters 请求参数
 @param callback 请求回调
 */
+ (void)PATCHWithURL:(NSString *_Nullable)url
          parameters:(NSDictionary *_Nullable)parameters
            callback:(ZHHttpRequest _Nullable )callback;


/**
 DELETE请求
 
 @param url 请求地址
 @param parameters 请求参数
 @param callback 请求回调
 */
+ (void)DELETEWithURL:(NSString *_Nullable)url
           parameters:(NSDictionary *_Nullable)parameters
             callback:(ZHHttpRequest _Nullable )callback;

/**
 DELETE请求
 
 @param url 请求地址
 @param parameters 请求参数
 @param callback 请求回调
 @note 防止参数拼到url后面
 */
+ (void)DELETEInURIWithURL:(NSString *_Nullable)url
           parameters:(NSDictionary *_Nullable)parameters
             callback:(ZHHttpRequest _Nullable )callback;


/**
 上传文件
 
 @param url 请求地址
 @param parameters 请求参数
 @param name 文件对应服务器上的字段
 @param filePath 文件路径
 @param progress 上传进度
 @param callback 请求回调
 */
+ (void)uploadFileWithURL:(NSString *_Nullable)url
               parameters:(NSDictionary *_Nullable)parameters
                     name:(NSString *_Nullable)name
                 filePath:(NSString *_Nullable)filePath
                 progress:(ZHHttpProgress _Nullable )progress
                 callback:(ZHHttpRequest _Nullable )callback;


/**
 上传图片文件

 @param url 请求地址
 @param parameters 请求参数
 @param images 图片数组
 @param name 文件对应服务器上的字段
 @param fileName 文件名
 @param mimeType 图片文件类型：png/jpeg(默认类型)
 @param progress 上传进度
 @param callback 请求回调
 */
+ (void)uploadImageURL:(NSString *_Nullable)url
            parameters:(NSDictionary *_Nullable)parameters
                images:(NSArray<UIImage *> *_Nullable)images
                  name:(NSString *_Nullable)name
              fileName:(NSString *_Nullable)fileName
              mimeType:(NSString *_Nullable)mimeType
              progress:(ZHHttpProgress _Nullable )progress
              callback:(ZHHttpRequest _Nullable )callback;


/**
 下载文件

 @param url 请求地址
 @param fileDir 文件存储的目录(默认存储目录为Download)
 @param progress 文件下载的进度信息
 @param callback 请求回调
 */
+ (void)downloadWithURL:(NSString *_Nullable)url
                fileDir:(NSString *_Nullable)fileDir
                request:(NSMutableURLRequest *_Nullable)request
               progress:(ZHHttpProgress _Nullable )progress
               callback:(ZHHttpDownload _Nullable )callback;


#pragma mark -- 网络缓存

/**
 *  获取YYCache对象
 */
+ (YYCache *_Nullable)getYYCache;

/**
 *  异步缓存网络数据,根据请求的 URL与parameters
 *  做Key存储数据, 这样就能缓存多级页面的数据
 *
 *  @param httpData   服务器返回的数据
 *  @param url        请求的URL地址
 *  @param parameters 请求的参数
 */
+ (void)setHttpCache:(id _Nullable )httpData url:(NSString *_Nullable)url parameters:(NSDictionary *_Nullable)parameters;

/**
 *  根据请求的 URL与parameters 异步取出缓存数据
 *
 *  @param url        请求的URL
 *  @param parameters 请求的参数
 *  @param block      异步回调缓存的数据
 *
 */
+ (void)httpCacheForURL:(NSString *_Nullable)url parameters:(NSDictionary *_Nullable)parameters withBlock:(void(^_Nullable)(id _Nullable responseObject))block;

/**
 *  磁盘最大缓存开销大小 bytes(字节)
 */
+ (void)setCostLimit:(NSInteger)costLimit;

/**
 *  获取网络缓存的总大小 bytes(字节)
 */
+ (NSInteger)getAllHttpCacheSize;

/**
 *  获取网络缓存的总大小 bytes(字节)
 *  推荐使用该方法 不会阻塞主线程，通过block返回
 */
+ (void)getAllHttpCacheSizeBlock:(void(^_Nullable)(NSInteger totalCount))block;

/**
 *  删除所有网络缓存
 */
+ (void)removeAllHttpCache;

/**
 *  删除所有网络缓存
 *  推荐使用该方法 不会阻塞主线程，同时返回Progress
 */
+ (void)removeAllHttpCacheBlock:(void(^_Nullable)(int removedCount, int totalCount))progress
                       endBlock:(void(^_Nullable)(BOOL error))end;


#pragma mark -- 重置AFHTTPSessionManager相关属性

/**
 *  获取AFHTTPSessionManager对象
 */
+ (AFHTTPSessionManager *_Nullable)getAFHTTPSessionManager;

/**
 设置网络请求参数的格式:默认为JSON格式

 @param requestSerializer ZHRequestSerializerJSON---JSON格式  ZHRequestSerializerHTTP--HTTP
 */
+ (void)setRequestSerializer:(ZHRequestSerializer)requestSerializer;



/**
 设置服务器响应数据格式:默认为JSON格式

 @param responseSerializer ZHResponseSerializerJSON---JSON格式  ZHResponseSerializerHTTP--HTTP

 */
+ (void)setResponseSerializer:(ZHResponseSerializer)responseSerializer;


/**
 设置请求头
 */
+ (void)setValue:(NSString *_Nullable)value forHTTPHeaderField:(NSString *_Nullable)field;


/**
 配置自建证书的Https请求，参考链接:http://blog.csdn.net/syg90178aw/article/details/52839103

 @param cerPath 自建https证书路径
 @param validatesDomainName 是否验证域名(默认YES) 如果证书的域名与请求的域名不一致，需设置为NO
 服务器使用其他信任机构颁发的证书也可以建立连接，但这个非常危险，建议打开 .validatesDomainName=NO,主要用于这种情况:客户端请求的是子域名，而证书上是另外一个域名。因为SSL证书上的域名是独立的
 For example:证书注册的域名是www.baidu.com,那么mail.baidu.com是无法验证通过的
 */
+ (void)setSecurityPolicyWithCerPath:(NSString *_Nullable)cerPath validatesDomainName:(BOOL)validatesDomainName;

#pragma mark -- 拼接URL工具

/// 图片表单上传
/// @param url 上传地址
/// @param dic 上传参数
/// @param name 文件名称
/// @param type 文件类型
/// @param imageData 图片二进制
/// @param progress 上传进度
/// @param successBlock 成功回调
+(void)upLoadFormImageUrl:(NSString *_Nullable)url parameters:(NSDictionary *_Nonnull)dic name:(NSString *_Nullable)name typy:(NSString *_Nonnull)type imageData:(NSData *_Nullable)imageData imageNum:(NSInteger )num progress:(ZHHttpProgress _Nonnull )progress success:(ZHHttpRequest _Nullable )successBlock;

/// 表单上传 视频
/// @param url 上传地址
/// @param dic 上传参数
/// @param name 文件名称
/// @param type 文件类型
/// @param videoData 视频二进制
/// @param progress 上传进度
/// @param successBlock 成功回调
+(void)upLoadFormVideoUrl:(NSString *_Nullable)url parameters:(NSDictionary *_Nullable)dic name:(NSString *_Nonnull)name typy:(NSString *_Nullable)type videoData:(NSData *_Nullable)videoData progress:(ZHHttpProgress _Nullable )progress success:(ZHHttpRequest _Nullable )successBlock fail:(ZHHttpRequest _Nullable )failBlock;


/// 带成功状态码
/// @param url 更新地址
/// @param parameters 传参
/// @param callback 成功回调
/// @note 错误处理统一在业务分类中处理
+ (void)untreatedHttpWithMethod:(ZHRequestMethod)method url:(NSString *_Nullable)url parameters:(NSDictionary *_Nullable)parameters callback:(ZHHttpRequest _Nullable )callback;




@end

NS_ASSUME_NONNULL_END
