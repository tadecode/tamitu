plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// google-services.json is NOT in the repository (public repo, P3-03 etap 10): the owner keeps it in
// %USERPROFILE%\.tamitu\firebase\<env>\ and copies it to android/app/src/<flavor>/ (android/FIREBASE.md).
// A missing file fails the build (ERROR), so an APK is never built silently without Firebase config.
// SEC-33 (review PR #70 #1): the only exception is the explicit project property
//   flutter build apk --debug -P tamitu.allowMissingGoogleServices=true
// used by the CI "does it compile" step (and the fake-backend demo) until GH-009 provides the files
// from secrets. It no longer depends on the CI environment variable and it is refused for release
// builds: a release APK/AAB always needs the real file (it would crash on Firebase.initializeApp()).
// SEC-35 (review PR #77 #1): the release check inspects the resolved task graph, not the command-line
// task names, so aggregate tasks (`assemble`, `build`, `bundle`) and a property set in
// ~/.gradle/gradle.properties or ORG_GRADLE_PROJECT_* are covered too: if any release variant's
// google-services task (process<Flavor>ReleaseGoogleServices) is scheduled, the build fails.
val allowMissingGoogleServices =
    providers.gradleProperty("tamitu.allowMissingGoogleServices").orNull == "true"

val releaseGoogleServicesTask = Regex("process\\w*ReleaseGoogleServices")
val appProject = project

gradle.taskGraph.whenReady {
    if (!allowMissingGoogleServices) return@whenReady
    val releaseTasks =
        allTasks.filter { it.project == appProject && releaseGoogleServicesTask.matches(it.name) }
    if (releaseTasks.isNotEmpty()) {
        throw GradleException(
            "tamitu.allowMissingGoogleServices=true is allowed only for debug/profile builds; " +
                "a release build requires android/app/src/<flavor>/google-services.json " +
                "(SEC-33/SEC-35). Release tasks in the graph: " +
                releaseTasks.joinToString { it.path },
        )
    }
}

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
