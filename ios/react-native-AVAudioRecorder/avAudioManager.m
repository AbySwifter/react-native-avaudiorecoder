//
//  avAudioManager.m
//  react-native-AVAudioRecorder
//
//  Created by Bear on 2016/11/24.
//  Copyright © 2016年 dragontrail. All rights reserved.
//

#import "avAudioManager.h"
#import "ChatAudioRecord.h"
#import "DebugLog.h"

@interface avAudioManager ()<ChatAudioRecordDelegate>

@property(nonatomic, retain)ChatAudioRecord* recorder;

@end

@implementation avAudioManager

-(ChatAudioRecord *)recorder{

    return [ChatAudioRecord sharedInstance];
}

RCT_EXPORT_MODULE(AudioRecorder);

RCT_EXPORT_METHOD(selfDescription:(RCTResponseSenderBlock)callBack){

    callBack(@[@"我是录音管理员"]);
}


RCT_EXPORT_METHOD(parpreRecoder:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject){
    __weak avAudioManager* weakSelf = self;
    if (self.recorder.onUpDatePeak != nil) {
        self.recorder.onUpDatePeak = nil;

    }
    self.recorder.onUpDatePeak = ^(NSDictionary* peakInfo){
        [weakSelf onUpdateRecordPeak:peakInfo];
    };
    [self.recorder startRecord:^(BOOL granted) {
        if (granted) {
            resolve(@YES);
        }else{
            reject(@"1222",@"没有麦克风权限",nil);
        }
    }];
}


RCT_EXPORT_METHOD(startRecorder:(RCTResponseSenderBlock)callBack){
    //开始录音
    NSDictionary* dictionary = [self.recorder startRecording];
    NSInteger count = dictionary.count;
    if (!count) {

        callBack(@[[NSNull null],@"success"]);
    }else{
        callBack(@[dictionary,@"failed"]);
    }
}

RCT_EXPORT_METHOD(stopRecorder:(RCTResponseSenderBlock)callBack){
    //停止录音
    NSDictionary* errMsg = [self.recorder stopRecord];
    if (errMsg.count == 0) {
        NSMutableDictionary* msg = [NSMutableDictionary dictionary];
        [msg setObject:@(self.recorder.recordDuration) forKey:@"duration"];
        [msg setObject:self.recorder.recordSavePath forKey:@"path"];
        NSURL* url = [NSURL fileURLWithPath:self.recorder.recordSavePath];
        [msg setObject:[url absoluteString] forKey:@"absoluteUrl"];
        callBack(@[[NSNull null],msg]);
    }else{
        callBack(@[errMsg,[NSNull null]]);
    }
}

RCT_EXPORT_METHOD(willCancelRecord){
    //TODO:将要取消录音
    [self.recorder willCancelRecord];
}

RCT_EXPORT_METHOD(continueRecord){
    //TODO:将要继续录音
    [self.recorder continueRecord];
}

RCT_EXPORT_METHOD(deleteRecord:(NSString*)path callback:(RCTResponseSenderBlock)callback){

    BOOL result = [self.recorder deleteMsg];
    NSString* msg = result?@"success":@"fail";
    callback(@[[NSNull null],msg]);
}

-(void)stopRecordBecauseTiomOut{
    NSMutableDictionary* msg = [NSMutableDictionary dictionary];
    [msg setObject:@(self.recorder.recordDuration) forKey:@"duration"];
    [msg setObject:self.recorder.recordSavePath forKey:@"path"];
    NSURL* url = [NSURL fileURLWithPath:self.recorder.recordSavePath];
    [msg setObject:[url absoluteString] forKey:@"absoluteUrl"];
    [self sendEventWithName:@"stopRecordBecauseTiomOut" body:msg ];
}

-(void)onUpdateRecordPeak:(NSDictionary*)dic{
    [self sendEventWithName:@"onUpdateRecordPeak" body:dic];
}

RCT_EXPORT_METHOD(play:(NSString*)path callback:(RCTResponseSenderBlock)callback){

    [self.recorder playAudioWithUrl:path finished:^(BOOL succ){
        callback(@[@(succ)]);
    }];
}

//发送超时停止录音的消息
-(NSArray<NSString *> *)supportedEvents{

    return @[@"stopRecordBecauseTiomOut",@"onUpdateRecordPeak"];
}

-(dispatch_queue_t)methodQueue{

    return dispatch_get_main_queue();
}
@end
