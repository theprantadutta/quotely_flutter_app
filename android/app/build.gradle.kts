import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.pranta.quotely"
    // permission_handler_android 14.1.0 requires consumers to compile against
    // API 37; the build fails at :app:checkDebugAarMetadata below that. This is
    // independent of targetSdk/minSdk, which still track flutter.* - raising
    // compileSdk only allows newer APIs, it does not opt into new runtime
    // behaviour or drop device support.
    compileSdk = 37
    // Pinned rather than flutter.ndkVersion (28.2.13676358 on Flutter 3.47.1).
    // Note this no longer auto-tracks the Flutter version - revisit on upgrade.
    ndkVersion = "30.0.14904198"

    compileOptions {
        // Flag to enable support for the new language APIs
        isCoreLibraryDesugaringEnabled = true
        // Java 17, matching the other apps in this repo. javac warns that
        // "source/target value 8 is obsolete and will be removed in a future
        // release"; desugaring stays on so minSdk 24 devices keep working.
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.pranta.quotely"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        multiDexEnabled = true

        // Required by flutter_inapp_purchase (7.1.14+). openiap-google ships
        // 'play' and 'amazon' product flavors; without this the Play variant
        // cannot be resolved and the build fails on a missing dimension.
        missingDimensionStrategy("platform", "play")
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // Play Console flagged release 17: "Optimized resource shrinking
            // isn't enabled". The app had no minification at all - this block
            // set only the signing config - so R8 was running in its
            // pass-through mode and neither shrinking code nor resources.
            //
            // proguard-android-optimize.txt is the optimizing variant of the
            // default rules and honours @Keep, which is what lets the Flutter
            // engine's JNI entry points survive without any rules of our own.
            // See proguard-rules.pro for the few app-specific keeps.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // WindowCompat.enableEdgeToEdge(Window) in MainActivity needs core 1.16+.
    // It already resolves transitively; pinning keeps the compile classpath
    // from ever drifting below the API we call.
    implementation("androidx.core:core:1.18.0")

    implementation("androidx.window:window:1.3.0")
    // For Java-friendly APIs to register and unregister callbacks
    implementation("androidx.window:window-java:1.3.0")
}

flutter {
    source = "../.."
}
