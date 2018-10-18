//
// Created by 吕晴阳 on 2018/10/17.
// Copyright (c) 2018 Lv Qingyang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


@interface AudioCompositionUtils : NSObject
+ (void)combineSourceURLs:(NSArray *)sourceURLs toURL:(NSURL *)toURL completed:(void (^)(NSError *error))completed;

+ (void)combineSourceURL:(NSURL *)sourceURL withLoopCount:(NSUInteger)count toURL:(NSURL *)toURL completed:(void (^)(NSError *error))completed;

+ (void)combineSourceURL:(NSURL *)sourceURL toTotalDuration:(CMTime)totalDuration frontClip:(CMTime)clipTime toURL:(NSURL *)toURL completed:(void (^)(NSError *error))completed;
@end
