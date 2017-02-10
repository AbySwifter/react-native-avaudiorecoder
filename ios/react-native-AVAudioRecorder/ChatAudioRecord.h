//
//  ChatAudioRecord.h
//  AVAudioRecode
//
//  Created by Bear on 2016/11/23.
//  Copyright © 2016年 dragontrail. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "DebugLog.h"
#import "NSString+file.h"


/**
 描述录音状态的枚举值

 - EChatRecorder_Stoped: 录音停止
 - EChatRecorder_Recoring: 正在录音
 - EChatRecorder_RelaseCancel: 录音取消并释放
 - EChatRecorder_Countdown: 录音即将到大最大时长
 - EChatRecorder_MaxRecord: 达到最大时间长度的录音
 - EChatRecorder_TooShort: 录音太短
 */
typedef NS_ENUM(NSInteger, ChatRecorderState)
{
    EChatRecorder_Stoped,
    EChatRecorder_Recoring,
    EChatRecorder_RelaseCancel,
    EChatRecorder_Countdown,
    EChatRecorder_MaxRecord,
    EChatRecorder_TooShort,
};

typedef void(^onUpDatePeakBlock)(NSDictionary* recorPeakInfo);
typedef void(^finishedPlay)(BOOL succ);
@protocol ChatAudioRecordDelegate <NSObject>

@optional
-(void)stopRecordBecauseTiomOut;
//-(void)onUpdateRecordPeak:(NSDictionary*)recordPeakInfo;

@end


@interface ChatAudioRecord : NSObject<AVAudioPlayerDelegate>

@property(nonatomic,retain)AVAudioSession *session;//控制app的音频播放和相关处理
@property(nonatomic,retain)AVAudioRecorder* recoder;//录音器
@property(nonatomic,retain)AVAudioPlayer* player;//播放器
@property(nonatomic,retain)NSTimer* recoderTimer;//录音计时器
@property(nonatomic,retain)NSTimer* recoderPeakTimer;//音量监听器
@property(nonatomic,retain)NSString* recordSavePath;//录音存储路径
@property(nonatomic,assign)NSInteger recordDuration;//本次录音的时长
@property(nonatomic,assign)NSInteger recordPeak;//录音音量等级
@property(nonatomic,assign)CGFloat recordDB;//录音分贝
@property(nonatomic,assign)ChatRecorderState recorderState;//录音状态
@property(nonatomic,assign)id <ChatAudioRecordDelegate> delegate;//代理
@property(nonatomic,copy)onUpDatePeakBlock onUpDatePeak;

+(instancetype)sharedInstance;//单例设计模式控制录音

-(void)startRecord:(isParpreRecoder)parpre;//开始录音准备
-(NSMutableDictionary*)startRecording;//开始录音
-(void)willCancelRecord;
-(void)continueRecord;
-(NSMutableDictionary*)stopRecord;//停止录音

-(BOOL)deleteMsg;
-(void)playAudioWithUrl:(NSString*)url finished:(finishedPlay)finish;
@end
