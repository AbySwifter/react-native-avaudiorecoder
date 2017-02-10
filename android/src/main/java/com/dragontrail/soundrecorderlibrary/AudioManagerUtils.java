package com.dragontrail.soundrecorderlibrary;

import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaPlayer;
import android.media.MediaRecorder;
import android.os.Environment;
import android.os.Handler;
import android.support.annotation.Nullable;
import android.util.Log;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableArray;

import java.io.File;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Timer;
import java.util.TimerTask;

/**
 * Created by boolean on 16-12-27.
 * Copyright © 2016 Dragontrail. All rights reserved.
 */
public class AudioManagerUtils {

    //文件路径
    private String mFilePath;
    //文件夹路径
    private String FolderPath;

    private MediaRecorder mMediaRecorder;
    private MediaPlayer mMediaPlayer;
    private final String TAG = "AudioManagerUtils";
    public static final int MAX_LENGTH = 1000 * 60;// 最大录音时长1000*60;

    static final int SAMPLE_RATE_IN_HZ = 8000;
    static final int BUFFER_SIZE = AudioRecord.getMinBufferSize(SAMPLE_RATE_IN_HZ,
            AudioFormat.CHANNEL_IN_DEFAULT, AudioFormat.ENCODING_PCM_16BIT);

    private OnAudioStatusUpdateListener audioStatusUpdateListener;
    private RecorderCallback mRecorderCallback;
    private AudioRecord mAudioRecord; //for calculating the mean amplitude

    public enum AudioStatus {
        UNKNOWN,
        RECORDING,
        RECORD_TIME_TOO_SHORT,
        RECORD_TIME_REACH_MAX,
        RECORD_FINISHED,
        RECORD_CANCELED,
        PLAYING
    }

    /**
     * 文件存储默认sdcard/record
     */
    private AudioManagerUtils(){

        //默认保存路径为/sdcard/record/下
        this(Environment.getExternalStorageDirectory()+"/record/");
    }

    private static AudioManagerUtils mAudioRecorderUtils = null;
    public static AudioManagerUtils getInstance() {
        if(mAudioRecorderUtils == null) {
            mAudioRecorderUtils = new AudioManagerUtils();
        }
        return mAudioRecorderUtils;
    }

    public AudioManagerUtils(String filePath) {

        File path = new File(filePath);
        if(!path.exists())
            path.mkdirs();

        this.FolderPath = filePath;
    }

    private long startTime;
    private long endTime;



