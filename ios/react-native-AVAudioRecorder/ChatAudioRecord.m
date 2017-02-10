//
//  ChatAudioRecord.m
//  AVAudioRecode
//
//  Created by Bear on 2016/11/23.
//  Copyright © 2016年 dragontrail. All rights reserved.
//

#import "ChatAudioRecord.h"
#import <UIKit/UIKit.h>

#define kChatRecordMaxDuration 60

@interface ChatAudioRecord ()<AVAudioRecorderDelegate>

@property(nonatomic,copy)finishedPlay finishPlay;

@end

@implementation ChatAudioRecord

static ChatAudioRecord* _sharedInstance = nil;

+(instancetype)sharedInstance{

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.recordPeak = 1;
        self.recordDuration = 0;
    }
    return self;
}
/**
 开始录音准备
 */
-(void)startRecord:(isParpreRecoder)parpre{

    //检查麦克风权限
    AVAudioSession* avSession = [AVAudioSession sharedInstance];
    if ([avSession respondsToSelector:@selector(requestRecordPermission:)]) {
        //TODO:开始录音ing
        [avSession requestRecordPermission:^(BOOL granted) {
            parpre(granted);
        }];
    }

}

/**
 开始录音
 */
-(NSMutableDictionary*)startRecording{
    NSMutableDictionary* errMsg = [NSMutableDictionary dictionary];
    //TODO:如果录制时间太短，则警告并中段录制
    if (self.recorderState == EChatRecorder_TooShort)
    {
        [errMsg setObject:@1 forKey:@"EChatRecorder_TooShort"];
        return errMsg;
    }
    [self.recoder stop];
    if (![self initRecord]) {
        //FIXME:这里可以弹出UI表示初始化录音机失败
        [errMsg setObject:@1 forKey:@"initRecordErr"];
        return errMsg;
    }
    [self.recoder record];//开始录音了
    self.recordPeak = 1;//出初始化音量大小
    self.recordDuration = 0;//清空录音时间
    self.recorderState = EChatRecorder_Recoring;//设置状态为正在录音
    self.recoderTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(onRecording) userInfo:nil repeats:YES];//每隔一秒调用一次正在录音的方法
    [[NSRunLoop currentRunLoop] addTimer:self.recoderTimer forMode:NSRunLoopCommonModes];
    self.recoderPeakTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(onRecordPeak) userInfo:nil repeats:YES];//每隔0.2秒调用监控声音的方法
    [[NSRunLoop currentRunLoop] addTimer:self.recoderPeakTimer forMode:NSRunLoopCommonModes];
    return errMsg;
}

-(NSMutableDictionary*)stopRecord{
    NSMutableDictionary* errMsg = [NSMutableDictionary dictionary];
    //停用计时器
    [self.recoderTimer invalidate];
    self.recoderTimer = nil;
    [self.recoderPeakTimer invalidate];
    self.recoderPeakTimer = nil;

    NSTimeInterval duration = self.recoder.currentTime;

    if (self.recorderState == EChatRecorder_RelaseCancel)
    {
        // TODO:取消发送的功能
        self.recorderState = EChatRecorder_Stoped;
        return errMsg;
    }

    if (duration<0.5) {
        DebugLog(@"录音太短");
        self.recorderState = EChatRecorder_TooShort;
        [errMsg setObject:@1 forKey:@"EChatRecorder_TooShort"];
    }
    else
    {
        [self.recoder stop];
        //取出录音文件的操作
    }
    //延时操作
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.recorderState = EChatRecorder_Stoped;
    });
    [self.recoder stop];
    return errMsg;

}
/**
 初始化录音机

 @return 是否初始化成功
 */
