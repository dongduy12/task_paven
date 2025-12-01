package com.paven_task.task_paven;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import java.util.TimeZone;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "task_paven/timezone";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if ("getLocalTimezone".equals(call.method)) {
                        result.success(TimeZone.getDefault().getID());
                    } else {
                        result.notImplemented();
                    }
                });
    }
}
