# Flutter 通用保留规则
-dontshrink
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# 保留所有 Dart 反射相关的类（JSON 序列化等）
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.** { *; }

# 保留第三方 SDK 类
-keep class com.tencent.** { *; }
-keep class com.huawei.** { *; }
-keep class com.alibaba.** { *; }
-keep class com.alipay.** { *; }
-keep class com.igexin.** { *; }

# 保留阿里云一键登录
-keep class com.mobile.auth.** { *; }
-keep class com.cmic.sso.** { *; }
-keep class cn.com.chinatelecom.** { *; }
-keep class com.sdk.** { *; }

# 保留微信 SDK
-keep class com.tencent.mm.opensdk.** { *; }
-keep class com.tencent.wxop.** { *; }
-keep class com.tencent.mm.sdk.** { *; }

# 保留华为 HMS / ML Kit
-keep class com.huawei.hms.** { *; }
-keep class com.huawei.agconnect.** { *; }
-keep class com.huawei.hmf.** { *; }

# 保留百度定位 / 高德地图相关
-keep class com.baidu.** { *; }
-keep class com.amap.** { *; }

# 保留所有 Native 方法（JNI）
-keepclasseswithmembernames class * {
    native <methods>;
}

# 保留枚举类
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# 保留序列化相关
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# 保留 R 文件
-keep class **.R$* { *; }

# 保留资源文件引用
-keepclassmembers class **.R$* {
    public static <fields>;
}

# 保留 View Binding / Data Binding
-keep class * implements androidx.viewbinding.ViewBinding { *; }

# 保留 Kotlin 协程相关
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}

# 保留 AndroidX Core Location（修复 AGP 9.0.1 + core-1.18.0 的 R8 NullPointerException bug）
-keep class androidx.core.location.** { *; }
