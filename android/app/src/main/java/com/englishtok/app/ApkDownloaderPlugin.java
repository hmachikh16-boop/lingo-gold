package com.englishtok.app;

import android.app.DownloadManager;
import android.content.ActivityNotFoundException;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.Settings;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

import androidx.core.content.FileProvider;

import java.io.File;
import java.util.regex.Pattern;

@CapacitorPlugin(name = "ApkDownloader")
public class ApkDownloaderPlugin extends Plugin {

    private static final String OFFICIAL_HOST = "englishtok-eight.vercel.app";
    private static final Pattern OFFICIAL_PATH =
            Pattern.compile("^/(english-tok|lin-go-gold-\\d+\\.\\d+\\.\\d+)\\.apk$");

    @PluginMethod
    public void download(PluginCall call) {
        final String url = call.getString("url");
        final String fileName = call.getString("fileName");
        final String title = call.getString("title", "Lin Go update");

        if (url == null || url.isEmpty()) {
            call.reject("رابط التنزيل غير متوفر.", "INVALID_URL");
            return;
        }

        Uri uri;
        try {
            uri = Uri.parse(url);
        } catch (Exception exception) {
            call.reject("رابط التنزيل غير صالح.", "INVALID_URL");
            return;
        }

        if (!"https".equalsIgnoreCase(uri.getScheme())
                || !OFFICIAL_HOST.equalsIgnoreCase(uri.getHost())
                || uri.getPath() == null
                || !OFFICIAL_PATH.matcher(uri.getPath()).matches()) {
            call.reject("يُسمح فقط برابط التنزيل الرسمي من موقع Lin Go.", "UNTRUSTED_URL");
            return;
        }

        if (fileName == null || !fileName.matches("^[A-Za-z0-9._-]+\\.apk$")) {
            call.reject("اسم ملف التنزيل غير صالح.", "INVALID_FILE_NAME");
            return;
        }

        try {
            final Context context = getContext();
            final DownloadManager manager =
                    (DownloadManager) context.getSystemService(Context.DOWNLOAD_SERVICE);
            if (manager == null) {
                call.reject("خدمة التنزيل غير متوفرة على هذا الجهاز.", "DOWNLOAD_MANAGER_UNAVAILABLE");
                return;
            }

            final DownloadManager.Request request = new DownloadManager.Request(uri);
            request.setTitle(title);
            request.setDescription("تنزيل تحديث Lin Go الرسمي");
            request.setMimeType("application/vnd.android.package-archive");
            request.setNotificationVisibility(
                    DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED
            );
            request.setAllowedOverMetered(true);
            request.setAllowedOverRoaming(false);

            final String location;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, fileName);
                location = "Downloads/" + fileName;
            } else {
                request.setDestinationInExternalFilesDir(
                        context,
                        Environment.DIRECTORY_DOWNLOADS,
                        fileName
                );
                location = "Android/data/" + context.getPackageName()
                        + "/files/Download/" + fileName;
            }

            final long downloadId = manager.enqueue(request);
            final JSObject result = new JSObject();
            result.put("id", downloadId);
            result.put("fileName", fileName);
            result.put("location", location);
            call.resolve(result);
        } catch (Exception exception) {
            call.reject(
                    "تعذر بدء التنزيل داخل التطبيق: " + exception.getMessage(),
                    "DOWNLOAD_FAILED"
            );
        }
    }

    @PluginMethod
    public void canInstallPackages(PluginCall call) {
        JSObject result = new JSObject();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            result.put("canInstall", getContext().getPackageManager().canRequestPackageInstalls());
        } else {
            result.put("canInstall", true);
        }
        call.resolve(result);
    }

    @PluginMethod
    public void openInstallSettings(PluginCall call) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Intent settings = new Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES);
                settings.setData(Uri.parse("package:" + getContext().getPackageName()));
                settings.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                getContext().startActivity(settings);
            }
            call.resolve();
        } catch (Exception exception) {
            call.reject("تعذر فتح إعدادات التثبيت: " + exception.getMessage(), "SETTINGS_FAILED");
        }
    }

    @PluginMethod
    public void install(PluginCall call) {
        final String fileName = call.getString("fileName");
        if (fileName == null || !fileName.matches("^[A-Za-z0-9._-]+\\.apk$")) {
            call.reject("اسم ملف التثبيت غير صالح.", "INVALID_FILE_NAME");
            return;
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
                && !getContext().getPackageManager().canRequestPackageInstalls()) {
            call.reject("يجب السماح للتثبيت من هذا التطبيق أولًا.", "INSTALL_PERMISSION_REQUIRED");
            return;
        }

        try {
            File file;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                file = new File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), fileName);
            } else {
                file = new File(getContext().getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS), fileName);
            }
            if (!file.exists()) {
                call.reject("ملف التحديث غير موجود. نزّله أولًا.", "FILE_MISSING");
                return;
            }
            Uri uri = FileProvider.getUriForFile(getContext(), getContext().getPackageName() + ".fileprovider", file);
            Intent install = new Intent(Intent.ACTION_VIEW);
            install.setDataAndType(uri, "application/vnd.android.package-archive");
            install.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            install.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
            getContext().startActivity(install);
            call.resolve();
        } catch (Exception exception) {
            call.reject("تعذر بدء التثبيت: " + exception.getMessage(), "INSTALL_FAILED");
        }
    }

    @PluginMethod
    public void saveFriendCode(PluginCall call) {
        final String code = call.getString("code");
        if (code == null || code.trim().isEmpty()) {
            call.reject("رمز الصديق غير صالح.", "INVALID_CODE");
            return;
        }
        getContext().getSharedPreferences("lingo_friends", Context.MODE_PRIVATE)
                .edit()
                .putString("friend_code", code.trim().toUpperCase())
                .apply();
        call.resolve();
    }

    @PluginMethod
    public void getFriendCode(PluginCall call) {
        final String code = getContext().getSharedPreferences("lingo_friends", Context.MODE_PRIVATE)
                .getString("friend_code", "");
        final JSObject result = new JSObject();
        result.put("code", code);
        call.resolve(result);
    }

    @PluginMethod
    public void openDownloads(PluginCall call) {
        try {
            final Intent intent = new Intent(DownloadManager.ACTION_VIEW_DOWNLOADS);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            getContext().startActivity(intent);
            call.resolve();
        } catch (ActivityNotFoundException exception) {
            call.reject("لا يوجد تطبيق لعرض التنزيلات على هذا الجهاز.", "DOWNLOADS_APP_MISSING");
        } catch (Exception exception) {
            call.reject("تعذر فتح التنزيلات: " + exception.getMessage(), "DOWNLOADS_OPEN_FAILED");
        }
    }
}
