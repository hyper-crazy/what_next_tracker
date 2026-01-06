pluginManagement {
    def flutterSdkPath = settings.extraProperties.get("flutter.sdk") as String
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.1.0" apply false
    // We force a stable Kotlin version here to avoid the 2.0.21 fetch error
    id("org.jetbrains.kotlin.android") version "1.9.24" apply false
}

include(":app")

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}