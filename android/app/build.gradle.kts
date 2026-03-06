import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.toiall.gold_sham"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // ✅ السطر الأساسي لحل مشكلة core library desugaring
        // ✅ التصحيح: في Kotlin DSL يجب استخدام isCoreLibraryDesugaringEnabled
        isCoreLibraryDesugaringEnabled = true
        // ✅ غيرت من VERSION_11 إلى VERSION_1_8
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        // ✅ غيرت من VERSION_11 إلى VERSION_1_8
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.toiall.gold_sham"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion // ✅ Forced to 21 for Firebase/AdMob compatibility
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // ✅ أضفت هذا السطر (مهم خاصة إذا كان minSdk <= 20)
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            
            // ✅ أضفت قواعد الحماية لضمان عدم توقف التطبيق بعد التصدير
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

// ✅ تطبيق إضافة Google Services لخدمات Firebase والإشعارات
apply(plugin = "com.google.gms.google-services")

flutter {
    source = "../.."
}

// ✅ أضفت قسم dependencies مع مكتبة desugaring المطلوبة
dependencies {
    // هذا هو dependency المطلوب لحل المشكلة
    // استخدم أحدث إصدار متوافق (2.0.4 حالياً)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
