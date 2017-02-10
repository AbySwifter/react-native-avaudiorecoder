import React, {
  PropTypes
} from 'react';
import {
   NativeModules,
   NativeEventEmitter,
   DeviceEventEmitter,
   Platform,
 } from 'react-native';
//本地对象
let TIMAudioRecorder = NativeModules.AudioRecorder;
const listener = Platform.OS == 'ios'?new NativeEventEmitter(TIMAudioRecorder):DeviceEventEmitter;
let instance = null;

class Recoder {
  static audioUpdaterListener;
  static peakInfo;
  constructor(){
    if(!instance){
      this.parpreRecoder = this.parpreRecoder.bind(this);
      this.play = this.play.bind(this);
      this.stopRecorder = this.stopRecorder.bind(this);
      this.startRecorder = this.startRecorder.bind(this);
      this.deleteCurrentRecord = this.deleteCurrentRecord.bind(this);
      this.peakInfo = {
        recordPeak:0,
        recordDB:0,
      };
      this.audioUpdaterListener = listener;
      this.listener=listener.addListener('onUpdateRecordPeak',(message)=>{
        this.peakInfo = message;
      });
      instance = this;
    }
    return instance;
  }
  /**
   * 准备录音
   */
  parpreRecoder(){
    return TIMAudioRecorder.parpreRecoder();
  }

  /**
   * 开始录音
   */
  startRecorder(callback){
    TIMAudioRecorder.startRecorder(callback);
  }
  /**
   * 停止录音
   */
  stopRecorder(callback){
    TIMAudioRecorder.stopRecorder(callback);
  }

  /**
   * 删除当前录制的录音
   */
  deleteCurrentRecord(callback){
    TIMAudioRecorder.deleteRecord(null,callback);
  }
  /**
   * 播放音乐
   */
  play(path,callback){
     TIMAudioRecorder.play(path,callback);
  }
}

// let AudioRecorder = {
//   audioUpdaterListener:listener,
//   startRecorder:startRecorder,
//   stopRecorder:stopRecorder,
// }

// module.exports = AudioRecorder;
// module.exports = Recoder;
export default Recoder;