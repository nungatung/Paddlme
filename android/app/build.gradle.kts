plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins. 
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // ✅ ADD THIS - Google services Gradle plugin
}

android {
    namespace = "com.example.wave_share"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.3.13750724"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
         isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.wave_share"
        minSdk = flutter.minSdkVersion  // ✅ CHANGED - Firebase requires minimum SDK 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true  // ✅ ADD THIS - Required for Firebase
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs. getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.7.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("androidx.multidex:multidex:2.0.1")

    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
   
}
