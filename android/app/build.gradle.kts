plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.techbizafrica.kflkiosk"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            storeFile = file(System.getenv("ANDROID_KEYSTORE_PATH") ?: "upload-keystore.jks")
            storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD") ?: ""
            keyAlias = System.getenv("ANDROID_KEY_ALIAS") ?: ""
            keyPassword = System.getenv("ANDROID_KEY_PASSWORD") ?: ""
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.techbizafrica.kflkiosk"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    flavorDimensions += "role"
    productFlavors {
        create("superadmin") {
            dimension = "role"
            applicationIdSuffix = ".superadmin"
            resValue("string", "app_name", "SSS Admin")
        }
        create("manager") {
            dimension = "role"
            applicationIdSuffix = ".manager"
            resValue("string", "app_name", "SSS Manager")
        }
        create("staff") {
            dimension = "role"
            applicationIdSuffix = ".staff"
            resValue("string", "app_name", "SSS Staff")
        }
        create("warehouse") {
            dimension = "role"
            applicationIdSuffix = ".warehouse"
            resValue("string", "app_name", "SSS Warehouse")
        }
        create("kiosk") {
            dimension = "role"
            applicationIdSuffix = ".kiosk"
            resValue("string", "app_name", "SSS Kiosk")
        }
        create("dashboard") {
            dimension = "role"
            applicationIdSuffix = ".dashboard"
            resValue("string", "app_name", "SSS Dashboard")
        }
    }

    buildTypes {
        release {
            val keystorePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
            if (keystorePassword != null && keystorePassword.isNotEmpty()) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                println("No ANDROID_KEYSTORE_PASSWORD provided, falling back to debug keystore for local build.")
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
