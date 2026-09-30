(function() {
  'use strict';

  if (window.__ZEROSCROLL_GUARD_INITIALIZED__) {
    return;
  }
  window.__ZEROSCROLL_GUARD_INITIALIZED__ = true;

  var config = window.__ZEROSCROLL_CONFIG__ || {};
  var fallbackPath = config.fallbackPath || '/direct/inbox/';
  var allowedPatterns = (config.allowedPaths || []).map(function(p) {
    return new RegExp(p);
  });
  var blockedPatterns = (config.alwaysBlockedPaths || []).map(function(p) {
    return new RegExp(p);
  });
  var hideSelectors = config.hideSelectors || [];
  var customCss = config.extraCss || config.customCss || '';

  // SINGLE ITEM VIEWER CONFIG & RULES
  var viewerConfig = config.viewerModeRules || config.viewerConfig || {};
  var viewerEnabled = viewerConfig.enabled !== false;
  var viewerPatterns = (viewerConfig.pathPatterns || [
    '^/reel/[^/]+/?$',
    '^/reels/[^/]+/?$',
    '^/p/[^/]+/?$'
  ]).map(function(p) {
    return new RegExp(p);
  });
  var viewerHideSelectors = viewerConfig.hideSelectors || [];
  var viewerScrollSelectors = viewerConfig.scrollContainerSelectors || [
    'main',
    "[role='main']",
    'article',
    "div[data-pressable-container='true']"
  ];
  var lockScroll = viewerConfig.lockScroll !== false;
  var preventScrollKeys = viewerConfig.preventScrollKeys !== false;
  var blockNextReel = viewerConfig.blockNextReel !== false;
  var disableVideoLoop = viewerConfig.disableVideoLoop !== false;
  var lastReelMessage = viewerConfig.lastReelMessage || "That's the last one.";

  var isViewerModeActive = false;
  var currentViewerMediaId = null;
  var lastDirectPath = '/direct/inbox/';
  var isNavigatingBackFromNextReel = false;
  var isHandlingBlocked = false;

  var currentViewerUser = null;

  function cleanPath(pathname) {
    if (!pathname) return '/';
    var clean = pathname.split('?')[0].split('#')[0];
    return clean || '/';
  }

  function extractMediaInfo(path) {
    var clean = cleanPath(path);
    var reelMatch = clean.match(/^\/(reel|reels|p)\/([^/]+)/);
    if (reelMatch) {
      return {
        type: reelMatch[1],
        id: reelMatch[2],
        username: null,
        path: clean
      };
    }
    var storyMatch = clean.match(/^\/stories\/([^/]+)(?:\/([^/]+))?/);
    if (storyMatch && storyMatch[1] !== 'create') {
      return {
        type: 'story',
        username: storyMatch[1],
        id: storyMatch[2] || storyMatch[1],
        path: clean
      };
    }
    return null;
  }

  function isViewerModePath(path) {
    if (!viewerEnabled) return false;
    var clean = cleanPath(path);
    for (var i = 0; i < viewerPatterns.length; i++) {
      if (viewerPatterns[i].test(clean)) {
        return true;
      }
    }
    return false;
  }

  function isPathAllowed(pathname) {
    var path = cleanPath(pathname);

    // 1. Explicitly blocked patterns have top priority
    for (var i = 0; i < blockedPatterns.length; i++) {
      if (blockedPatterns[i].test(path)) {
        return false;
      }
    }

    // 2. Allowed patterns
    for (var j = 0; j < allowedPatterns.length; j++) {
      if (allowedPatterns[j].test(path)) {
        return true;
      }
    }

    // Default deny: any other route is blocked
    return false;
  }

  function notifyFlutterBlocked(path, originalUrl) {
    console.warn('[ZeroScroll Guard] Blocked prohibited navigation:', path);
    try {
      if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
        window.flutter_inappwebview.callHandler('onNavigationBlocked', {
          path: path,
          url: originalUrl || window.location.href
        });
      }
    } catch (e) {}
  }

  function notifyViewerModeChanged(isViewer, mediaInfo) {
    try {
      if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
        window.flutter_inappwebview.callHandler('onViewerModeChanged', {
          isViewer: isViewer,
          mediaId: mediaInfo ? mediaInfo.id : null,
          mediaType: mediaInfo ? mediaInfo.type : null,
          username: mediaInfo ? mediaInfo.username : null,
          path: mediaInfo ? mediaInfo.path : window.location.pathname,
          lastDirectPath: lastDirectPath || '/direct/inbox/'
        });
      }
    } catch (e) {}
  }

  function notifyNextReelBlocked(blockedId, currentId) {
    console.warn('[ZeroScroll Viewer] Blocked transition to next reel:', blockedId);
    try {
      if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
        window.flutter_inappwebview.callHandler('onNextReelBlocked', {
          blockedId: blockedId,
          currentId: currentId,
          message: lastReelMessage
        });
      }
    } catch (e) {}
  }

  function notifyNextStoryUserBlocked(blockedUser, currentUser) {
    console.warn('[ZeroScroll Viewer] Blocked transition to next story user:', blockedUser);
    try {
      if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
        window.flutter_inappwebview.callHandler('onNextStoryUserBlocked', {
          blockedUser: blockedUser,
          currentUser: currentUser,
          message: "Story ended. ZeroScroll blocks advancing to other accounts."
        });
      }
    } catch (e) {}
  }

  function closeViewerMode() {
    isViewerModeActive = false;
    currentViewerMediaId = null;
    currentViewerUser = null;
    applyScrollLock(false);
    applyViewerCss(false);
    hideReplayOverlay();
    notifyViewerModeChanged(false, null);
    if (lastDirectPath && lastDirectPath.indexOf('/direct/') === 0) {
      window.location.replace(lastDirectPath);
    } else {
      window.history.back();
    }
  }

  function blockNavigation(targetPath) {
    if (isHandlingBlocked) return;
    isHandlingBlocked = true;

    notifyFlutterBlocked(targetPath, window.location.href);

    // Force replaceState to the allowed fallback path
    try {
      window.history.replaceState(null, '', fallbackPath);
    } catch (e) {}

    // Dispatch popstate so SPA routers update their internal routing tree
    try {
      window.dispatchEvent(new PopStateEvent('popstate', { state: null }));
    } catch (e) {}

    // In case the SPA does not react, perform window.location redirect
    setTimeout(function() {
      if (!isPathAllowed(window.location.pathname)) {
        window.location.replace(fallbackPath);
      }
      isHandlingBlocked = false;
    }, 50);
  }

  // --- VIEWER MODE: SCROLL LOCKING ---
  function applyScrollLock(enable) {
    var html = document.documentElement;
    var body = document.body;
    if (enable) {
      if (html) {
        html.style.setProperty('overflow', 'hidden', 'important');
        html.style.setProperty('touch-action', 'none', 'important');
        html.style.setProperty('overscroll-behavior', 'none', 'important');
      }
      if (body) {
        body.style.setProperty('overflow', 'hidden', 'important');
        body.style.setProperty('touch-action', 'none', 'important');
        body.style.setProperty('overscroll-behavior', 'none', 'important');
      }
    } else {
      if (html) {
        html.style.removeProperty('overflow');
        html.style.removeProperty('touch-action');
        html.style.removeProperty('overscroll-behavior');
      }
      if (body) {
        body.style.removeProperty('overflow');
        body.style.removeProperty('touch-action');
        body.style.removeProperty('overscroll-behavior');
      }
    }
  }

  function applyViewerCss(enable) {
    var styleTag = document.getElementById('zeroscroll-viewer-style');
    if (!enable) {
      if (styleTag && styleTag.parentNode) {
        styleTag.parentNode.removeChild(styleTag);
      }
      return;
    }
    if (!styleTag) {
      styleTag = document.createElement('style');
      styleTag.id = 'zeroscroll-viewer-style';
      var target = document.head || document.documentElement;
      if (target) {
        target.appendChild(styleTag);
      }
    }

    var rules = [];
    if (viewerScrollSelectors && viewerScrollSelectors.length > 0) {
      rules.push(viewerScrollSelectors.join(',\n') + ' { overflow: hidden !important; touch-action: none !important; overscroll-behavior: none !important; }');
    }
    if (viewerHideSelectors && viewerHideSelectors.length > 0) {
      rules.push(viewerHideSelectors.join(',\n') + ' { display: none !important; visibility: hidden !important; pointer-events: none !important; opacity: 0 !important; }');
    }
    if (styleTag) {
      styleTag.textContent = rules.join('\n');
    }
  }

  // Capture phase listener for gestures
  function onScrollCapture(e) {
    if (isViewerModeActive && lockScroll) {
      e.preventDefault();
      e.stopImmediatePropagation();
      return false;
    }
  }

  var scrollKeyCodes = [
    ' ',
    'Space',
    'Spacebar',
    'ArrowUp',
    'ArrowDown',
    'ArrowLeft',
    'ArrowRight',
    'PageUp',
    'PageDown',
    'Home',
    'End'
  ];

  function onKeyDownCapture(e) {
    if (!isViewerModeActive || !preventScrollKeys) return;
    var tag = (e.target && e.target.tagName) ? e.target.tagName.toLowerCase() : '';
    if (tag === 'input' || tag === 'textarea' || (e.target && e.target.isContentEditable)) {
      return;
    }
    if (scrollKeyCodes.indexOf(e.key) !== -1 || scrollKeyCodes.indexOf(e.code) !== -1) {
      e.preventDefault();
      e.stopImmediatePropagation();
      return false;
    }
  }

  window.addEventListener('touchmove', onScrollCapture, { capture: true, passive: false });
  window.addEventListener('wheel', onScrollCapture, { capture: true, passive: false });
  window.addEventListener('keydown', onKeyDownCapture, { capture: true, passive: false });

  // --- VIEWER MODE: VIDEO BEHAVIOR & REPLAY BUTTON ---
  function showReplayOverlay(video) {
    var existing = document.getElementById('zeroscroll-replay-overlay');
    if (!existing) {
      existing = document.createElement('div');
      existing.id = 'zeroscroll-replay-overlay';
      existing.style.cssText = 'position:fixed;top:0;left:0;right:0;bottom:0;display:flex;align-items:center;justify-content:center;background:rgba(0,0,0,0.45);z-index:999998;pointer-events:auto;';

      var btn = document.createElement('button');
      btn.id = 'zeroscroll-replay-button';
      btn.setAttribute('aria-label', 'Replay video');
      btn.style.cssText = 'background:rgba(20,20,20,0.88);border:2px solid rgba(255,255,255,0.85);color:#fff;border-radius:50px;padding:12px 28px;display:flex;align-items:center;gap:8px;font-size:16px;font-weight:600;cursor:pointer;box-shadow:0 8px 30px rgba(0,0,0,0.5);font-family:system-ui,-apple-system,sans-serif;user-select:none;-webkit-tap-highlight-color:transparent;';
      btn.innerHTML = '<svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor"><path d="M12 5V1L7 6l5 5V7c3.31 0 6 2.69 6 6 0 2.97-2.16 5.44-5 5.92v2.02c3.95-.49 7-3.85 7-7.94 0-4.42-3.58-8-8-8zm-6 8c0-1.65.67-3.15 1.76-4.24L6.34 7.34C4.9 8.79 4 10.79 4 13c0 4.09 3.05 7.45 7 7.94v-2.02c-2.84-.48-5-2.95-5-5.92z"/></svg><span>Replay</span>';

      btn.onclick = function(e) {
        e.stopPropagation();
        existing.style.display = 'none';
        if (video) {
          video.currentTime = 0;
          video.play();
        }
      };

      existing.appendChild(btn);
      (document.body || document.documentElement).appendChild(existing);
    } else {
      existing.style.display = 'flex';
    }
  }

  function hideReplayOverlay() {
    var existing = document.getElementById('zeroscroll-replay-overlay');
    if (existing) {
      existing.style.display = 'none';
    }
  }

  function attachVideoControls(video) {
    if (!video || video.__zeroscroll_attached__) return;
    video.__zeroscroll_attached__ = true;

    if (disableVideoLoop) {
      video.loop = false;
      video.removeAttribute('loop');
    }

    video.addEventListener('ended', function() {
      video.pause();
      showReplayOverlay(video);
    });

    video.addEventListener('play', function() {
      hideReplayOverlay();
    });
  }

  function scanVideos() {
    if (!isViewerModeActive) return;
    var videos = document.querySelectorAll('video');
    for (var i = 0; i < videos.length; i++) {
      attachVideoControls(videos[i]);
    }
  }

  // --- LOCATION & VIEWER MODE STATE ENGINE ---
  function checkViewerModeLocation(pathname) {
    var path = cleanPath(pathname || window.location.pathname);

    // Keep track of last direct messages path
    if (path.indexOf('/direct/') === 0) {
      lastDirectPath = path;
    }

    if (isViewerModePath(path)) {
      var mediaInfo = extractMediaInfo(path);
      if (!isViewerModeActive) {
        // Entering viewer mode
        isViewerModeActive = true;
        currentViewerMediaId = mediaInfo ? mediaInfo.id : null;
        currentViewerUser = mediaInfo ? mediaInfo.username : null;
        applyScrollLock(true);
        applyViewerCss(true);
        scanVideos();
        notifyViewerModeChanged(true, mediaInfo);
      } else if (mediaInfo && mediaInfo.type === 'story') {
        if (currentViewerUser && mediaInfo.username !== currentViewerUser) {
          notifyNextStoryUserBlocked(mediaInfo.username, currentViewerUser);
          closeViewerMode();
          return false;
        } else {
          currentViewerMediaId = mediaInfo.id;
          return true;
        }
      } else if (blockNextReel && mediaInfo && currentViewerMediaId && mediaInfo.id !== currentViewerMediaId) {
        // Moving to a DIFFERENT reel while in viewer mode
        if (!isNavigatingBackFromNextReel) {
          isNavigatingBackFromNextReel = true;
          notifyNextReelBlocked(mediaInfo.id, currentViewerMediaId);
          window.history.back();
          setTimeout(function() {
            isNavigatingBackFromNextReel = false;
          }, 300);
        }
        return false;
      }
      return true;
    } else {
      if (isViewerModeActive) {
        // Exiting viewer mode
        isViewerModeActive = false;
        currentViewerMediaId = null;
        currentViewerUser = null;
        applyScrollLock(false);
        applyViewerCss(false);
        hideReplayOverlay();
        notifyViewerModeChanged(false, null);
      }
      return false;
    }
  }

  function checkCurrentLocation() {
    var currentPath = window.location.pathname;
    if (!isPathAllowed(currentPath)) {
      blockNavigation(currentPath);
      return;
    }
    checkViewerModeLocation(currentPath);
  }

  // --- LAYER 2: Wrap History API ---
  var originalPushState = window.history.pushState;
  window.history.pushState = function(state, unused, url) {
    if (url) {
      try {
        var targetUrl = new URL(url, window.location.origin);
        if (targetUrl.origin === window.location.origin) {
          var targetPath = targetUrl.pathname;
          if (!isPathAllowed(targetPath)) {
            blockNavigation(targetPath);
            return;
          }
          if (isViewerModeActive && isViewerModePath(targetPath)) {
            var mediaInfo = extractMediaInfo(targetPath);
            if (mediaInfo) {
              if (mediaInfo.type === 'story') {
                if (currentViewerUser && mediaInfo.username !== currentViewerUser) {
                  notifyNextStoryUserBlocked(mediaInfo.username, currentViewerUser);
                  closeViewerMode();
                  return;
                }
              } else if (blockNextReel && currentViewerMediaId && mediaInfo.id !== currentViewerMediaId) {
                notifyNextReelBlocked(mediaInfo.id, currentViewerMediaId);
                return;
              }
            }
          }
        }
      } catch (err) {}
    }
    var result = originalPushState.apply(this, arguments);
    checkCurrentLocation();
    return result;
  };

  var originalReplaceState = window.history.replaceState;
  window.history.replaceState = function(state, unused, url) {
    if (url) {
      try {
        var targetUrl = new URL(url, window.location.origin);
        if (targetUrl.origin === window.location.origin) {
          var targetPath = targetUrl.pathname;
          if (!isPathAllowed(targetPath)) {
            blockNavigation(targetPath);
            return;
          }
          if (isViewerModeActive && isViewerModePath(targetPath)) {
            var mediaInfo = extractMediaInfo(targetPath);
            if (mediaInfo) {
              if (mediaInfo.type === 'story') {
                if (currentViewerUser && mediaInfo.username !== currentViewerUser) {
                  notifyNextStoryUserBlocked(mediaInfo.username, currentViewerUser);
                  closeViewerMode();
                  return;
                }
              } else if (blockNextReel && currentViewerMediaId && mediaInfo.id !== currentViewerMediaId) {
                notifyNextReelBlocked(mediaInfo.id, currentViewerMediaId);
                return;
              }
            }
          }
        }
      } catch (err) {}
    }
    var result = originalReplaceState.apply(this, arguments);
    checkCurrentLocation();
    return result;
  };

  // Listen to popstate and hashchange
  window.addEventListener('popstate', function() {
    checkCurrentLocation();
  }, true);

  window.addEventListener('hashchange', function() {
    checkCurrentLocation();
  }, true);

  // Intercept anchor clicks in the capture phase
  document.addEventListener('click', function(event) {
    try {
      var anchor = event.target && event.target.closest ? event.target.closest('a') : null;
      if (!anchor || !anchor.href) return;

      var targetUrl = new URL(anchor.href, window.location.origin);
      if (targetUrl.origin === window.location.origin) {
        var targetPath = targetUrl.pathname;
        if (!isPathAllowed(targetPath)) {
          event.preventDefault();
          event.stopImmediatePropagation();
          blockNavigation(targetPath);
          return;
        }
        if (isViewerModeActive && isViewerModePath(targetPath)) {
          var mediaInfo = extractMediaInfo(targetPath);
          if (mediaInfo) {
            if (mediaInfo.type === 'story') {
              if (currentViewerUser && mediaInfo.username !== currentViewerUser) {
                event.preventDefault();
                event.stopImmediatePropagation();
                notifyNextStoryUserBlocked(mediaInfo.username, currentViewerUser);
                closeViewerMode();
                return;
              }
            } else if (blockNextReel && currentViewerMediaId && mediaInfo.id !== currentViewerMediaId) {
              event.preventDefault();
              event.stopImmediatePropagation();
              notifyNextReelBlocked(mediaInfo.id, currentViewerMediaId);
              return;
            }
          }
        }
      }
    } catch (e) {}
  }, true);

  // --- LAYER 3: CSS Injection ---
  function buildCssRules() {
    var rules = [];
    if (hideSelectors && hideSelectors.length > 0) {
      var combinedSelectors = hideSelectors.join(',\n');
      rules.push(combinedSelectors + ' { display: none !important; visibility: hidden !important; pointer-events: none !important; opacity: 0 !important; }');
    }
    if (customCss) {
      rules.push(customCss);
    }
    return rules.join('\n');
  }

  function applyCss() {
    var cssText = buildCssRules();
    if (!cssText) return;

    var inlineApplied = false;

    try {
      var styleTag = document.getElementById('zeroscroll-guard-style');
      if (!styleTag) {
        styleTag = document.createElement('style');
        styleTag.id = 'zeroscroll-guard-style';
        var target = document.head || document.documentElement;
        if (target) {
          target.appendChild(styleTag);
        }
      }
      if (styleTag) {
        styleTag.textContent = cssText;
        inlineApplied = true;
      }
    } catch (e) {
      inlineApplied = false;
    }

    try {
      if ((!inlineApplied || document.adoptedStyleSheets) && 'adoptedStyleSheets' in document && typeof CSSStyleSheet !== 'undefined') {
        var sheet = window.__ZEROSCROLL_STYLESHEET__;
        if (!sheet) {
          sheet = new CSSStyleSheet();
          window.__ZEROSCROLL_STYLESHEET__ = sheet;
        }
        sheet.replaceSync(cssText);
        var currentSheets = Array.from(document.adoptedStyleSheets || []);
        if (!currentSheets.includes(sheet)) {
          document.adoptedStyleSheets = currentSheets.concat([sheet]);
        }
      }
    } catch (e) {}
  // --- REELS OFF PLACEHOLDER DECORATION ---
  function insertReelPlaceholders() {
    if (isPathAllowed('/reel/placeholder_check/')) {
      return;
    }
    try {
      var reelLinks = document.querySelectorAll("a[href*='/reel/']:not([data-zs-placeholder]), a[href*='/reels/']:not([data-zs-placeholder])");
      for (var i = 0; i < reelLinks.length; i++) {
        var a = reelLinks[i];
        a.setAttribute('data-zs-placeholder', 'true');
        var placeholder = document.createElement('div');
        placeholder.className = 'zeroscroll-reel-placeholder';
        placeholder.setAttribute('style', 'display:inline-flex;align-items:center;justify-content:center;padding:8px 12px;background:#262626;border-radius:10px;color:#8e8e8e;font-size:12px;font-weight:500;border:1px solid #363636;margin:4px 0;cursor:pointer;');
        placeholder.innerHTML = '<span>🎬 Reel hidden by ZeroScroll</span>';
        a.appendChild(placeholder);
      }
    } catch (e) {}
  }

  // --- DOM MutationObserver ---
  function setupMutationObserver() {
    checkCurrentLocation();
    applyCss();
    insertReelPlaceholders();

    var observer = new MutationObserver(function() {
      checkCurrentLocation();
      applyCss();
      insertReelPlaceholders();
      if (isViewerModeActive) {
        applyScrollLock(true);
        applyViewerCss(true);
        scanVideos();
      }
    });

    if (document.documentElement) {
      observer.observe(document.documentElement, {
        childList: true,
        subtree: true
      });
    } else {
      document.addEventListener('DOMContentLoaded', function() {
        observer.observe(document.documentElement, {
          childList: true,
          subtree: true
        });
      });
    }
  }

  // --- HOT-RELOAD SUPPORT ---
  window.__ZEROSCROLL_UPDATE_CONFIG__ = function(newConfig) {
    if (!newConfig || typeof newConfig !== 'object') {
      return false;
    }
    try {
      console.log('[ZeroScroll Guard] Hot-reloading route config, version:', newConfig.version);
      window.__ZEROSCROLL_CONFIG__ = Object.freeze(newConfig);
      config = newConfig;

      if (newConfig.fallbackPath) {
        fallbackPath = newConfig.fallbackPath;
      }
      if (newConfig.allowedPaths && Array.isArray(newConfig.allowedPaths)) {
        allowedPatterns = newConfig.allowedPaths.map(function(p) {
          return new RegExp(p);
        });
      }
      if (newConfig.alwaysBlockedPaths && Array.isArray(newConfig.alwaysBlockedPaths)) {
        blockedPatterns = newConfig.alwaysBlockedPaths.map(function(p) {
          return new RegExp(p);
        });
      }
      if (newConfig.hideSelectors && Array.isArray(newConfig.hideSelectors)) {
        hideSelectors = newConfig.hideSelectors;
      }
      customCss = newConfig.extraCss || newConfig.customCss || '';

      var vCfg = newConfig.viewerModeRules || newConfig.viewerConfig || {};
      viewerConfig = vCfg;
      viewerEnabled = vCfg.enabled !== false;
      if (vCfg.pathPatterns && Array.isArray(vCfg.pathPatterns)) {
        viewerPatterns = vCfg.pathPatterns.map(function(p) {
          return new RegExp(p);
        });
      }
      if (vCfg.hideSelectors && Array.isArray(vCfg.hideSelectors)) {
        viewerHideSelectors = vCfg.hideSelectors;
      }
      if (vCfg.scrollContainerSelectors && Array.isArray(vCfg.scrollContainerSelectors)) {
        viewerScrollSelectors = vCfg.scrollContainerSelectors;
      }
      if (typeof vCfg.lockScroll === 'boolean') lockScroll = vCfg.lockScroll;
      if (typeof vCfg.preventScrollKeys === 'boolean') preventScrollKeys = vCfg.preventScrollKeys;
      if (typeof vCfg.blockNextReel === 'boolean') blockNextReel = vCfg.blockNextReel;
      if (typeof vCfg.disableVideoLoop === 'boolean') disableVideoLoop = vCfg.disableVideoLoop;
      if (vCfg.lastReelMessage) lastReelMessage = vCfg.lastReelMessage;

      // Re-apply updated CSS immediately
      applyCss();

      if (isViewerModeActive) {
        applyViewerCss(true);
        applyScrollLock(lockScroll);
      }

      // Check current location against updated rules
      checkCurrentLocation();
      return true;
    } catch (err) {
      console.error('[ZeroScroll Guard] Failed to hot-reload configuration:', err);
      return false;
    }
  };

  // Initial run
  checkCurrentLocation();
  applyCss();
  setupMutationObserver();

  // Periodic safety check
  setInterval(function() {
    checkCurrentLocation();
    insertReelPlaceholders();
    if (isViewerModeActive) {
      scanVideos();
    }
  }, 250);
})();
