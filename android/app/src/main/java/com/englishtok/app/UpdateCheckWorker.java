package com.englishtok.app;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;

import androidx.annotation.NonNull;
import androidx.core.app.NotificationCompat;
import androidx.work.Worker;
import androidx.work.WorkerParameters;

import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;

/**
 * Periodic background check for a new Lin Go Gold release. When a newer
 * version is published, posts a system notification (with sound) that opens
 * the app; the in-app updater then downloads and installs it.
 */
public class UpdateCheckWorker extends Worker {
    private static final String CHANNEL_ID = "lingo_updates";
    private static final String MANIFEST_URL = "https://englishtok-eight.vercel.app/download/gold-latest.json";

    public UpdateCheckWorker(@NonNull Context context, @NonNull WorkerParameters params) {
        super(context, params);
    }

    @NonNull
    @Override
    public Result doWork() {
        try {
            String json = fetch(MANIFEST_URL);
            if (json == null) return Result.success();
            JSONObject manifest = new JSONObject(json);
            String latestVersion = manifest.optString("version", "");
            if (latestVersion.isEmpty()) return Result.success();

            String installedVersion = getInstalledVersion();
            if (installedVersion == null || compareVersions(latestVersion, installedVersion) <= 0) {
                return Result.success();
            }

            postNotification(latestVersion);
            return Result.success();
        } catch (Exception ignored) {
            return Result.retry();
        }
    }

    private String fetch(String urlStr) {
        HttpURLConnection conn = null;
        try {
            URL url = new URL(urlStr);
            conn = (HttpURLConnection) url.openConnection();
            conn.setConnectTimeout(15000);
            conn.setReadTimeout(15000);
            conn.setRequestProperty("Cache-Control", "no-cache");
            if (conn.getResponseCode() != 200) return null;
            BufferedReader reader = new BufferedReader(new InputStreamReader(conn.getInputStream()));
            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) sb.append(line);
            reader.close();
            return sb.toString();
        } catch (Exception e) {
            return null;
        } finally {
            if (conn != null) conn.disconnect();
        }
    }

    private String getInstalledVersion() {
        try {
            PackageInfo info = getApplicationContext().getPackageManager()
                    .getPackageInfo(getApplicationContext().getPackageName(), 0);
            return info.versionName;
        } catch (PackageManager.NameNotFoundException e) {
            return null;
        }
    }

    private int compareVersions(String a, String b) {
        String[] pa = a.split("\\.");
        String[] pb = b.split("\\.");
        int n = Math.max(pa.length, pb.length);
        for (int i = 0; i < n; i++) {
            int va = i < pa.length ? parseIntOrZero(pa[i]) : 0;
            int vb = i < pb.length ? parseIntOrZero(pb[i]) : 0;
            if (va != vb) return Integer.compare(va, vb);
        }
        return 0;
    }

    private int parseIntOrZero(String s) {
        try { return Integer.parseInt(s.replaceAll("[^0-9]", "")); }
        catch (Exception e) { return 0; }
    }

    private void postNotification(String version) {
        Context ctx = getApplicationContext();
        NotificationManager manager = (NotificationManager) ctx.getSystemService(Context.NOTIFICATION_SERVICE);
        if (manager == null) return;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    CHANNEL_ID,
                    "تحديثات Lin Go",
                    NotificationManager.IMPORTANCE_DEFAULT
            );
            channel.setDescription("إشعارات التحديثات الجديدة");
            manager.createNotificationChannel(channel);
        }

        Intent launch = ctx.getPackageManager().getLaunchIntentForPackage(ctx.getPackageName());
        if (launch == null) return;
        launch.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
        PendingIntent pending = PendingIntent.getActivity(
                ctx, 0, launch,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
        );

        NotificationCompat.Builder builder = new NotificationCompat.Builder(ctx, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.stat_sys_download_done)
                .setContentTitle("تحديث Lin Go متوفر")
                .setContentText("الإصدار " + version + " جاهز للتثبيت. افتح التطبيق للتحديث.")
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setAutoCancel(true)
                .setContentIntent(pending);

        manager.notify(1001, builder.build());
    }
}
