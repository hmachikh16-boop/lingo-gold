package com.englishtok.app;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Build;

import androidx.annotation.NonNull;
import androidx.core.app.NotificationCompat;
import androidx.work.Worker;
import androidx.work.WorkerParameters;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;

/**
 * Periodic background poller for friend messages. When a friend sends a new
 * message, posts a system notification (with sound) even if the app is closed.
 */
public class FriendMessageWorker extends Worker {
    private static final String CHANNEL_ID = "lingo_friends";
    private static final String PREFS = "lingo_friends";
    private static final String KEY_LAST = "last_messages";
    private static final String BASE = "https://englishtok-eight.vercel.app/api/admin";

    public FriendMessageWorker(@NonNull Context context, @NonNull WorkerParameters params) {
        super(context, params);
    }

    @NonNull
    @Override
    public Result doWork() {
        try {
            SharedPreferences prefs = getApplicationContext().getSharedPreferences(PREFS, Context.MODE_PRIVATE);
            String code = prefs.getString("friend_code", "");
            if (code == null || code.trim().isEmpty()) return Result.success();

            String url = BASE + "?action=friends_list&code=" + UriEncode(code)
                    + "&device=" + UriEncode("android");
            String json = fetch(url);
            if (json == null) return Result.retry();

            JSONObject payload = new JSONObject(json);
            JSONArray friends = payload.optJSONArray("friends");
            if (friends == null) return Result.success();

            String lastJson = prefs.getString(KEY_LAST, "{}");
            JSONObject last = new JSONObject(lastJson);
            JSONObject next = new JSONObject();

            for (int i = 0; i < friends.length(); i++) {
                JSONObject f = friends.optJSONObject(i);
                if (f == null) continue;
                String fCode = f.optString("code", "");
                String fLast = f.optString("lastMessage", "");
                String sender = f.optString("lastSenderCode", "");
                String name = f.optString("name", fCode);
                int unread = f.optInt("unread", 0);
                next.put(fCode, fLast);

                String prev = last.optString(fCode, null);
                boolean isNew = prev != null && !prev.equals(fLast) && !fLast.isEmpty()
                        && !normalize(sender).equals(normalize(code));
                if (isNew) {
                    postNotification(name, fLast.length() > 80 ? fLast.substring(0, 80) : fLast);
                }
            }
            prefs.edit().putString(KEY_LAST, next.toString()).apply();
            return Result.success();
        } catch (Exception ignored) {
            return Result.retry();
        }
    }

    private String fetch(String urlStr) {
        java.net.HttpURLConnection conn = null;
        try {
            java.net.URL url = new java.net.URL(urlStr);
            conn = (java.net.HttpURLConnection) url.openConnection();
            conn.setConnectTimeout(15000);
            conn.setReadTimeout(15000);
            conn.setRequestProperty("Accept", "application/json");
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

    private String normalize(String s) {
        if (s == null) return "";
        return s.trim().toUpperCase().replaceAll("\\s+", "");
    }

    private String UriEncode(String s) {
        try { return java.net.URLEncoder.encode(s, "UTF-8"); }
        catch (Exception e) { return s; }
    }

    private void postNotification(String title, String body) {
        Context ctx = getApplicationContext();
        NotificationManager manager = (NotificationManager) ctx.getSystemService(Context.NOTIFICATION_SERVICE);
        if (manager == null) return;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    CHANNEL_ID,
                    "رسائل الأصدقاء",
                    NotificationManager.IMPORTANCE_DEFAULT
            );
            channel.setDescription("إشعارات رسائل الأصدقاء");
            manager.createNotificationChannel(channel);
        }

        Intent launch = ctx.getPackageManager().getLaunchIntentForPackage(ctx.getPackageName());
        if (launch == null) return;
        launch.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
        PendingIntent pending = PendingIntent.getActivity(
                ctx, (int) System.currentTimeMillis(), launch,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
        );

        NotificationCompat.Builder builder = new NotificationCompat.Builder(ctx, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.stat_notify_chat)
                .setContentTitle(title)
                .setContentText(body)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setAutoCancel(true)
                .setContentIntent(pending);

        manager.notify((int) System.currentTimeMillis(), builder.build());
    }
}
