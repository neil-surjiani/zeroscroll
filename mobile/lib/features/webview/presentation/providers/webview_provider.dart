import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/webview_mode.dart';

/// Presentation state for the guarded WebView container.
class WebviewState {
  const WebviewState({
    this.mode = WebviewMode.directMessages,
    this.isLoading = true,
    this.progress = 0.0,
    this.isOffline = false,
    this.isSslError = false,
    this.hasHttpError = false,
    this.httpStatusCode,
    this.errorMessage,
    this.canGoBack = false,
    this.currentUrl,
  });

  final WebviewMode mode;
  final bool isLoading;
  final double progress;
  final bool isOffline;
  final bool isSslError;
  final bool hasHttpError;
  final int? httpStatusCode;
  final String? errorMessage;
  final bool canGoBack;
  final String? currentUrl;

  bool get hasAnyError => isOffline || isSslError || hasHttpError;

  WebviewState copyWith({
    WebviewMode? mode,
    bool? isLoading,
    double? progress,
    bool? isOffline,
    bool? isSslError,
    bool? hasHttpError,
    int? httpStatusCode,
    String? errorMessage,
    bool? canGoBack,
    String? currentUrl,
    bool resetErrors = false,
  }) {
    return WebviewState(
      mode: mode ?? this.mode,
      isLoading: isLoading ?? this.isLoading,
      progress: progress ?? this.progress,
      isOffline: resetErrors ? false : (isOffline ?? this.isOffline),
      isSslError: resetErrors ? false : (isSslError ?? this.isSslError),
      hasHttpError: resetErrors ? false : (hasHttpError ?? this.hasHttpError),
      httpStatusCode: resetErrors
          ? null
          : (httpStatusCode ?? this.httpStatusCode),
      errorMessage: resetErrors ? null : (errorMessage ?? this.errorMessage),
      canGoBack: canGoBack ?? this.canGoBack,
      currentUrl: currentUrl ?? this.currentUrl,
    );
  }
}

/// State notifier managing webview loading, progress, error, and navigation states.
class WebviewNotifier extends StateNotifier<WebviewState> {
  WebviewNotifier() : super(const WebviewState());

  void setMode(WebviewMode mode) {
    state = state.copyWith(mode: mode);
  }

  void onLoadStart(String? url) {
    state = state.copyWith(
      isLoading: true,
      progress: 0.1,
      currentUrl: url,
      resetErrors: true,
    );
  }

  void onProgressChanged(int progress) {
    state = state.copyWith(
      progress: progress / 100.0,
      isLoading: progress < 100,
    );
  }

  void onLoadStop(String? url, {bool canGoBack = false}) {
    state = state.copyWith(
      isLoading: false,
      progress: 1.0,
      currentUrl: url,
      canGoBack: canGoBack,
    );
  }

  void onOfflineError([String? description]) {
    state = state.copyWith(
      isLoading: false,
      isOffline: true,
      errorMessage: description ?? 'Unable to connect to the internet.',
    );
  }

  void onSslError([String? description]) {
    state = state.copyWith(
      isLoading: false,
      isSslError: true,
      errorMessage:
          description ?? 'Secure SSL connection could not be established.',
    );
  }

  void onHttpError(int statusCode, [String? description]) {
    state = state.copyWith(
      isLoading: false,
      hasHttpError: true,
      httpStatusCode: statusCode,
      errorMessage: description ?? 'Received HTTP error ($statusCode).',
    );
  }

  void updateCanGoBack(bool canGoBack) {
    state = state.copyWith(canGoBack: canGoBack);
  }

  void clearError() {
    state = state.copyWith(resetErrors: true);
  }
}

final webviewNotifierProvider =
    StateNotifierProvider<WebviewNotifier, WebviewState>((ref) {
      return WebviewNotifier();
    });
