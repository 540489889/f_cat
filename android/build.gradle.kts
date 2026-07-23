allprojects {
    repositories {
        // Flutter 引擎产物国内镜像（规避 download.flutter.io 证书不匹配 / 下载失败）
        maven { url = uri("https://storage.flutter-io.cn/download.flutter.io") }
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
        maven { url = uri("https://developer.huawei.com/repo/") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://maven.aliyun.com/repository/google") }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// 强制所有子模块（包括 geocoding_android 等插件）使用统一的 compileSdk
// 在 Gradle 配置阶段结束时执行，避免 afterEvaluate 在已评估项目上注册
gradle.afterProject { project ->
    if (project.extensions.findByName("android") != null) {
        project.extensions.getByName("android").withGroovyBuilder {
            setProperty("compileSdk", 36)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}



