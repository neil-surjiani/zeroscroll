import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../remote_config/data/remote_config_repository.dart';
import '../../../remote_config/domain/route_config.dart';
import '../../../security/presentation/providers/debug_log_provider.dart';
import '../../data/webview_constants.dart';
import '../../data/zero_scroll_web_view_controller_impl.dart';
import '../providers/webview_controller_provider.dart';
import '../providers/webview_provider.dart';

/// Guarded WebView container displaying Direct Messages and Activity with 3-layer protection.
class WebviewContainer extends ConsumerStatefulWidget {
  const WebviewContainer({
    super.key,
    this.initialUrl = WebViewConstants.directInboxUrl,
    this.customUserAgent,
  });

  final String initialUrl;
  final String? customUserAgent;

  @override
  ConsumerState<WebviewContainer> createState() => _WebviewContainerState();
}

class _WebviewContainerState extends ConsumerState<WebviewContainer>
    with AutomaticKeepAliveClientMixin {
  InAppWebViewController? _rawController;
  ZeroScrollWebViewControllerImpl? _controllerWrapper;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final webviewState = ref.watch(webviewNotifierProvider);
    final theme = Theme.of(context);

    // Watch RouteConfig and Guard JS assets
    final routeConfigAsync = ref.watch(routeConfigProvider);
    final guardJsAsync = ref.watch(guardJsProvider);

    final config =
        routeConfigAsync.valueOrNull ??
        const RouteConfig(
          version: 1,
          userAgent: WebViewConstants.defaultUserAgent,
          fallbackPath: '/direct/inbox/',
          allowedPaths: [
            r'^/direct/',
            r'^/accounts/login',
            r'^/accounts/activity',
            r'^/accounts/onetap',
            r'^/challenge/',
            r'^/two_factor/',
            r'^/accounts/suspended',
            r'^/reel/[^/]+/?$',
            r'^/reels/[^/]+/?$',
            r'^/p/[^/]+/?$',
          ],
          alwaysBlockedPaths: [
            r'^/$',
            r'^/explore',
            r'^/reels/?$',
            r'^/stories/',
            r'^/accounts/edit',
            r'^/(?!direct|accounts|challenge|two_factor|reel|reels|p|legal|static)[a-zA-Z0-9._]+/?$',
          ],
          hideSelectors: [
            "a[href='/']",
            "a[href^='/explore']",
            "a[href^='/reels']",
            "a[aria-label='Home']",
            "a[aria-label='Search']",
            "a[aria-label='Reels']",
            "section[aria-label='Stories']",
            "div[aria-label*='Stories']",
            "div[data-testid='story-tray']",
          ],
        );

    final guardJs = guardJsAsync.valueOrNull ?? '';
    final userAgent =
        widget.customUserAgent ??
        (config.userAgent.isNotEmpty
            ? config.userAgent
            : WebViewConstants.defaultUserAgent);

    // Sync active config version to debug state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(debugLogProvider.notifier).setConfigVersion(config.version);
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final controller = ref.read(webViewControllerProvider);
        if (controller != null && await controller.canGoBack()) {
          await controller.goBack();
        } else {
          // Minimize the app on Android when no web history exists
          await SystemNavigator.pop();
        }
      },
      child: Stack(
        children: [
          // Underlying guarded InAppWebView
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
            initialUserScripts: UnmodifiableListView<UserScript>([
              // LAYER 2 & 3: Injected at Document Start
              UserScript(
                source:
                    '''
                  window.__ZEROSCROLL_CONFIG__ = Object.freeze(${config.toJsonString()});
                  $guardJs
                ''',
                injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                forMainFrameOnly: false,
              ),
            ]),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              domStorageEnabled: true,
              thirdPartyCookiesEnabled: true,
              mediaPlaybackRequiresUserGesture: true,
              mixedContentMode: MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
              allowFileAccess: false,
              allowContentAccess: false,
              safeBrowsingEnabled: true,
              userAgent: userAgent,
              useHybridComposition: true,
              cacheEnabled: true,
              transparentBackground: false,
              supportMultipleWindows: false,
              allowsInlineMediaPlayback: true,
            ),
            onWebViewCreated: (controller) {
              _rawController = controller;
              final wrapper = ZeroScrollWebViewControllerImpl(controller);
              _controllerWrapper = wrapper;
              ref.read(webViewControllerProvider.notifier).state = wrapper;

              // Register JavaScript bridge for Layer 2 blocked toast notifications
              controller.addJavaScriptHandler(
                handlerName: 'onNavigationBlocked',
                callback: (args) {
                  final data = args.isNotEmpty && args[0] is Map
                      ? args[0] as Map
                      : null;
                  final path = data?['path']?.toString() ?? '';
                  final url = data?['url']?.toString() ?? '';
                  ref
                      .read(debugLogProvider.notifier)
                      .addBlockedNavigation(path, url);
                  _showBlockedToast(path);
                },
              );
            },
            onConsoleMessage: (controller, consoleMessage) {
              ref
                  .read(debugLogProvider.notifier)
                  .addConsoleLog(
                    consoleMessage.message,
                    consoleMessage.messageLevel.toString(),
                  );
            },
            onLoadStart: (controller, url) {
              final urlString = url?.toString();
              _controllerWrapper?.updateCachedUrl(urlString);
              ref.read(debugLogProvider.notifier).setCurrentUrl(urlString);
              ref.read(webviewNotifierProvider.notifier).onLoadStart(urlString);

              // LAYER 1: Check in Dart on load start
              if (url != null) {
                final host = url.host.toLowerCase();
                if (host.contains(WebViewConstants.allowedHost)) {
                  final path = url.path;
                  if (!config.isPathAllowed(path)) {
                    ref
                        .read(debugLogProvider.notifier)
                        .addBlockedNavigation(path, urlString ?? '');
                    _showBlockedToast(path);
                    controller.stopLoading();
                    final fallback = WebUri(
                      'https://${url.host}${config.fallbackPath}',
                    );
                    controller.loadUrl(urlRequest: URLRequest(url: fallback));
                  }
                }
              }
            },
            onProgressChanged: (controller, progress) {
              ref
                  .read(webviewNotifierProvider.notifier)
                  .onProgressChanged(progress);
            },
            onLoadStop: (controller, url) async {
              final urlString = url?.toString();
              _controllerWrapper?.updateCachedUrl(urlString);
              ref.read(debugLogProvider.notifier).setCurrentUrl(urlString);
              final canGoBack = await controller.canGoBack();
              ref
                  .read(webviewNotifierProvider.notifier)
                  .onLoadStop(urlString, canGoBack: canGoBack);

              // Ensure CSS hiding and location checks remain active after complete load
              await controller.evaluateJavascript(
                source: '''
                (function() {
                  if (typeof checkCurrentLocation === 'function') checkCurrentLocation();
                  if (typeof applyCss === 'function') applyCss();
                })();
              ''',
              );
            },
            onReceivedError: (controller, request, error) {
              final isMainFrame = request.isForMainFrame ?? true;
              if (isMainFrame) {
                ref
                    .read(webviewNotifierProvider.notifier)
                    .onOfflineError(error.description);
              }
            },
            onReceivedHttpError: (controller, request, errorResponse) {
              final isMainFrame = request.isForMainFrame ?? true;
              if (isMainFrame) {
                final statusCode = errorResponse.statusCode ?? 500;
                if (statusCode >= 400) {
                  ref
                      .read(webviewNotifierProvider.notifier)
                      .onHttpError(statusCode, errorResponse.reasonPhrase);
                }
              }
            },
            onReceivedServerTrustAuthRequest: (controller, challenge) async {
              ref
                  .read(webviewNotifierProvider.notifier)
                  .onSslError(
                    'SSL certificate validation failed for ${challenge.protectionSpace.host}',
                  );
              return ServerTrustAuthResponse(
                action: ServerTrustAuthResponseAction.CANCEL,
              );
            },
            onPermissionRequest: (controller, request) async {
              return PermissionResponse(
                resources: request.resources,
                action: PermissionResponseAction.GRANT,
              );
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final uri = navigationAction.request.url;
              if (uri == null) return NavigationActionPolicy.ALLOW;

              final host = uri.host.toLowerCase();

              // LAYER 1: Host check
              if (!config.isHostAllowed(host)) {
                // Cancel navigation and prompt to open external URL in system browser
                _confirmAndLaunchExternalUrl(context, uri);
                return NavigationActionPolicy.CANCEL;
              }

              // LAYER 1: Allowed Instagram path check
              if (host.contains(WebViewConstants.allowedHost)) {
                final path = uri.path;
                if (!config.isPathAllowed(path)) {
                  ref
                      .read(debugLogProvider.notifier)
                      .addBlockedNavigation(path, uri.toString());
                  _showBlockedToast(path);

                  final fallback = WebUri(
                    'https://${uri.host}${config.fallbackPath}',
                  );
                  controller.loadUrl(urlRequest: URLRequest(url: fallback));
                  return NavigationActionPolicy.CANCEL;
                }
              }

              return NavigationActionPolicy.ALLOW;
            },
          ),

          // Loading Progress Bar Overlay
          if (webviewState.isLoading && !webviewState.hasAnyError)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: webviewState.progress > 0 ? webviewState.progress : null,
                minHeight: 2.5,
                backgroundColor: Colors.transparent,
                color: theme.colorScheme.primary,
              ),
            ),

          // Initial Loading Placeholder (prevents blank white screen on cold start)
          if (webviewState.isLoading &&
              webviewState.progress < 0.25 &&
              !webviewState.hasAnyError)
            Container(
              color: theme.colorScheme.surface,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                      strokeWidth: 2.5,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading messages...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Offline Error Overlay
          if (webviewState.isOffline)
            _OfflineErrorOverlay(onRetry: _retryLoading),

          // SSL / HTTP Error Overlay
          if (webviewState.isSslError || webviewState.hasHttpError)
            _GenericErrorOverlay(
              errorMessage: webviewState.errorMessage,
              isSsl: webviewState.isSslError,
              onRetry: _retryLoading,
            ),
        ],
      ),
    );
  }

  void _retryLoading() {
    ref.read(webviewNotifierProvider.notifier).clearError();
    if (_rawController != null) {
      _rawController!.reload();
    } else {
      setState(() {});
    }
  }

  void _showBlockedToast(String path) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.shield_outlined, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Blocked by ZeroScroll: $path',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF22272E),
      ),
    );
  }

  Future<void> _confirmAndLaunchExternalUrl(
    BuildContext context,
    WebUri uri,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Open External Link?'),
        content: Text(
          'ZeroScroll is a distraction-free container. This link leads to an external website:\n\n${uri.toString()}\n\nWould you like to open it in your system browser?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Open in Browser'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final parsed = Uri.parse(uri.toString());
        if (await canLaunchUrl(parsed)) {
          await launchUrl(parsed, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    }
  }
}

class _OfflineErrorOverlay extends StatelessWidget {
  const _OfflineErrorOverlay({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'No Internet Connection',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ZeroScroll requires a network connection to load your direct messages.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenericErrorOverlay extends StatelessWidget {
  const _GenericErrorOverlay({
    required this.errorMessage,
    required this.isSsl,
    required this.onRetry,
  });

  final String? errorMessage;
  final bool isSsl;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSsl ? Icons.gpp_bad_outlined : Icons.error_outline_rounded,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              isSsl ? 'Secure Connection Failed' : 'Page Error Occurred',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Failed to load page securely.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
