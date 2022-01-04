//
//  CPFileTool.h
//  CPDownloader
//
//  Created by 曹培 on 17/3/7.
//  Copyright © 2017年 Cs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CPFileTool : NSObject

+ (BOOL)createDirectoryIfNotExists:(NSString *)path;

+ (BOOL)fileExistsAtPath:(NSString *)path;

+ (long long)fileSizeAtPath:(NSString *)path;

+ (void)removeFileAtPath:(NSString *)path;

+ (void)moveFileFromPath:(NSString *)fromPath toPath:(NSString *)toPath;

@end
