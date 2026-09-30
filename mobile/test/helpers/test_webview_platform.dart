import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Test implementation of [PlatformInAppWebViewWidget] for widget tests.
class TestPlatformInAppWebViewWidget extends PlatformInAppWebViewWidget {
  TestPlatformInAppWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(key: Key('test_in_app_webview'));
  }

  @override
  T controllerFromPlatform<T>(PlatformInAppWebViewController controller) {
    return controller as T;
  }

  @override
  void dispose() {}
}

/// Test implementation of [InAppWebViewPlatform] that stubs webview instantiation in tests.
class TestInAppWebViewPlatform extends InAppWebViewPlatform {
  static void register() {
    InAppWebViewPlatform.instance = TestInAppWebViewPlatform();
  }

  @override
  PlatformInAppWebViewWidget createPlatformInAppWebViewWidget(
    PlatformInAppWebViewWidgetCreationParams params,
  ) {
    return TestPlatformInAppWebViewWidget(params);
  }
}
