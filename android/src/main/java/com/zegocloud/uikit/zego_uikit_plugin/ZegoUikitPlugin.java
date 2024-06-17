package com.zegocloud.uikit.zego_uikit_plugin;

import android.app.ActivityManager;
import android.content.Context;
import android.content.IntentFilter;
import android.content.BroadcastReceiver;
import android.content.Intent;
import android.os.Build;
import android.util.Log;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import java.util.List;

/**
 * ZegoUikitPlugin
 */
public class ZegoUikitPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private MethodChannel methodChannel;
    private Context context;
    private ActivityPluginBinding activityBinding;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        Log.d("uikit plugin", "onAttachedToEngine");

        methodChannel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "zego_uikit_plugin");
        methodChannel.setMethodCallHandler(this);

        context = flutterPluginBinding.getApplicationContext();
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        Log.d("uikit plugin", "onMethodCall: " + call.method);

        if (call.method.equals(Defines.FLUTTER_API_FUNC_BACK_TO_DESKTOP)) {
            Boolean nonRoot = call.argument(Defines.FLUTTER_PARAM_NON_ROOT);

            backToDesktop(nonRoot);

            result.success(null);
        } else {
            result.notImplemented();
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        Log.d("uikit plugin", "onDetachedFromEngine");

        methodChannel.setMethodCallHandler(null);
    }


    @Override
    public void onAttachedToActivity(ActivityPluginBinding activityPluginBinding) {
        Log.d("uikit plugin", "onAttachedToActivity");

        activityBinding = activityPluginBinding;
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding activityPluginBinding) {
        Log.d("uikit plugin", "onReattachedToActivityForConfigChanges");

        activityBinding = activityPluginBinding;
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        Log.d("uikit plugin", "onDetachedFromActivityForConfigChanges");

        activityBinding = null;
    }

    @Override
    public void onDetachedFromActivity() {
        Log.d("uikit plugin", "onDetachedFromActivity");

        activityBinding = null;
    }

    public void backToDesktop(Boolean nonRoot) {
        Log.i("uikit plugin", "backToDesktop" + " nonRoot:" + nonRoot);

        try {
            activityBinding.getActivity().moveTaskToBack(nonRoot);
        } catch (Exception e) {
            Log.e("uikit plugin, backToDesktop", e.toString());
        }
    }
}