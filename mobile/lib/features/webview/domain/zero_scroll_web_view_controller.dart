/// Interface defining external actions and queries supported by the WebView controller.
abstract class ZeroScrollWebViewController {
  /// Loads the Direct Messages inbox.
  Future<void> loadInbox();

  /// Loads a specific Direct Message thread by thread ID.
  Future<void> loadThread(String threadId);

  /// Loads the Notifications and Activity view.
  Future<void> loadNotifications();

  /// Returns the current active URL in the WebView.
  Future<String?> getCurrentUrl();

  /// Synchronously or asynchronously cached active URL string.
  String? get currentUrl;

  /// Evaluates JavaScript code within the active page.
  Future<dynamic> evaluateJs(String source);

  /// Checks whether the WebView can navigate back in its history.
  Future<bool> canGoBack();

  /// Navigates back one step in WebView history.
  Future<void> goBack();

  /// Reloads the currently loaded page.
  Future<void> reload();

  /// Clears all session data (cookies, cache, localStorage, and IndexedDB)
  /// and resets the view to the login/inbox screen.
  Future<void> clearAllSessionData();
}
