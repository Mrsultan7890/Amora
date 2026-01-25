# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Play Core (Fix for missing classes)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Dio
-keep class dio.** { *; }

# Shared Preferences
-keep class shared_preferences.** { *; }

# Image Picker
-keep class image_picker.** { *; }

# Geolocator
-keep class geolocator.** { *; }

# Permission Handler
-keep class permission_handler.** { *; }

# Cached Network Image
-keep class cached_network_image.** { *; }

# WebSocket
-keep class web_socket_channel.** { *; }

# Don't obfuscate model classes
-keep class **.*Model { *; }
-keep class **.*Response { *; }
-keep class **.*Request { *; }

# Prevent obfuscation of native methods
-keepclasseswithmembernames class * {
    native <methods>;
}