# Flutter ve Firebase için ProGuard kuralları

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.measurement.** { *; }
-keep class com.google.android.gms.internal.** { *; }

# Google Play Core (R8 hatalarını engellemek için)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Google Generative AI
-dontwarn com.google.ai.**

# Just Audio
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# Genel Android kuralları
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
