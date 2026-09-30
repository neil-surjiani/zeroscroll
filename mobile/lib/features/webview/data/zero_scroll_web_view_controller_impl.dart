import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../domain/zero_scroll_web_view_controller.dart';
import 'webview_constants.dart';

/// Concrete implementation of [ZeroScrollWebViewController] wrapping [InAppWebViewController].
class ZeroScrollWebViewControllerImpl implements ZeroScrollWebViewController {
  ZeroScrollWebViewControllerImpl(this._controller);

  final InAppWebViewController _controller;
  String? _cachedUrl;

  /// Updates internal URL cache when navigations occur.
  void updateCachedUrl(String? url) {
    _cachedUrl = url;
  }

  @override
  String? get currentUrl => _cachedUrl;

  @override
  Future<void> loadInbox() async {
    await _controller.loadUrl(
      urlRequest: URLRequest(url: WebUri(WebViewConstants.directInboxUrl)),
    );
  }

  @override
  Future<void> loadNotifications() async {
    await _controller.loadUrl(
      urlRequest: URLRequest(url: WebUri(WebViewConstants.notificationsUrl)),
    );
  }

  @override
  Future<String?> getCurrentUrl() async {
    final uri = await _controller.getUrl();
    _cachedUrl = uri?.toString();
    return _cachedUrl;
  }

  @override
  Future<dynamic> evaluateJs(String source) async {
    return _controller.evaluateJavascript(source: source);
  }

  @override
  Future<bool> canGoBack() async {
    return _controller.canGoBack();
  }

  @override
  Future<void> goBack() async {
    await _controller.goBack();
  }

  @override
  Future<void> reload() async {
    await _controller.reload();
  }

  @override
  Future<void> clearAllSessionData() async {
    // 1. Delete all cookies through the WebView CookieManager
    final cookieManager = CookieManager.instance();
    await cookieManager.deleteAllCookies();

    // 2. Clear all cached web resources
    await InAppWebViewController.clearAllCache();

    // 3. Clear localStorage, sessionStorage, and IndexedDB
    const clearStorageJs = '''
      (function() {
        try {
          if (window.localStorage) window.localStorage.clear();
          if (window.sessionStorage) window.sessionStorage.clear();
          if (window.indexedDB && window.indexedDB.databases) {
            window.indexedDB.databases().then(function(dbs) {
              if (dbs) {
                for (var i = 0; i < dbs.length; i++) {
                  if (dbs[i].name) {
                    window.indexedDB.deleteDatabase(dbs[i].name);
                  }
                }
              }
            });
          }
        } catch (e) {}
      })();
    ''';

    try {
      await _controller.evaluateJavascript(source: clearStorageJs);
    } catch (_) {
      // Continue even if JS storage wipe fails due to page state
    }

    // 4. Return to the start inbox URL (which will cleanly present the login page)
    await loadInbox();
  }
}
