# R8 rules for the release build.
#
# Ported from snake_classic, which ships very nearly this plugin set. The
# guiding rule there applies here too: do NOT add blanket
# "-keep class <pkg>.** { *; }" entries for whole SDKs. Every SDK in this app
# ships its own consumer rules inside its AAR, and Firebase is built for R8
# full mode, so blanket keeps protect nothing that is not already protected
# while pinning thousands of classes R8 could otherwise inline, merge, rename
# or drop. Only rules with a documented reason belong below.

# ---------------------------------------------------------------------------
# Flutter. No rules needed: the engine marks its JNI entry points with @Keep
# (honoured by proguard-android-optimize.txt) and the Flutter Gradle plugin
# keeps every FlutterPlugin implementation (flutter_proguard_rules.pro).
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# drift / sqlite3 need nothing here. drift is pure Dart, and sqlite3 reaches
# its native library through FFI rather than JNI or reflection, so there are
# no Java symbols for R8 to strip. sqlite3_flutter_libs only bundles the .so.
# ---------------------------------------------------------------------------

# Google Play Core (deferred components / split install) - referenced by the
# Flutter embedding but not shipped in this app. Note this is a different
# artifact from com.google.android.play:app-update, which in_app_update does
# use and which ships its own consumer rules.
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# ---------------------------------------------------------------------------
# Firebase Crashlytics: readable stack traces. The Crashlytics Gradle plugin
# uploads the R8 mapping file; these attributes must survive shrinking for the
# retrace to line up, and custom exception types keep their names so a report
# says what was thrown. Without SourceFile/LineNumberTable every future crash
# report - including the ProxyBillingActivity one we just fixed - arrives
# without line numbers.
# ---------------------------------------------------------------------------
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ---------------------------------------------------------------------------
# flutter_local_notifications - uses Gson to (de)serialize scheduled
# notification details. R8 full mode strips the generic TypeToken signatures
# and crashes on scheduled/rescheduled notifications without these keeps
# (the rules the plugin's README asks for).
# ---------------------------------------------------------------------------
-keep class com.dexterous.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.stream.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Keep Parcelables
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
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

# ---------------------------------------------------------------------------
# Google Play Billing + flutter_inapp_purchase (OpenIAP). Both AARs ship their
# own consumer rules: billing keeps its AIDL and proxy activities (including
# the two we re-declare in AndroidManifest.xml), openiap-google keeps
# dev.hyo.openiap.models.** for its JSON bridge. The Flutter plugin class
# itself is a FlutterPlugin and is kept by the Flutter Gradle plugin. Nothing
# to add beyond silencing optional references.
# ---------------------------------------------------------------------------
-dontwarn dev.hyo.**
-dontwarn io.github.hyochan.**
