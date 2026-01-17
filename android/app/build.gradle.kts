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
    source = "../. ."
}

dependencies {
    // ✅ Import the Firebase BoM (Bill of Materials)
    implementation(platform("com.google.firebase:firebase-bom:34.7.0"))
    
    // ✅ Firebase Analytics (example - already included via BoM)
    implementation("com.google.firebase:firebase-analytics")
    
    // ✅ MultiDex support
    implementation("androidx.multidex:multidex:2.0.1")
    
    // When using the BoM, don't specify versions in Firebase dependencies
    // Add other Firebase products you want to use here 
}
