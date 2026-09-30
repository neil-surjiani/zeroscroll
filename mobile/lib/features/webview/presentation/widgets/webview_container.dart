import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../limits/presentation/providers/limits_state_provider.dart';
import '../../../limits/presentation/providers/reel_budget_provider.dart';
import '../../../limits/presentation/providers/story_budget_provider.dart';
import '../../../limits/presentation/widgets/reply_friction_dialog.dart';
import '../../../remote_config/presentation/providers/remote_config_provider.dart';
import '../../../security/presentation/providers/debug_log_provider.dart';
import '../../../settings/domain/feature_preferences.dart';
import '../../../settings/presentation/providers/feature_preferences_provider.dart';
import '../../data/webview_constants.dart';
import '../../data/zero_scroll_web_view_controller_impl.dart';
import '../../domain/webview_mode.dart';
import '../providers/webview_controller_provider.dart';
import '../providers/webview_provider.dart';

/// Guarded WebView container displaying Direct Messages and Activity with 3-layer protection
/// and isolated single-item media viewer mode.
class WebviewContainer extends ConsumerStatefulWidget {
  const WebviewContainer({
    super.key,
    this.initialUrl = WebViewConstants.directInboxUrl,
    this.customUserAgent,
    this.isMainInbox = true,
  });

  final String initialUrl;
  final String? customUserAgent;
  final bool isMainInbox;

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
    final todayReelCount = ref.watch(todayReelCountProvider);
    final todayStoryCount = ref.watch(todayStoryCountProvider);
    final featurePrefs = ref.watch(featurePreferencesProvider);
    final theme = Theme.of(context);

    // Watch Effective RouteConfig and Guard JS assets
    final config = ref.watch(effectiveRouteConfigProvider);
    final guardJsAsync = ref.watch(guardJsProvider);
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

    // Listen for effective config updates to perform live hot-reloading
    ref.listen<RouteConfig>(effectiveRouteConfigProvider, (previous, next) async {
      if (_rawController != null) {
        await _rawController!.evaluateJavascript(
          source: '''
            if (typeof window.__ZEROSCROLL_UPDATE_CONFIG__ === 'function') {
              window.__ZEROSCROLL_UPDATE_CONFIG__(${next.toJsonString()});
            }
          ''',
        );
        final currentUrl = await _rawController!.getUrl();
        if (currentUrl != null && !next.isPathAllowed(currentUrl.path)) {
          await _rawController!.loadUrl(
            urlRequest: URLRequest(url: WebUri(next.fallbackPath)),
          );
        }
      }
    });

    // Requirement 6: If kill switch is enabled, show friendly message and DO NOT load WebView
    if (config.killSwitch.enabled) {
      return KillSwitchOverlay(
        message: config.killSwitch.message,
        onRetry: () => ref.read(routeConfigRepositoryProvider).refreshConfig(),
      );
    }

    // Fail-Closed: If guard JS failed to load from assets, disable WebView
    if (guardJsAsync.hasError) {
      return Scaffold(
        body: _GuardFailedOverlay(
          onRetry: () => ref.refresh(guardJsProvider),
          errorMessage:
              'Guard script asset could not be loaded from app bundle. Fail-closed protection active.',
        ),
      );
    }

    final isViewerMode = webviewState.mode == WebviewMode.singleMediaViewer;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Requirement 6: Hardware back button closes viewer mode and returns to DMs
        if (ref.read(webviewNotifierProvider).mode ==
            WebviewMode.singleMediaViewer) {
          await _closeViewerModeAndReturnToDirect();
          return;
        }

