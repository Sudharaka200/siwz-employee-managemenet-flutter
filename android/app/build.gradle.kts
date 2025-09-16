plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.example.employee_tracking"
    compileSdk = 36 // Updated to 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
        freeCompilerArgs = listOf("-Xlint:-options") // Suppress Java 8 warnings
    }

    defaultConfig {
        applicationId = "com.example.employee_tracking"
        minSdk = flutter.minSdkVersion // Ensure minSdk is at least 21
        targetSdk = 36 // Updated to 36 for consistency
        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}