    /**
     * 开始录音 使用amr格式
     *      录音文件
     * @return
     */
    public void startRecord(RecorderCallback callback) {
        this.mRecorderCallback = callback;
        // 开始录音
        /* ①Initial：实例化MediaRecorder对象 */
        if (mMediaRecorder == null)
            mMediaRecorder = new MediaRecorder();
            /*mAudioRecord = new AudioRecord(MediaRecorder.AudioSource.MIC,
                SAMPLE_RATE_IN_HZ, AudioFormat.CHANNEL_IN_DEFAULT,
                AudioFormat.ENCODING_PCM_16BIT, BUFFER_SIZE);*/
        try {
            /* ②setAudioSource/setVedioSource */
            mMediaRecorder.setAudioSource(MediaRecorder.AudioSource.MIC);// 设置麦克风
            /* ②设置音频文件的编码：AAC/AMR_NB/AMR_MB/Default 声音的（波形）的采样 */
            mMediaRecorder.setOutputFormat(MediaRecorder.OutputFormat.DEFAULT);
            /*
             * ②设置输出文件的格式：THREE_GPP/MPEG-4/RAW_AMR/Default THREE_GPP(3gp格式
             * ，H263视频/ARM音频编码)、MPEG-4、RAW_AMR(只支持音频且音频编码要求为AMR_NB)
             */
            mMediaRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB);

            SimpleDateFormat   formatter   =   new SimpleDateFormat("yyyy年MM月dd日 HH:mm:ss");
            Date curDate =  new Date(System.currentTimeMillis());
            String   str   =   formatter.format(curDate);
            mFilePath = FolderPath + str + ".amr" ;
            Log.d(TAG, "file path: " + mFilePath);
            /* ③准备 */
            mMediaRecorder.setOutputFile(mFilePath);
            mMediaRecorder.setMaxDuration(MAX_LENGTH);
            mMediaRecorder.prepare();
            /* ④开始 */
            mMediaRecorder.start();
            //mAudioRecord.startRecording();
            /* 获取开始时间* */
            startTime = System.currentTimeMillis();

            updateMicStatus();
            Log.e(TAG, "startTime" + startTime);
            mRecorderCallback.onSuccess(null, null);
        } catch (IllegalStateException e) {
            Log.i(TAG, "call startAmr(File mRecAudioFile) failed!" + e.getMessage());
            mRecorderCallback.onError(101, e.getMessage());
        } catch (IOException e) {
            Log.i(TAG, "call startAmr(File mRecAudioFile) failed!" + e.getMessage());
            mRecorderCallback.onError(102, e.getMessage());
        }
    }

    /**
     * 停止录音
     */
    public void stopRecord(RecorderCallback callback) {
        this.mRecorderCallback = callback;
        if (mMediaRecorder == null)
            return;
        endTime = System.currentTimeMillis();
        long duringTime = endTime - startTime;
        AudioStatus status = AudioStatus.UNKNOWN;
        if(duringTime < 500) {
            cancelRecord();
            callback.onError(103, "too short, recording canceled!");
            status = AudioStatus.RECORD_TIME_TOO_SHORT;
        }
        try {
            mMediaRecorder.stop();
            //mAudioRecord.stop();
        } catch (IllegalStateException e) {
            callback.onError(101, e.getLocalizedMessage());
        }
        mMediaRecorder.reset();
        mMediaRecorder.release();
        //mAudioRecord.release();
        //mAudioRecord = null;
        mMediaRecorder = null;
        mRecorderCallback.onSuccess(mFilePath, duringTime);

        mFilePath = ""; //empty the file path, prepare for next recording
    }

    /**
     * 取消录音
     */
    public void cancelRecord(){

        mMediaRecorder.stop();
        mMediaRecorder.reset();
        mMediaRecorder.release();
        mMediaRecorder = null;
        File file = new File(mFilePath);
        if (file.exists()) {
            file.delete();
        }
        mFilePath = "";

    }

    /**
     * 根据存放路径播放录音
     * @param url
     */
    public void playAudioWithUrl(String url) {
        mMediaPlayer = new MediaPlayer();
        try{
            mMediaPlayer.prepareAsync();
            mMediaPlayer.setDataSource(url);
            mMediaPlayer.start();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public void stopAudioPlay() {
        if(mMediaPlayer != null && mMediaPlayer.isPlaying()) {
            mMediaPlayer.stop();
            mMediaPlayer.release();
        }
    }

    private final Handler mHandler = new Handler();
    private Runnable mUpdateMicStatusTimer = new Runnable() {
        public void run() {
            updateMicStatus();
        }
    };


    private int BASE = 200;
    private int SPACE = 100;// 间隔取样时间

    public void setOnAudioStatusUpdateListener(OnAudioStatusUpdateListener audioStatusUpdateListener) {
        this.audioStatusUpdateListener = audioStatusUpdateListener;
    }

    /**
     * 更新麦克状态
     */
    private void updateMicStatus() {

        if (mMediaRecorder != null) {

            /*short[] buffer = new short[BUFFER_SIZE];

            //r是实际读取的数据长度，一般而言r会小于buffersize
            int r = mAudioRecord.read(buffer, 0, BUFFER_SIZE);
            Log.d(TAG, "r = " + r);
            long v = 0;
            // 将 buffer 内容取出，进行平方和运算
            for (int i = 0; i < buffer.length; i++) {
                v += buffer[i] * buffer[i];
            }
            Log.d(TAG, "v = " + v);
            // 平方和除以数据总长度，得到音量大小。
            double mean = v / (double) r;
            double ratio = 10 * Math.log10(mean);
            Log.d(TAG, "分贝值:" + ratio);
            */
            double ratio = (double)mMediaRecorder.getMaxAmplitude() / BASE;
            double db = 0;// 分贝
            if (ratio > 1) {
                db = 20 * Math.log10(ratio);
                if(null != audioStatusUpdateListener) {
                    audioStatusUpdateListener.onUpdate(db, generatePeak(db));
                }
            }

            mHandler.postDelayed(mUpdateMicStatusTimer, SPACE);
        }
    }

    private int generatePeak(double db) {
        double peakPower = Math.pow(10, (0.05*db));
        int peak = (int) ((peakPower*10)/20 + 1);
        if(peak < 1) {
            peak = 1;
        } else if(peak >5) {
            peak = 5;
        }
        return peak;
    }

    public interface OnAudioStatusUpdateListener {
        /**
         * 录音中...
         * @param db 当前声音分贝
         */
        public void onUpdate(double db, int peak);
    }

    public interface RecorderCallback {
        public void onError(int code, String msg);
        public void onSuccess(@Nullable String path, @Nullable Long duration);
    }

    public static WritableArray createErrMsg(int code, String msg) {
        WritableArray errMsg = Arguments.createArray();
        errMsg.pushInt(code);
        errMsg.pushString(msg);
        return errMsg;
    }
}
