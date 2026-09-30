import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../limits/presentation/providers/limits_state_provider.dart';
import '../../../limits/presentation/providers/story_budget_provider.dart';
import '../../../limits/presentation/widgets/reply_friction_dialog.dart';
import '../../../remote_config/presentation/providers/remote_config_provider.dart';
import '../../../webview/data/webview_constants.dart';

/// Isolated Story Tray screen for [StoriesViewMode.fromFollowing].
///
/// Loads the home page strictly in tray-only mode, suppressing algorithmic feeds.
/// Enforces fail-closed protection: if the tray cannot be found within 5 seconds,
/// or if feed posts are detected, the container displays a focus-protective fallback.
class StoriesTrayScreen extends ConsumerStatefulWidget {
  const StoriesTrayScreen({super.key});

  @override
  ConsumerState<StoriesTrayScreen> createState() => _StoriesTrayScreenState();
}

class _StoriesTrayScreenState extends ConsumerState<StoriesTrayScreen>
    with AutomaticKeepAliveClientMixin {
  InAppWebViewController? _controller;
  bool _isTrayLoaded = false;
  bool _isFailClosed = false;
  bool _isStoryViewerMode = false;
  String? _currentStoryUser;
  bool _storyBudgetReached = false;
  Timer? _failClosedTimer;

  static const String _trayCss = '''
    /* STRICT FAIL-CLOSED TRAY ISOLATION: Hide algorithmic feed, explore, suggestions, navigation */
    article,
    [role='feed'],
    div[data-testid='post-container'],
    div:has(> article),
    main > div > div > div:nth-child(2),
    div[data-testid='mobile-top-nav'],
    div[data-testid='mobile-nav'],
    div[role='tablist'],
    div[role='banner'],
    div:has(> a[href*='play.google.com']),
    div:has(> a[href*='apps.apple.com']) {
      display: none !important;
      visibility: hidden !important;
      height: 0 !important;
      overflow: hidden !important;
      pointer-events: none !important;
      opacity: 0 !important;
    }

    /* Keep ONLY story tray visible */
    div[data-testid='story-tray'],
    section[aria-label='Stories'],
    div[aria-label*='Stories'],
    header:has(div[role='menu']) {
      display: block !important;
      visibility: visible !important;
      pointer-events: auto !important;
      opacity: 1 !important;
    }
  ''';

  static const String _trayDetectorJs = '''
    (function() {
      function checkTray() {
        var tray = document.querySelector("div[data-testid='story-tray'], section[aria-label='Stories'], div[aria-label*='Stories'], header div[role='menu']");
        var articles = document.querySelectorAll("article, [role='feed']");
        var feedDetected = false;
        for (var i = 0; i < articles.length; i++) {
          var el = articles[i];
          if (el.offsetHeight > 40 && window.getComputedStyle(el).display !== 'none') {
            feedDetected = true;
            break;
          }
        }
        if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
          window.flutter_inappwebview.callHandler('onTrayStatus', {
            found: !!tray,
            feedDetected: feedDetected
          });
        }
      }
      setInterval(checkTray, 350);
      checkTray();
    })();
  ''';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _startFailClosedTimer();
  }

  void _startFailClosedTimer() {
    _failClosedTimer?.cancel();
    _failClosedTimer = Timer(const Duration(seconds: 5), () {
      if (!_isTrayLoaded && mounted) {
        setState(() {
          _isFailClosed = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _failClosedTimer?.cancel();
    super.dispose();
  }

  void _retryLoading() {
    setState(() {
      _isFailClosed = false;
      _isTrayLoaded = false;
    });
    _startFailClosedTimer();
    _controller?.reload();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final todayStories = ref.watch(todayStoryCountProvider);
    final config = ref.watch(effectiveRouteConfigProvider);
    final guardJsAsync = ref.watch(guardJsProvider);
    final guardJs = guardJsAsync.valueOrNull ?? '';

    if (_isFailClosed) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.35,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Stories are unavailable right now.',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'ZeroScroll hides the feed to protect your focus. We could not safely isolate the story tray without exposing algorithmic posts.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _retryLoading,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_isStoryViewerMode) {
          await _closeStoryViewer();
          return;
        }
        if (_controller != null && await _controller!.canGoBack()) {
          await _controller!.goBack();
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri('https://${WebViewConstants.allowedHost}/'),
            ),
            initialUserScripts: UnmodifiableListView<UserScript>([
              UserScript(
                source: '''
                  window.__ZEROSCROLL_CONFIG__ = Object.freeze(${config.toJsonString()});
                  $guardJs
                  var style = document.createElement('style');
                  style.textContent = `$_trayCss`;
                  document.documentElement.appendChild(style);
                  $_trayDetectorJs
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
              safeBrowsingEnabled: true,
              userAgent: config.userAgent.isNotEmpty
                  ? config.userAgent
                  : WebViewConstants.defaultUserAgent,
              useHybridComposition: true,
              cacheEnabled: true,
              isInspectable: kDebugMode,
            ),
            onWebViewCreated: (controller) {
              _controller = controller;

              controller.addJavaScriptHandler(
                handlerName: 'onTrayStatus',
                callback: (args) {
                  final data = args.isNotEmpty && args[0] is Map
                      ? args[0] as Map
                      : null;
                  final found = data?['found'] as bool? ?? false;
                  final feedDetected =
                      data?['feedDetected'] as bool? ?? false;

                  if (feedDetected) {
                    _failClosedTimer?.cancel();
                    if (mounted) {
                      setState(() {
                        _isFailClosed = true;
                      });
                    }
                    return;
                  }

                  if (found && !_isTrayLoaded) {
                    _failClosedTimer?.cancel();
                    if (mounted) {
                      setState(() {
                        _isTrayLoaded = true;
                      });
                    }
                  }
                },
              );

              controller.addJavaScriptHandler(
                handlerName: 'onViewerModeChanged',
                callback: (args) async {
                  final data = args.isNotEmpty && args[0] is Map
                      ? args[0] as Map
                      : null;
                  final isViewer = data?['isViewer'] as bool? ?? false;
                  final mediaType = data?['mediaType']?.toString();
                  final username = data?['username']?.toString();

                  if (isViewer && mediaType == 'story') {
                    final limitsConfig =
                        ref.read(limitsConfigProvider).valueOrNull;
                    if (limitsConfig != null &&
                        limitsConfig.isReplyFrictionEnabled &&
                        context.mounted) {
                      final canProceed =
                          await ReplyFrictionDialog.show(context, ref);
                      if (!canProceed) {
                        await _closeStoryViewer();
                        return;
                      }
                    }

                    final canOpen = await ref
                        .read(storyBudgetServiceProvider)
                        .canOpenStory(username);
                    if (!canOpen) {
                      if (mounted) {
                        setState(() {
                          _storyBudgetReached = true;
                        });
                      }
                      await controller.evaluateJavascript(
                        source:
                            'var v = document.querySelector("video"); if (v) v.pause();',
                      );
                    } else {
                      if (mounted) {
                        setState(() {
                          _storyBudgetReached = false;
                        });
                      }
                      await ref
                          .read(todayStoryCountProvider.notifier)
                          .recordStoryViewed(username);
                    }
                  }

                  if (mounted) {
                    setState(() {
                      _isStoryViewerMode = isViewer;
                      _currentStoryUser = username;
                    });
                  }
                },
              );

              controller.addJavaScriptHandler(
                handlerName: 'onNextStoryUserBlocked',
                callback: (args) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Story ended. ZeroScroll blocks advancing to other accounts.',
                      ),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              );
            },
            onLoadStart: (controller, url) {
              final path = url?.path ?? '';
              if (path.startsWith('/stories/')) {
                final targetUser = _extractStoryUsername(path);
                if (_currentStoryUser != null &&
                    targetUser != null &&
                    _currentStoryUser != targetUser) {
                  controller.stopLoading();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Story ended. ZeroScroll blocks advancing to other accounts.',
                      ),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  _closeStoryViewer();
                  return;
                }
              }
            },
          ),

          // Story Viewer Overlay with Close Button & Story Count
          if (_isStoryViewerMode && !_storyBudgetReached)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
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
                        label: 'Close story viewer and return to Story Tray',
                        child: FilledButton.icon(
                          key: const ValueKey('story_viewer_close_button'),
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
                          onPressed: _closeStoryViewer,
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
                        label: '$todayStories stories viewed today',
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
                              const Icon(
                                Icons.auto_stories_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Stories today: $todayStories',
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

          // Story Budget Reached Screen
          if (_storyBudgetReached)
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
                        'You have reached your daily story budget. Close the viewer to return to your stories tray.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        onPressed: _closeStoryViewer,
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Return to Stories'),
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

  Future<void> _closeStoryViewer() async {
    setState(() {
      _isStoryViewerMode = false;
      _currentStoryUser = null;
      _storyBudgetReached = false;
    });
    if (_controller != null) {
      await _controller!.loadUrl(
        urlRequest: URLRequest(
          url: WebUri('https://${WebViewConstants.allowedHost}/'),
        ),
      );
    }
  }

  String? _extractStoryUsername(String path) {
    final match = RegExp(r'^/stories/([^/]+)').firstMatch(path);
    return match?.group(1);
  }
}
