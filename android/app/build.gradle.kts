plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// google-services.json is NOT in the repository (public repo, P3-03 etap 10): the owner copies it to
// android/app/src/dev/ and android/app/src/prod/ (see android/FIREBASE.md). A missing file fails the
// build (ERROR), so a developer never gets an APK silently built without Firebase config.
// Exception: CI (GitHub Actions sets CI=true) or -Ptamitu.allowMissingGoogleServices=true only WARN,
// so the "does it compile" check runs without any Firebase config or keys until GH-009 provides
// the files from repository secrets. Such an APK cannot sign in (Firebase.initializeApp fails).
val allowMissingGoogleServices =
    providers.environmentVariable("CI").orNull == "true" ||
        providers.gradleProperty("tamitu.allowMissingGoogleServices").orNull == "true"

googleServices {
    missingGoogleServicesStrategy =
        if (allowMissingGoogleServices) {
            com.google.gms.googleservices.GoogleServicesPlugin.MissingGoogleServicesStrategy.WARN
        } else {
            com.google.gms.googleservices.GoogleServicesPlugin.MissingGoogleServicesStrategy.ERROR
        }
}

android {
    namespace = "pl.tadecode.tamitu"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "pl.tadecode.tamitu"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // ADR-0007 / Q8: minSdk 26.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildFeatures {
        resValues = true
    }

    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "Tamitu Dev")
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "Tamitu")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
