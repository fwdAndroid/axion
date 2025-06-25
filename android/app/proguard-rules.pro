# Keep ZegoCloud SDK classes
-keep class **.zego.** { *; }
-keep class **.zegoexpress.** { *; }
-keep class com.zegocloud.** { *; }
-keep class im.zego.** { *; }
-keep class org.webrtc.** { *; }
-keep class org.videolan.libvlc.** { *; }


# Keep specific classes mentioned in error
-keep class com.itgsa.opensdk.mediaunit.KaraokeMediaHelper { *; }
-keep class com.itgsa.opensdk.media.MediaClient { *; }

# General Flutter rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep annotations
-keepattributes *Annotation*
-keepattributes InnerClasses

# Keep native methods
-keepclasseswithmembers class * {
    native <methods>;
}

-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
-dontwarn com.itgsa.opensdk.mediaunit.KaraokeMediaHelper