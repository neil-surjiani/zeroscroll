# Flutter wrapper rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**
-ignorewarnings

# InAppWebView rules
-keep class com.pichillilorenzo.flutter_inappwebview_android.** { *; }

# SQLite rules
-keep class org.sqlite.** { *; }
