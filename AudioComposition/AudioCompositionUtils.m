//
// Created by 吕晴阳 on 2018/10/17.
// Copyright (c) 2018 Lv Qingyang. All rights reserved.
//

#import "AudioCompositionUtils.h"


@implementation AudioCompositionUtils {

}

/// 合并音频文件
/// @param sourceURLs 需要合并的多个音频文件
/// @param toURL      合并后音频文件的存放地址
/// 注意:导出的文件是:m4a格式的.
+ (void)combineSourceURLs:(NSArray *)sourceURLs toURL:(NSURL *)toURL completed:(void (^)(NSError *error))completed {
    if (!sourceURLs || sourceURLs.count < 1) {
        completed([NSError errorWithDomain:@"sourceURLs should more than one" code:nil userInfo:nil]);
        return;
    }

//  1. 创建`AVMutableComposition `,用于合并所有的音视频文件
    AVMutableComposition *mixComposition = [AVMutableComposition composition];


//  2. 给`AVMutableComposition` 添加一个新音频的轨道,并返回音频轨道
    AVMutableCompositionTrack *compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
//  3. 循环添加需要的音频资源

//  3.1 音频插入的开始时间,用于记录每次添加音频文件的开始时间
    CMTime beginTime = kCMTimeZero;
//  3.2 用于记录错误的对象
    NSError *error = nil;
//  3.3 循环添加音频资源
    for (NSURL *sourceURL in sourceURLs) {
//      3.3.1 音频文件资源
        AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:sourceURL.filePathURL options:nil];
//      3.3.2 需要合并的音频文件的播放的时间区间
        CMTimeRange audio_timeRange = CMTimeRangeMake(kCMTimeZero, audioAsset.duration);
        //      3.3.3 添加音频文件
//      参数说明:
        //      insertTimeRange:源录音文件的的区间
        //      ofTrack:插入音 频的内容
        //      atTime:源音频插入到目标文件开始时间
        //      error: 插入失败记录错误
        //      返回:YES表示插入成功,`NO`表示插入失败
        BOOL success = [compositionAudioTrack insertTimeRange:audio_timeRange ofTrack:[self getTrackWithAsset:audioAsset] atTime:beginTime error:&error];
//      3.3.4 如果插入失败,打印插入失败信息
        if (!success) {
            completed(error);
            return;
        }
        //     3.3.5  记录下次音频文件插入的开始时间
        beginTime = CMTimeAdd(beginTime, audioAsset.duration);
    }

    [self exportAudioWithComposition:mixComposition toURL:toURL completed:completed];
}

//循环一段音频指定次数输出
+ (void)combineSourceURL:(NSURL *)sourceURL withLoopCount:(NSUInteger)count toURL:(NSURL *)toURL completed:(void (^)(NSError *error))completed {
    if (count < 2) {
        completed([NSError errorWithDomain:@"loopCount should more than one" code:nil userInfo:nil]);
        return;
    }

    AVMutableComposition *mixComposition = [AVMutableComposition composition];
    AVMutableCompositionTrack *compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    NSError *error = nil;
    AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:sourceURL.filePathURL options:nil];
    CMTime duration = audioAsset.duration;
    CMTimeRange audio_timeRange = CMTimeRangeMake(kCMTimeZero, duration);
    for (int i = 0; i < count; i++) {
        BOOL success = [compositionAudioTrack insertTimeRange:audio_timeRange ofTrack:[self getTrackWithAsset:audioAsset] atTime:CMTimeMultiply(duration, i) error:&error];
        if (!success) {
            completed(error);
            return;
        }
    }

    [self exportAudioWithComposition:mixComposition toURL:toURL completed:completed];
}

+ (void)combineSourceURL:(NSURL *)sourceURL toTotalDuration:(CMTime)totalDuration frontClip:(CMTime)clipTime toURL:(NSURL *)toURL completed:(void (^)(NSError *error))completed {
    AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:sourceURL.filePathURL options:nil];
    CMTime duration = audioAsset.duration;

    //判断头部裁剪时间是否小于音频长度
    if (CMTimeCompare(duration, clipTime) < 0) {
        completed([NSError errorWithDomain:@"frontClip should less than the audio's duration" code:nil userInfo:nil]);
        return;
    }

    AVMutableComposition *mixComposition = [AVMutableComposition composition];
    AVMutableCompositionTrack *compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    NSError *error = nil;

    //先添加首段被裁减的音频
    CMTimeRange audio_timeRange = CMTimeRangeMake(clipTime, audioAsset.duration);
    BOOL success = [compositionAudioTrack insertTimeRange:audio_timeRange ofTrack:[self getTrackWithAsset:audioAsset] atTime:kCMTimeZero error:&error];
    if (!success) {
        completed(error);
        return;
    }

    //后面循环的音频
    CMTime curDuration = CMTimeSubtract(duration, clipTime);
    audio_timeRange = CMTimeRangeMake(kCMTimeZero, audioAsset.duration);
    for (; CMTimeCompare(curDuration, totalDuration) < 0; curDuration = CMTimeAdd(curDuration, duration)) {
        BOOL success = [compositionAudioTrack insertTimeRange:audio_timeRange ofTrack:[self getTrackWithAsset:audioAsset] atTime:curDuration error:&error];
        if (!success) {
            completed(error);
            return;
        }
    }

    //裁剪后面多余的音频
    if (CMTimeCompare(curDuration, totalDuration) > 0) {
        [compositionAudioTrack removeTimeRange:CMTimeRangeMake(totalDuration, CMTimeSubtract(curDuration, totalDuration))];
    }

    [self exportAudioWithComposition:mixComposition toURL:toURL completed:completed];
}

+ (void)exportAudioWithComposition:(AVMutableComposition *)mixComposition toURL:(NSURL *)toURL completed:(void (^)(NSError *error))completed {
    //如果对应文件存在则先删除
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:toURL.path]) {
        [fileManager removeItemAtURL:toURL error:&error];
        if (error) {
            completed(error);
            return;
        }
    }

//  4. 导出合并的音频文件
//  4.0 创建一个导入M4A格式的音频的导出对象
    AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetAppleM4A];
//  4.2 设置导入音视频的URL
    assetExport.outputURL = toURL.filePathURL;
//  导出音视频的文件格式
    assetExport.outputFileType = AVFileTypeAppleM4A;
//  优化网络
    assetExport.shouldOptimizeForNetworkUse = YES;
//  4.3 导入出
    [assetExport exportAsynchronouslyWithCompletionHandler:^{
//      4.5 分发到主线程
        dispatch_async(dispatch_get_main_queue(), ^{
            completed(assetExport.error);
        });
    }];
}

+ (AVAssetTrack *)getTrackWithAsset:(AVAsset *)asset {
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeAudio];
    return tracks.count > 0 ? tracks[0] : nil;
}

+ (void)logTime:(CMTime)time {
    NSLog(@"[%@ %s] %lld/%d", self.class, sel_getName(_cmd), time.value, time.timescale);
}

@end