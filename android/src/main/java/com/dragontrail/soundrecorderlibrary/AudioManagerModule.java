package com.dragontrail.soundrecorderlibrary;

import android.util.Log;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

/**
 * Created by boolean on 16-12-26.
 * Copyright © 2016 Dragontrail. All rights reserved.
 */
public class AudioManagerModule extends ReactContextBaseJavaModule {

    private final String TAG = "AudioManagerModule";


    public AudioManagerModule(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @Override
    public String getName() {
        return "AudioRecorder";
    }

    @ReactMethod
    public void startRecorder(final Callback callback) {
        AudioManagerUtils utils = AudioManagerUtils.getInstance();
        utils.startRecord(new AudioManagerUtils.RecorderCallback() {
            @Override
            public void onError(int code, String msg) {
                callback.invoke(AudioManagerUtils.createErrMsg(code, msg));
            }

            @Override
            public void onSuccess(String path, Long duration) {
                callback.invoke(null, "start success");
            }
        });
        //录音回调
        utils.setOnAudioStatusUpdateListener(new AudioManagerUtils.OnAudioStatusUpdateListener() {

            /**
             * update the recording state
             * @param db 当前声音分贝
             */
            @Override
            public void onUpdate(double db, int peak) {
                Log.e(TAG, "the current spl is " + db + "|||||peak is" + peak);
                WritableMap map = Arguments.createMap();
                map.putDouble("recordDB",db);
                map.putInt("reacordPeak", peak);
                // report(emit) to JS, JS part should add listener
                getReactApplicationContext()
                        .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                        .emit("onUpdateRecordPeak", map);
            }

        });

    }

    @ReactMethod
    public void stopRecorder(final Callback callback) {
        AudioManagerUtils.getInstance().stopRecord(new AudioManagerUtils.RecorderCallback() {
            @Override
            public void onError(int code, String msg) {
                callback.invoke(AudioManagerUtils.createErrMsg(code, msg));
            }

            @Override
            public void onSuccess(String path, Long duration) {
                WritableMap map = Arguments.createMap();
                Log.d(TAG, "duration is" + duration);
                map.putInt("duration", duration.intValue());
                map.putString("path", path);
                map.putString("absoluteUrl", null);
                callback.invoke(null, map);
            }
        });
    }

    @ReactMethod
    public void deleteRecord(final Callback callback) {

    }

    @ReactMethod
    public void play(String url) {
        //need message id
        AudioManagerUtils utils = AudioManagerUtils.getInstance();
        utils.playAudioWithUrl(url);
    }

    @ReactMethod
    public void willCancelRecord() {

    }

    @ReactMethod
    public void continueRecord() {

    }

}
