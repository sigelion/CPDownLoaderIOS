//
//  CPDownLoader.m
//  CPDownloader
//
//  Created by 曹培 on 17/3/7.
//  Copyright © 2017年 Cs. All rights reserved.
//

#import "CPDownLoader.h"
#import "CPFileTool.h"

#define kCache NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject

@interface CPDownLoader ()<NSURLSessionDataDelegate>
{
    long long _fileTmpSize;
    long long _totalSize;
}
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, copy) NSString *downLoadingFilePath;
@property (nonatomic, copy) NSString *downLoadedFilePath;
@property (nonatomic, strong) NSOutputStream *outputStream;

@end

@implementation CPDownLoader

-(NSURLSession *)session {
    if (!_session) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue new]];
    }
    return _session;
}

- (NSString *)downLoadingPath {
    NSString *path = [kCache stringByAppendingPathComponent:@"downLoader/downloading"];
    if ([CPFileTool createDirectoryIfNotExists:path]) {
        return path;
    }
    return @"";
}

- (NSString *)downLoadedPath {
    NSString *path = [kCache stringByAppendingPathComponent:@"downLoader/downloaded"];
    if ([CPFileTool createDirectoryIfNotExists:path]) {
        return path;
    }
    return @"";
    
}


-(void)downLoadWithUrl:(NSURL *)url {
    
    self.downLoadingFilePath = [self.downLoadingPath stringByAppendingPathComponent:url.lastPathComponent];
    
    self.downLoadedFilePath = [self.downLoadedPath stringByAppendingPathComponent:url.lastPathComponent];
    
     
    //1.判断当前url对应的资源是否已经下载完毕，如果下载完毕，直接返回
    
    if ([CPFileTool fileExistsAtPath:self.downLoadedFilePath]) {
        NSLog(@"当前资源已经下载完毕");
        return;
    }
    
    //2.检测本地有没有下载过临时缓存
    //2.1没有本地缓存，从0字节开始下载（断点下载，HTTP，RANGE “bytes＝开始～”）
//    _fileTmpSize = 21574062;
    if (![CPFileTool fileExistsAtPath:self.downLoadingFilePath]) {
        [self downLoadWithUrl:url offset:_fileTmpSize];
        return;
    }
    
    //2.2有本地缓存，获取本地缓存的大小ls，文件真正的总大小rs
    
    
    _fileTmpSize = [CPFileTool fileSizeAtPath:self.downLoadingFilePath];
    [self downLoadWithUrl:url offset:_fileTmpSize];
    
    
    {
//    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
//    request.HTTPMethod = @"HEAD";
//    NSURLResponse *response;
//    NSError *error;
//    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
//    if (error) {
//        NSLog(@"%@", error);
//    }
    
//    NSLog(@"%@", response);
    }
}

-(void)downLoadWithUrl:(NSURL *)url offset:(long long)offset {
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:0];
    [request setValue:[NSString stringWithFormat:@"bytes=%lld-",offset] forHTTPHeaderField:@"Range"];
    NSURLSessionTask *task = [self.session dataTaskWithRequest:request];
    [task resume];
}

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(nonnull NSHTTPURLResponse *)response completionHandler:(nonnull void (^)(NSURLSessionResponseDisposition))completionHandler {
    
    NSLog(@"%@", response);
    
    //2.2.1 ls < rs 直接接着下载
    //2.2.1 ls = rs 移动到下载完成文件夹
    //2.2.1 ls > rs 删除本地缓存，从0开始下载
    
    NSString *rangeStr = response.allHeaderFields[@"Content-Range"];
    _totalSize = [[rangeStr componentsSeparatedByString:@"/"].lastObject longLongValue];
    if (_fileTmpSize == _totalSize) {
        // 验证文件的完整性 （大小相等，不一定代表文件完整）
        NSLog(@"下载完成，执行移动操作");
        [CPFileTool moveFileFromPath:self.downLoadingFilePath toPath:self.downLoadedFilePath];
        completionHandler(NSURLSessionResponseCancel);
        return;
    }
    
    if (_fileTmpSize > _totalSize) {
        NSLog(@"清除本地缓存，然后从0下载");
        // 清除本地缓存
        [CPFileTool removeFileAtPath:self.downLoadingFilePath];
        // 取消本次请求
        completionHandler(NSURLSessionResponseCancel);
        // 从0开始下载
        [self downLoadWithUrl:response.URL];
        
        return;
    }
    
    // 创建文件输出流
    self.outputStream = [NSOutputStream outputStreamToFileAtPath:self.downLoadingFilePath append:YES];
    [self.outputStream open];
    
    NSLog(@"继续接收数据");
    
    
    completionHandler(NSURLSessionResponseAllow);
}

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    
    NSLog(@"在接受数据");
    _fileTmpSize += data.length;
    [self.outputStream write:data.bytes maxLength:data.length];
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    
    if (!error) {
        NSLog(@"本次请求完成");
        // 文件完整性验证
        if (_fileTmpSize == _totalSize) {
            [CPFileTool moveFileFromPath:self.downLoadingFilePath toPath:self.downLoadedFilePath];
        }
    }
    else
        NSLog(@"有错误－%@",error);
}

@end
