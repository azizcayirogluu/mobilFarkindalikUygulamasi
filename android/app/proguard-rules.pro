# Flutter ve eklentiler
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase ve Google Play Services (Kendi otomatik consumer kurallarını kullanır)
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Google Play Core & Google AI
-dontwarn com.google.android.play.core.**
-dontwarn com.google.ai.**

# Just Audio / ExoPlayer
-dontwarn com.google.android.exoplayer2.**
-dontwarn androidx.media3.**

# Crashlytics ve Serileştirme için gerekli nitelikler
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
-keepattributes SourceFile,LineNumberTable
