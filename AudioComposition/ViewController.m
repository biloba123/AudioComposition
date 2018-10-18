//
//  ViewController.m
//  AudioComposition
//
//  Created by 吕晴阳 on 2018/10/17.
//  Copyright © 2018 Lv Qingyang. All rights reserved.
//

#import "ViewController.h"
#import "AudioCompositionUtils.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()
@property(weak, nonatomic) IBOutlet UILabel *stateLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (IBAction)combineDiffAudios:(id)sender {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *toUrl = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/test.m4a", fileManager.temporaryDirectory.path]];
    NSLog(@"[%@ %s] %@", self.class, sel_getName(_cmd), toUrl);
    [self showInfo:@"合并..."];
    [AudioCompositionUtils combineSourceURLs:[self sourceURLs] toURL:toUrl completed:^(NSError *error) {
        if (!error) {
            [self showInfo:[NSString stringWithFormat:@"成功：%@", toUrl]];
            [self playAudioAtURL:toUrl];
        } else {
            NSLog(@"[%@ %s] %@", self.class, sel_getName(_cmd), error);
            [self showInfo:@"失败"];
        }
    }];
}

- (IBAction)combineAudioSomeTimes:(id)sender {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *toUrl = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/loop.m4a", fileManager.temporaryDirectory.path]];
    NSLog(@"[%@ %s] %@", self.class, sel_getName(_cmd), toUrl);
    [self showInfo:@"合并..."];
    [AudioCompositionUtils combineSourceURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"m1" ofType:@"mp3"]]
                              withLoopCount:5
                                      toURL:toUrl
                                  completed:^(NSError *error) {
                                      if (!error) {
                                          [self showInfo:[NSString stringWithFormat:@"成功：%@", toUrl]];
                                          [self playAudioAtURL:toUrl];
                                      } else {
                                          NSLog(@"[%@ %s] %@", self.class, sel_getName(_cmd), error);
                                          [self showInfo:@"失败"];
                                      }
                                  }];
}

- (IBAction)clipAndCombine:(id)sender {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *toUrl = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/clip_loop.m4a", fileManager.temporaryDirectory.path]];
    NSLog(@"[%@ %s] %@", self.class, sel_getName(_cmd), toUrl);
    [self showInfo:@"合并..."];
    NSDate *before= [NSDate date];
    [AudioCompositionUtils combineSourceURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"m4" ofType:@"mp3"]]
                            toTotalDuration:CMTimeMake(48000 * 60, 48000)
                                  frontClip:CMTimeMake(48000 * 10, 48000)
                                      toURL:toUrl
                                  completed:^(NSError *error) {
                                      if (!error) {
                                          NSLog(@"[%@ %s] %f", self.class, sel_getName(_cmd), [[NSDate date] timeIntervalSinceDate:before]);
                                          [self showInfo:[NSString stringWithFormat:@"成功：%@", toUrl]];
                                          [self playAudioAtURL:toUrl];
                                      } else {
                                          NSLog(@"[%@ %s] %@", self.class, sel_getName(_cmd), error);
                                          [self showInfo:@"失败"];
                                      }
                                  }];

}

- (NSArray *)sourceURLs {
    NSMutableArray *urls = [NSMutableArray new];
    for (NSString *name in @[@"m1", @"m2", @"m3"]) {
        [urls addObject:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:name ofType:@"mp3"]]];
    }

    return urls;
}

- (void)showInfo:(NSString *)info {
    self.stateLabel.text = info;
}

- (void)playAudioAtURL:(NSURL *)url {
    NSError *error = nil;
    AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url fileTypeHint:AVFileTypeAppleM4A error:&error];
    if (error) {
        NSLog(@"[%@ %s] %@", self.class, sel_getName(_cmd), error);
        return;
    }
    [audioPlayer prepareToPlay];
    [audioPlayer play];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
