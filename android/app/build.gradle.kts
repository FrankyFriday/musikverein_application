plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin muss nach Android und Kotlin Plugins angewendet werden
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.musikvereinscharrel.musikverein_application" // Einheitlicher Package-Name für Prod
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    buildToolsVersion = ''

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.musikvereinscharrel.musikverein_application" // Standard Application ID für prod
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("debug")
        }
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }

    }

    flavorDimensions += "default"

    productFlavors {
        create("dev") {
            dimension = "default"
            applicationId = "com.musikvereinscharrel.musikverein_application.dev"
            versionNameSuffix = "-dev"
        }
        create("qa") {  // <-- geändert von 'test' zu 'qa'
            dimension = "default"
            applicationId = "com.musikvereinscharrel.musikverein_application.qa"
            versionNameSuffix = "-qa"
        }
        create("prod") {
            dimension = "default"
            applicationId = "com.musikvereinscharrel.musikverein_application"
        }
    }

}

flutter {
    source = "../.."
}
