plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 修复 AGP 9.1.0 R8 NPE: 强制使用修复了 androidx.core 兼容性的 R8 版本
buildscript {
    dependencies {
        classpath("com.android.tools:r8:8.7.19")
    }
}

import java.util.Properties

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "pet.jolipaw.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        val storeFilePath = keystoreProperties.getProperty("storeFile")
        if (!storeFilePath.isNullOrEmpty()) {
            create("release") {
                storeFile = file(storeFilePath)
                storePassword = keystoreProperties.getProperty("storePassword") ?: ""
                keyAlias = keystoreProperties.getProperty("keyAlias") ?: ""
                keyPassword = keystoreProperties.getProperty("keyPassword") ?: ""
            }
        }
    }

    defaultConfig {
        applicationId = "pet.jolipaw.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    packaging {
        jniLibs {
            keepDebugSymbols.clear()
            excludes.addAll(listOf("**/x86/*.so", "**/x86_64/*.so"))
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    compileOnly("com.tencent.mm.opensdk:wechat-sdk-android:6.8.0")
}

flutter {
    source = "../.."
}
