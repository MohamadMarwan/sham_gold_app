# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.mediation.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }

# Prevent shrinking of important codecs
-keep class io.flutter.plugins.googlemobileads.AdMessageCodec { *; }

# ✅ حل مشكلة R8 الخاصة بـ Play Core (التي سببت فشل البناء)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# ✅ منع حذف أو تغيير أسماء موديلات البيانات (ضروري لفك تشفير JSON)
-keep class com.example.gold_sham.shared.models.** { *; }
-keepclassmembers class com.example.gold_sham.shared.models.** { *; }

# Keep GSON/JSON related fields
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class com.example.gold_sham.** { *; }
