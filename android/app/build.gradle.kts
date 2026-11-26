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

// ADR-0019 (TAM-119, REL-MD-1): prodRelease is signed with the owner's upload key (Play App Signing keeps
// the app signing key). Nothing about the key is in the repository: the four values come from Gradle
// properties (owner's %USERPROFILE%\.gradle\gradle.properties, -P, ORG_GRADLE_PROJECT_*) or from
// environment variables, so a later CI build (ADR-0019 stage 2) can use the same mechanism.
// Missing or incomplete values = no signing config for prod (never the debug key) and, if a prodRelease
// packaging task is in the task graph, a build error that lists what is missing (android/RELEASE.md).
// devRelease keeps the debug key (ADR-0019 pt 3, "devRelease unchanged": QA builds, never uploaded).
fun uploadSigningValue(property: String, env: String): String? =
    (providers.gradleProperty(property).orNull ?: providers.environmentVariable(env).orNull)
        ?.takeIf { it.isNotBlank() }

val uploadStoreFile = uploadSigningValue("tamitu.upload.storeFile", "TAMITU_UPLOAD_STORE_FILE")
val uploadStorePassword =
    uploadSigningValue("tamitu.upload.storePassword", "TAMITU_UPLOAD_STORE_PASSWORD")
val uploadKeyAlias = uploadSigningValue("tamitu.upload.keyAlias", "TAMITU_UPLOAD_KEY_ALIAS")
val uploadKeyPassword =
    uploadSigningValue("tamitu.upload.keyPassword", "TAMITU_UPLOAD_KEY_PASSWORD")

// Problems are collected here and reported only when a prodRelease build is requested, so debug,
// profile and dev builds (and the CI "does it compile" step) work without any signing setup.
val uploadSigningProblems: List<String> =
    buildList {
        if (uploadStoreFile == null) add("tamitu.upload.storeFile / TAMITU_UPLOAD_STORE_FILE is not set")
        if (uploadStorePassword == null) {
            add("tamitu.upload.storePassword / TAMITU_UPLOAD_STORE_PASSWORD is not set")
        }
        if (uploadKeyAlias == null) add("tamitu.upload.keyAlias / TAMITU_UPLOAD_KEY_ALIAS is not set")
        if (uploadKeyPassword == null) {
            add("tamitu.upload.keyPassword / TAMITU_UPLOAD_KEY_PASSWORD is not set")
        }
        if (uploadStoreFile != null && !file(uploadStoreFile).isFile) {
            // The path is the owner's local path; it is not printed (no private paths in build logs).
            add("the file given in tamitu.upload.storeFile / TAMITU_UPLOAD_STORE_FILE does not exist")
        }
    }

val prodReleasePackagingTask = Regex("(assemble|bundle|package|sign)ProdRelease\\w*")

gradle.taskGraph.whenReady {
    if (uploadSigningProblems.isEmpty()) return@whenReady
    val prodReleaseTasks =
        allTasks.filter { it.project == appProject && prodReleasePackagingTask.matches(it.name) }
    if (prodReleaseTasks.isNotEmpty()) {
        throw GradleException(
            "prodRelease must be signed with the upload key (ADR-0019), but the signing config " +
                "is incomplete:\n - " + uploadSigningProblems.joinToString("\n - ") +
                "\nSee android/RELEASE.md. The debug key is never used for prodRelease. " +
                "Release tasks in the graph: " + prodReleaseTasks.joinToString { it.path },
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

    signingConfigs {
        if (uploadSigningProblems.isEmpty()) {
            create("upload") {
                storeFile = file(uploadStoreFile!!)
                storePassword = uploadStorePassword
                keyAlias = uploadKeyAlias
                keyPassword = uploadKeyPassword
            }
        }
    }

    // Signing per flavor (TAM-119). AGP takes the build type's signing config first, so debug and
    // profile builds keep the debug key; the release build type has none, so release variants use
    // the flavor's: dev = debug key (ADR-0019 pt 3), prod = upload key or nothing (unsigned + the
    // task-graph error above). Do not add a signingConfig to buildTypes.release.
    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "Tamitu Dev")
            signingConfig = signingConfigs.getByName("debug")
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "Tamitu")
            signingConfig = signingConfigs.findByName("upload")
        }
    }

    buildTypes {
        release {
            signingConfig = null
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
