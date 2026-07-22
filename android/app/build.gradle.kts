plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "pet.jolipaw.app"
    compileSdk = flutter.compileSdkVersion
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
    }

    buildTypes {
        debug {
            // debug 模式也使用 zhichuang.keystore 签名（微信/阿里云一键登录依赖签名校验）
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
        }
        release {
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

    // 阿里云一键登录 AAR（本地依赖，直接引用 ali_auth 插件的 libs 目录）
    implementation(files(
        "../../local_patches/ali_auth/android/libs/auth_number_product-2.14.19-release.aar",
        "../../local_patches/ali_auth/android/libs/logger-2.2.2-release.aar",
        "../../local_patches/ali_auth/android/libs/main-2.2.3-release.aar"
    ))
}

flutter {
    source = "../.."
}
