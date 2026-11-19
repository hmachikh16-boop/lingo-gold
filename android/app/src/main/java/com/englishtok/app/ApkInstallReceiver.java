package com.englishtok.app;

import android.app.DownloadManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;

import androidx.core.content.FileProvider;

import java.io.File;

/**
 * Listens for Android DownloadManager completions and, when the finished file
 * is a Lin Go APK, launches the system package installer so the update installs
 * from inside the app without the user opening a file manager or browser.
 */
public class ApkInstallReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent == null || !DownloadManager.ACTION_DOWNLOAD_COMPLETE.equals(intent.getAction())) {
            return;
        }
        long downloadId = intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, -1L);
        if (downloadId < 0) return;

        DownloadManager manager = (DownloadManager) context.getSystemService(Context.DOWNLOAD_SERVICE);
        if (manager == null) return;

        Uri fileUri = null;
        String mimeType = null;
        Cursor cursor = null;
        try {
            cursor = manager.query(new DownloadManager.Query().setFilterById(downloadId));
            if (cursor != null && cursor.moveToFirst()) {
                int status = cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS));
                if (status != DownloadManager.STATUS_SUCCESSFUL) return;
                mimeType = cursor.getString(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_MEDIA_TYPE));
                String localUri = cursor.getString(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_LOCAL_URI));
                if (localUri != null) fileUri = Uri.parse(localUri);
            }
        } catch (Exception ignored) {
            return;
        } finally {
            if (cursor != null) cursor.close();
        }

        if (fileUri == null) return;
        if (mimeType == null || !mimeType.contains("package-archive")) {
            // Only act on APK downloads; leave other files alone.
            if (fileUri.getPath() == null || !fileUri.getPath().toLowerCase().endsWith(".apk")) return;
        }

        // On Android 8+ the user must grant install permission first.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
                && !context.getPackageManager().canRequestPackageInstalls()) {
            Intent settings = new Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES);
            settings.setData(Uri.parse("package:" + context.getPackageName()));
            settings.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(settings);
            return;
        }

        try {
            Uri installUri;
            if ("file".equals(fileUri.getScheme())) {
                File file = new File(fileUri.getPath());
                installUri = FileProvider.getUriForFile(
                        context,
                        context.getPackageName() + ".fileprovider",
                        file
                );
            } else {
                installUri = fileUri;
            }
            Intent install = new Intent(Intent.ACTION_VIEW);
            install.setDataAndType(installUri, "application/vnd.android.package-archive");
            install.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            install.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
            context.startActivity(install);
        } catch (Exception ignored) {
            // Fall back to opening the Downloads app.
            try {
                Intent fallback = new Intent(DownloadManager.ACTION_VIEW_DOWNLOADS);
                fallback.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                context.startActivity(fallback);
            } catch (Exception ignored2) { }
        }
    }
}
