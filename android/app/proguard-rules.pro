# Facebook Audience Network
-keep class com.facebook.ads.** { *; }
-dontwarn com.facebook.ads.**
-dontwarn com.facebook.infer.annotation.**

# Google Mobile Ads & Mediation
-keep class com.google.ads.mediation.** { *; }
-dontwarn com.google.ads.mediation.**

# Unity Ads Mediation Adapter
-keep class com.unity3d.ads.** { *; }
-keep class com.unity3d.services.** { *; }
-dontwarn com.unity3d.ads.**
-dontwarn com.unity3d.services.**

# Firebase Messaging
-keep class com.google.firebase.messaging.** { *; }
-dontwarn com.google.firebase.messaging.**

# Flutter + Dart
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
