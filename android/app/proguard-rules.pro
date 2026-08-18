# ============================================================
# ProGuard / R8 keep rules for ZiggyBites Delivery (Release)
# ============================================================
# Without these rules, R8 (minifyEnabled true) strips classes
# used by audioplayers, flutter_background_service, and
# flutter_local_notifications, causing silent notifications
# and broken ringtones in the release APK.
# ============================================================

# ---------- Flutter core ----------
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.app.** { *; }
-dontwarn io.flutter.**

# ---------- Flutter plugin registrant (generated) ----------
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# ---------- Firebase Cloud Messaging ----------
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ---------- flutter_local_notifications ----------
-keep class com.dexterous.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.**

# ---------- audioplayers (critical for ringtone in background) ----------
-keep class xyz.luan.audioplayers.** { *; }
-keep class xyz.luan.audioplayers.AudioplayersPlugin { *; }
-keep class xyz.luan.audioplayers.player.** { *; }
-dontwarn xyz.luan.audioplayers.**

# ---------- flutter_background_service ----------
-keep class id.flutter.flutter_background_service.** { *; }
-keep class id.flutter.flutter_background_service.BackgroundService { *; }
-dontwarn id.flutter.flutter_background_service.**

# ---------- permission_handler ----------
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# ---------- geolocator ----------
-keep class com.baseflow.geolocator.** { *; }
-dontwarn com.baseflow.geolocator.**

# ---------- Dart VM entry points (vm:entry-point pragma) ----------
# Dart functions annotated with @pragma('vm:entry-point') must not be removed.
# The Dart AOT compiler respects the pragma, but the Kotlin/Java bridge
# classes that call into them must be kept.
-keep @interface dart.annotation.DartName
-keepclassmembers class * {
    @dart.annotation.DartName *;
}

# ---------- Kotlin / coroutines ----------
-keep class kotlin.** { *; }
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.coroutines.**

# ---------- AndroidX / Support ----------
-keep class androidx.** { *; }
-dontwarn androidx.**

# ---------- Media / Audio ----------
# Keep MediaPlayer and related system classes used by audioplayers
-keep class android.media.** { *; }

# ---------- General safety rules ----------
# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep all enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable implementations
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes SourceFile,LineNumberTable