-(BOOL)initRecord{
    //录音设置
    NSMutableDictionary* recordSetting = [NSMutableDictionary dictionaryWithCapacity:2];
    //设置录音格式
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    //设置录音采样率
    [recordSetting setValue:[NSNumber numberWithFloat:44100] forKey:AVSampleRateKey];
    //录音通道数 1 或 2
    [recordSetting setValue:[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];
    //线性采样位数 8、16、24、32
    [recordSetting setValue:[NSNumber numberWithInt:15] forKey:AVLinearPCMBitDepthKey];
    //录音的质量
    [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];

    //设置初始的文件存储路径
    NSString* strUrl = [NSString stringWithFormat:@"%@/Dingla_%@.mp4",[NSString cachePatch],[NSString uuid]];
    NSURL* url = [NSURL fileURLWithPath:strUrl];

    self.recordSavePath = strUrl;//设置文件的存储路径
    NSError* error = nil;
    //初始化
    self.recoder = [[AVAudioRecorder alloc] initWithURL:url settings:recordSetting error:&error];
    //开启音量检测
    self.recoder.meteringEnabled = YES;
    self.recoder.delegate = self;
    if ([self.recoder prepareToRecord]) {
        return YES;
    }
    DebugLog(@"录音初始化失败");
    return NO;
}

//录音计时的方法
-(void)onRecording{
    self.recordDuration++;
    DebugLog(@"000000000000000000000000000000");

    if (self.recordDuration == kChatRecordMaxDuration) {
        //TODO:置空定时器
        [self.recoderTimer invalidate];
        self.recoderTimer = nil;
        [self.recoderPeakTimer invalidate];
        self.recoderPeakTimer = nil;
        //停止录制
        self.recorderState = EChatRecorder_MaxRecord;
        [self stopRecord];
        if (self.delegate&&[self.delegate respondsToSelector:@selector(stopRecordBecauseTiomOut)]) {
            [self.delegate stopRecordBecauseTiomOut];
        }
    }
    else if (self.recordDuration >= 50){
        self.recorderState = EChatRecorder_Countdown;
        //发出开始倒计时的信息
    }
    else if (self.recordDuration == 1){
        //预备添加语音消息到界面，大于一秒了
    }
}


/**
 实时的监控录音音量
 */
- (void)onRecordPeak
{
    [self.recoder updateMeters];

    CGFloat peakPower = 0;
    peakPower = [self.recoder peakPowerForChannel:0];
    self.recordDB = peakPower;
    peakPower = pow(10, (0.05 * peakPower));
    NSInteger peak = (NSInteger)((peakPower * 100)/20 + 1);
    if (peak < 1)
    {
        peak = 1;
    }
    else if (peak > 5)
    {
        peak = 5;
    }
    if (peak != self.recordPeak)
    {
        self.recordPeak = peak;
    }
    NSDictionary* dic = @{@"recordDB":@(self.recordDB),@"recordPeak":@(self.recordPeak)};
    if (self.onUpDatePeak != nil) {
        self.onUpDatePeak(dic);
    }

}

//在按钮事件中有dragonOut的方法，表示用户即将上滑动取消。
- (void)willCancelRecord
{
    if (_recordDuration > 50)
    {
        self.recorderState = EChatRecorder_Countdown;
    }
    else
    {
        self.recorderState = EChatRecorder_RelaseCancel;
    }
}

//当用户有决定继续录制的时候。
- (void)continueRecord
{
    if (_recordDuration > 50)
    {
        self.recorderState = EChatRecorder_Countdown;
    }
    else
    {
        self.recorderState = EChatRecorder_Recoring;
    }
}

/**
 删除当前录音文件的方法

 @return 是否删除成功
 */
-(BOOL)deleteMsg{
    return [self deleteMsgWithPath:self.recoder.url.path];
}


/**
 删除录音文件

 @param path 文件路径
 @return 返回是否删除成功的方法
 */
-(BOOL)deleteMsgWithPath:(NSString*)path{
    //    用完即删除
    if ([[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        if (!self.recoder.recording)
        {
            [self.recoder deleteRecording];
            return YES;
        }
        return NO;
    };
    return NO;
}
/**
 播放语音

 @param url 文件路径
 */
-(void)playAudioWithUrl:(NSString*)url finished:(finishedPlay)finish{
    self.player = nil;
    NSURL* fileUrl = [NSURL fileURLWithPath:url];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileUrl error:nil];
    self.player.delegate = self;
    self.finishPlay = finish;
    if (self.player) {
        [self.player prepareToPlay];
        [self.player play];

    }

}

#pragma mark - AVAudioPlayerDelegate
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    self.finishPlay(flag);
}

#pragma mark - AVAudioRecorderDelegate 代理方法
-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    //TODO:录制成功且完毕的处理
    DebugLog(@"录制完毕");
}

-(void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error{
    //TODO:发生录制错误的处理
    DebugLog(@"发生录制错误");
}
@end
