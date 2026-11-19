package com.englishtok.app;

import android.os.Bundle;

import com.getcapacitor.BridgeActivity;
import androidx.work.ExistingPeriodicWorkPolicy;
import androidx.work.PeriodicWorkRequest;
import androidx.work.WorkManager;
import java.util.concurrent.TimeUnit;

public class MainActivity extends BridgeActivity {

    @Override
    public void onCreate(Bundle savedInstanceState) {
        registerPlugin(SpeechRecognitionPlugin.class);
        registerPlugin(TextToSpeechPlugin.class);
        registerPlugin(ProgressBackupPlugin.class);
        registerPlugin(ApkDownloaderPlugin.class);
        super.onCreate(savedInstanceState);

        // Request notification permission on Android 13+.
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            if (checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS)
                    != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                requestPermissions(new String[]{android.Manifest.permission.POST_NOTIFICATIONS}, 1001);
            }
        }

        // Schedule a periodic background check for new Lin Go updates.
        try {
            PeriodicWorkRequest request =
                    new PeriodicWorkRequest.Builder(UpdateCheckWorker.class, 6, TimeUnit.HOURS)
                            .build();
            WorkManager.getInstance(this).enqueueUniquePeriodicWork(
                    "lingo_update_check",
                    ExistingPeriodicWorkPolicy.KEEP,
                    request
            );
        } catch (Exception ignored) { }

        // Schedule a periodic background poll for friend messages.
        try {
            PeriodicWorkRequest request =
                    new PeriodicWorkRequest.Builder(FriendMessageWorker.class, 15, TimeUnit.MINUTES)
                            .build();
            WorkManager.getInstance(this).enqueueUniquePeriodicWork(
                    "lingo_friend_messages",
                    ExistingPeriodicWorkPolicy.KEEP,
                    request
            );
        } catch (Exception ignored) { }

        // Lesson audio is bundled with the app. Do not let WebView reject play()
        // calls that happen just after a user taps a speaker button.
        if (getBridge() != null && getBridge().getWebView() != null) {
            getBridge().getWebView().getSettings().setMediaPlaybackRequiresUserGesture(false);
        }
    }
}