        final controller = ref.read(webViewControllerProvider);
        if (controller != null && await controller.canGoBack()) {
          await controller.goBack();
        } else {
          // Minimize the app on Android when no web history exists
          await SystemNavigator.pop();
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Underlying guarded InAppWebView
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
            initialUserScripts: UnmodifiableListView<UserScript>([
              // LAYER 2 & 3: Injected at Document Start
              UserScript(
                source: '''
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
              isInspectable: kDebugMode,
            ),
            onWebViewCreated: (controller) {
              _rawController = controller;
              final wrapper = ZeroScrollWebViewControllerImpl(controller);
              if (widget.isMainInbox) {
                ref.read(webViewControllerProvider.notifier).state = wrapper;
              }

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

              // Requirement 1 & 7: JavaScript handler for single item viewer mode change
              controller.addJavaScriptHandler(
                handlerName: 'onViewerModeChanged',
                callback: (args) async {
                  final data = args.isNotEmpty && args[0] is Map
                      ? args[0] as Map
                      : null;
                  final isViewer = data?['isViewer'] as bool? ?? false;
                  final mediaId = data?['mediaId']?.toString();
                  final mediaType = data?['mediaType']?.toString();
                  final username = data?['username']?.toString();
                  final lastDirectPath = data?['lastDirectPath']?.toString();

                  if (isViewer) {
                    if (!context.mounted) return;
                    final limitsConfig = ref.read(limitsConfigProvider).valueOrNull;
                    if (limitsConfig != null && limitsConfig.isReplyFrictionEnabled) {
                      final canProceed = await ReplyFrictionDialog.show(context, ref);
                      if (!canProceed) {
                        await _closeViewerModeAndReturnToDirect();
                        return;
                      }
                    }

                    if (mediaType == 'story') {
                      final canOpen = await ref
                          .read(storyBudgetServiceProvider)
                          .canOpenStory();
                      if (!canOpen) {
                        ref
                            .read(webviewNotifierProvider.notifier)
                            .setStoryBudgetReached(true);
                        await controller.evaluateJavascript(
                          source:
                              'var v = document.querySelector("video"); if (v) v.pause();',
                        );
                      } else {
                        ref
                            .read(webviewNotifierProvider.notifier)
                            .setStoryBudgetReached(false);
                        await ref
                            .read(todayStoryCountProvider.notifier)
                            .recordStoryOpened();
                      }
                    } else {
                      final canOpen = await ref
                          .read(reelBudgetServiceProvider)
                          .canOpenReel();
                      if (!canOpen) {
                        ref
                            .read(webviewNotifierProvider.notifier)
                            .setBudgetReached(true);
                        await controller.evaluateJavascript(
                          source:
                              'var v = document.querySelector("video"); if (v) v.pause();',
                        );
                      } else {
                        ref
                            .read(webviewNotifierProvider.notifier)
                            .setBudgetReached(false);
                        await ref
                            .read(todayReelCountProvider.notifier)
                            .recordReelOpened();
                      }
                    }
                  }

                  ref
                      .read(webviewNotifierProvider.notifier)
                      .setViewerMode(
                        isViewer: isViewer,
                        mediaId: mediaId,
                        mediaType: mediaType,
                        username: username,
                        lastDirectPath: lastDirectPath,
                      );
                },
              );

              // Requirement 3: Handler for blocked next-reel transitions
              controller.addJavaScriptHandler(
                handlerName: 'onNextReelBlocked',
                callback: (args) {
                  final data = args.isNotEmpty && args[0] is Map
                      ? args[0] as Map
                      : null;
                  final message =
                      data?['message']?.toString() ??
                      config.viewerConfig.lastReelMessage;
                  _showLastReelToast(message);
                },
              );

              // Requirement 3: Handler for blocked next-story transitions (different user)
              controller.addJavaScriptHandler(
                handlerName: 'onNextStoryUserBlocked',
                callback: (args) async {
                  final data = args.isNotEmpty && args[0] is Map
                      ? args[0] as Map
                      : null;
                  final message = data?['message']?.toString() ??
                      "That was the last story from this user.";
                  _showLastReelToast(message);
                  await _closeViewerModeAndReturnToDirect();
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

              if (url != null) {
                final host = url.host.toLowerCase();
                if (host.contains(WebViewConstants.allowedHost)) {
                  final path = url.path;

                  // Check if this is a viewer path
                  if (config.isViewerPath(path)) {
                    final currentId = ref
                        .read(webviewNotifierProvider)
                        .currentMediaId;
                    final targetId = _extractMediaId(path);

                    // If moving from one reel to another reel in viewer mode
                    if (currentId != null &&
                        targetId != null &&
                        currentId != targetId) {
                      controller.stopLoading();
                      _showLastReelToast(config.viewerConfig.lastReelMessage);
                      controller.goBack();
                      return;
                    }
                  }

                  // Check if this is a story viewer path
                  final storyInfo = _extractStoryInfo(path);
                  if (storyInfo != null) {
                    final currentViewerUser = ref
                        .read(webviewNotifierProvider)
                        .currentViewerUsername;
                    if (currentViewerUser != null &&
                        storyInfo.username.isNotEmpty &&
                        currentViewerUser != storyInfo.username) {
                      controller.stopLoading();
                      _showLastReelToast(
                        "That was the last story from @$currentViewerUser.",
                      );
                      _closeViewerModeAndReturnToDirect();
                      return;
                    }

                    // In fromDmsOnly mode, verify story is opened from DMs
                    if (featurePrefs.storiesViewMode ==
                        StoriesViewMode.fromDmsOnly) {
                      final lastDirect =
                          ref.read(webviewNotifierProvider).lastDirectPath;
                      final currentUrl =
                          ref.read(webviewNotifierProvider).currentUrl;
                      final prevPath = currentUrl != null
                          ? (Uri.tryParse(currentUrl)?.path ?? '')
                          : '';
                      final isFromDm = prevPath.contains('/direct/') ||
                          lastDirect.contains('/direct/');
                      if (!isFromDm) {
                        ref
                            .read(debugLogProvider.notifier)
                            .addBlockedNavigation(path, urlString ?? '');
                        _showBlockedToast(path);
                        controller.stopLoading();
                        final fallback = WebUri(
                          'https://${url.host}${config.fallbackPath}',
                        );
                        controller.loadUrl(urlRequest: URLRequest(url: fallback));
                        return;
                      }
                    }
                  }

                  // LAYER 1: Check in Dart on load start
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

              // Check if loaded page is a viewer page directly
              final isStoryPage = _extractStoryInfo(url?.path ?? '') != null;
              if (url != null && (config.isViewerPath(url.path) || isStoryPage)) {
                if (!context.mounted) return;
                final limitsConfig = ref.read(limitsConfigProvider).valueOrNull;
                if (limitsConfig != null && limitsConfig.isReplyFrictionEnabled) {
                  final canProceed = await ReplyFrictionDialog.show(context, ref);
                  if (!canProceed) {
                    await _closeViewerModeAndReturnToDirect();
                    return;
                  }
                }

                if (isStoryPage) {
                  final canOpen = await ref
                      .read(storyBudgetServiceProvider)
                      .canOpenStory();
                  if (!canOpen) {
                    ref
                        .read(webviewNotifierProvider.notifier)
                        .setStoryBudgetReached(true);
                    await controller.evaluateJavascript(
                      source:
                          'var v = document.querySelector("video"); if (v) v.pause();',
                    );
                  } else {
                    ref
                        .read(webviewNotifierProvider.notifier)
                        .setStoryBudgetReached(false);
                  }
                } else {
                  final canOpen = await ref
                      .read(reelBudgetServiceProvider)
                      .canOpenReel();
                  if (!canOpen) {
                    ref
                        .read(webviewNotifierProvider.notifier)
                        .setBudgetReached(true);
                    await controller.evaluateJavascript(
                      source:
                          'var v = document.querySelector("video"); if (v) v.pause();',
                    );
                  } else {
                    ref
                        .read(webviewNotifierProvider.notifier)
                        .setBudgetReached(false);
                  }
                }
              }

              // Ensure CSS hiding and location checks remain active after complete load
              await controller.evaluateJavascript(
                source: '''
                (function() {
                  if (typeof checkCurrentLocation === 'function') checkCurrentLocation();
                  if (typeof applyCss === 'function') applyCss();
                })();
              ''',
              );

              // Fail-closed verification: ensure the guard script initialized on the loaded page
              if (url != null && !url.toString().contains('about:blank')) {
                try {
                  final guardInit = await controller.evaluateJavascript(
                    source:
                        'Boolean(window.__ZEROSCROLL_GUARD_INITIALIZED__ === true);',
                  );
                  if (guardInit == false || guardInit == 0 || guardInit == 'false') {
                    await controller.stopLoading();
                    await controller.loadUrl(
                      urlRequest: URLRequest(url: WebUri('about:blank')),
                    );
                    ref
                        .read(webviewNotifierProvider.notifier)
                        .onGuardFailure(
                          'Page protection guard failed to initialize. Web access disabled.',
                        );
                    return;
                  }
                } catch (e) {
                  await controller.stopLoading();
                  await controller.loadUrl(
                    urlRequest: URLRequest(url: WebUri('about:blank')),
                  );
                  ref
                      .read(webviewNotifierProvider.notifier)
                      .onGuardFailure('Guard verification error: $e');
                  return;
                }
              }
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
                _confirmAndLaunchExternalUrl(context, uri);
                return NavigationActionPolicy.CANCEL;
              }

              // LAYER 1: Allowed Instagram path check
              if (host.contains(WebViewConstants.allowedHost)) {
                final path = uri.path;

                // Viewer mode next-reel check
                if (config.isViewerPath(path)) {
                  final currentId = ref
                      .read(webviewNotifierProvider)
                      .currentMediaId;
                  final targetId = _extractMediaId(path);
                  if (currentId != null &&
                      targetId != null &&
                      currentId != targetId) {
                    _showLastReelToast(config.viewerConfig.lastReelMessage);
                    return NavigationActionPolicy.CANCEL;
                  }
                }

                // Story viewer single-user check
                final storyInfo = _extractStoryInfo(path);
                if (storyInfo != null) {
                  final currentViewerUser = ref
                      .read(webviewNotifierProvider)
                      .currentViewerUsername;
                  if (currentViewerUser != null &&
                      storyInfo.username.isNotEmpty &&
                      currentViewerUser != storyInfo.username) {
                    _showLastReelToast(
                      "That was the last story from @$currentViewerUser.",
                    );
                    _closeViewerModeAndReturnToDirect();
                    return NavigationActionPolicy.CANCEL;
                  }

                  if (featurePrefs.storiesViewMode ==
                      StoriesViewMode.fromDmsOnly) {
                    final lastDirect =
                        ref.read(webviewNotifierProvider).lastDirectPath;
                    final currentUrl =
                        ref.read(webviewNotifierProvider).currentUrl;
                    final prevPath = currentUrl != null
                        ? (Uri.tryParse(currentUrl)?.path ?? '')
                        : '';
                    final isFromDm = prevPath.contains('/direct/') ||
                        lastDirect.contains('/direct/');
                    if (!isFromDm) {
                      ref.read(debugLogProvider.notifier).addBlockedNavigation(
                            path,
                            uri.toString(),
                          );
                      _showBlockedToast(path);
                      final fallback = WebUri(
                        'https://${uri.host}${config.fallbackPath}',
                      );
                      controller.loadUrl(urlRequest: URLRequest(url: fallback));
                      return NavigationActionPolicy.CANCEL;
                    }
                  }
                }

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

          // Initial Loading Placeholder
          if (webviewState.isLoading &&
              webviewState.progress < 0.25 &&
              !webviewState.hasAnyError &&
              !isViewerMode)
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

          // Fail-closed Guard Failure Overlay
          if (webviewState.isGuardFailed)
            _GuardFailedOverlay(
              errorMessage: webviewState.errorMessage,
              onRetry: _retryLoading,
            ),

          // Requirement 5: Persistent top bar overlay with Close button and today's reel/story count
          if (isViewerMode &&
              !webviewState.showBudgetReached &&
              !webviewState.showStoryBudgetReached)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.85),
                        Colors.black.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Semantics(
                        button: true,
                        label: 'Close viewer and return to Direct Messages',
                        child: FilledButton.icon(
                          key: const ValueKey('viewer_close_button'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            minimumSize: const Size(48, 48),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: _closeViewerModeAndReturnToDirect,
                          icon: const Icon(Icons.close_rounded, size: 22),
                          label: const Text(
                            'Close',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      Semantics(
                        label: webviewState.isStoryViewer
                            ? '$todayStoryCount stories viewed today'
                            : '$todayReelCount reels viewed today',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                webviewState.isStoryViewer
                                    ? Icons.amp_stories_outlined
                                    : Icons.play_circle_outline_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                webviewState.isStoryViewer
                                    ? 'Stories today: $todayStoryCount'
                                    : 'Reels today: $todayReelCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Requirement 7: Reel Budget Reached Screen Overlay
          if (webviewState.showBudgetReached)
            Positioned.fill(
              child: Container(
                color: theme.scaffoldBackgroundColor,
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer.withValues(
                            alpha: 0.35,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.timer_off_outlined,
                          size: 64,
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Daily Reel Budget Reached',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'You have reached your daily reel budget. Close the viewer to return to your direct messages.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        key: const ValueKey('budget_return_button'),
                        onPressed: _closeViewerModeAndReturnToDirect,
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Return to Messages'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Requirement 3: Story Budget Reached Screen Overlay
          if (webviewState.showStoryBudgetReached)
            Positioned.fill(
              child: Container(
                color: theme.scaffoldBackgroundColor,
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer.withValues(
                            alpha: 0.35,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.timer_off_outlined,
                          size: 64,
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Daily Story Limit Reached',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'You have reached your daily story limit (${featurePrefs.dailyStoryLimit ?? 10}). Close the viewer to return to your direct messages.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        key: const ValueKey('story_budget_return_button'),
                        onPressed: _closeViewerModeAndReturnToDirect,
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Return to Messages'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Closes viewer mode and navigates history back until a Direct Messages path is reached.
  Future<void> _closeViewerModeAndReturnToDirect() async {
    final controller = _rawController;
    final lastDirectPath = ref.read(webviewNotifierProvider).lastDirectPath;
    ref.read(webviewNotifierProvider.notifier).setViewerMode(isViewer: false);

    if (controller != null) {
      try {
        final history = await controller.getCopyBackForwardList();
        if (history != null &&
            history.currentIndex != null &&
            history.list != null) {
          final currentIndex = history.currentIndex!;
          final list = history.list!;
          int? targetIndex;
          for (int i = currentIndex - 1; i >= 0; i--) {
            final path = list[i].url?.path ?? '';
            final full = list[i].url?.toString() ?? '';
            if (path.contains('/direct/') || full.contains('/direct/')) {
              targetIndex = i;
              break;
            }
          }
          if (targetIndex != null) {
            final steps = targetIndex - currentIndex;
            await controller.goBackOrForward(steps: steps);
            return;
          }
        }
      } catch (_) {}

      // Fallback directly to last direct path or inbox
      final host = WebViewConstants.allowedHost;
      final target = WebUri('https://$host$lastDirectPath');
      await controller.loadUrl(urlRequest: URLRequest(url: target));
    }
  }

  String? _extractMediaId(String path) {
    final match = RegExp(r'^/(?:reel|reels|p)/([^/]+)').firstMatch(path);
    return match?.group(1);
  }

  ({String username, String storyId})? _extractStoryInfo(String path) {
    final match =
        RegExp(r'^/stories/(?!create/)([^/]+)/([^/?#]+)').firstMatch(path);
    if (match != null) {
      return (username: match.group(1) ?? '', storyId: match.group(2) ?? '');
    }
    return null;
  }

  void _retryLoading() {
    ref.read(webviewNotifierProvider.notifier).clearError();
    if (_rawController != null) {
      _rawController!.loadUrl(
        urlRequest: URLRequest(url: WebUri(widget.initialUrl)),
      );
    } else {
      setState(() {});
    }
  }

  void _showBlockedToast(String path) {
    if (!mounted) return;
    final isReel = path.contains('/reel/') || path.contains('/reels/');
    final message = isReel
        ? 'Reels are disabled in ZeroScroll.'
        : 'Blocked by ZeroScroll: $path';
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.shield_outlined, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
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

  void _showLastReelToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E2229),
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

  @override
  void dispose() {
    _rawController = null;
    _controllerWrapper = null;
    super.dispose();
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

/// Fail-closed overlay shown if guard JS fails to inject or cannot be verified.
class _GuardFailedOverlay extends StatelessWidget {
  const _GuardFailedOverlay({
    required this.onRetry,
    this.errorMessage,
  });

  final VoidCallback onRetry;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: const ValueKey('guard_failed_overlay'),
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shield_rounded,
                size: 64,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Security Guard Offline',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              errorMessage ??
                  'ZeroScroll could not verify the page protection guard on this page. '
                  'To protect your attention and ensure no unshielded feeds are exposed, web access is paused (fail-closed).',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const ValueKey('guard_retry_btn'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Connection'),
            ),
          ],
        ),
      ),
    );
  }
}
