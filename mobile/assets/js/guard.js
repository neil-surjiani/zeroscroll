(function() {
  'use strict';

  // Only run in top-level window frame, never inside iframes
  try {
    if (window.self !== window.top) {
      return;
    }
  } catch (e) {
    return;
  }

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

  function isRootHomePath(path) {
    if (!path) return true;
    var clean = cleanPath(path);
    return clean === '/' || clean === '';
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
    if (!pathname || pathname === 'blank' || pathname === '/blank') {
      if (!window.location.hostname || window.location.protocol === 'about:') {
        return true;
      }
    }
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

    var isRoot = isRootHomePath(targetPath);
    if (!isRoot) {
      notifyFlutterBlocked(targetPath, window.location.href);
    }

    var effectiveFallback = fallbackPath;
    if (!window.location.hostname || window.location.origin === 'null' || window.location.protocol === 'about:') {
      effectiveFallback = 'https://www.instagram.com' + fallbackPath;
    }

    if (isRoot && document.documentElement) {
      document.documentElement.classList.add('zeroscroll-home-redirecting');
    }

    // Directly replace location to navigate to the fallback (DMs)
    try {
      window.location.replace(effectiveFallback);
    } catch (e) {
      window.location.href = effectiveFallback;
    }

    setTimeout(function() {
      isHandlingBlocked = false;
    }, 500);
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
    if (!window.location.hostname || window.location.href === 'about:blank' || window.location.protocol === 'about:') {
      return;
    }
    var currentPath = window.location.pathname;

    // Direct seamless redirect for root home path (e.g. following login or home link)
    if (isRootHomePath(currentPath)) {
      if (document.documentElement) {
        document.documentElement.classList.add('zeroscroll-home-redirecting');
      }
      try {
        window.location.replace(fallbackPath);
      } catch (e) {
        window.location.href = fallbackPath;
      }
      return;
    }

    if (!isPathAllowed(currentPath)) {
      blockNavigation(currentPath);
      return;
    }
    checkViewerModeLocation(currentPath);
    if (typeof checkOnetapPrompt === 'function') {
      checkOnetapPrompt();
    }
  }

  // --- LAYER 2: Wrap History API ---
  var originalPushState = window.history.pushState;
  window.history.pushState = function(state, unused, url) {
    if (url) {
      try {
        var targetUrl = new URL(url, window.location.origin);
        if (targetUrl.origin === window.location.origin) {
          var targetPath = targetUrl.pathname;

          if (isRootHomePath(targetPath)) {
            if (document.documentElement) {
              document.documentElement.classList.add('zeroscroll-home-redirecting');
            }
            window.location.replace(fallbackPath);
            return;
          }

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
    if (!isHandlingBlocked) {
      checkCurrentLocation();
    }
    return result;
  };

  var originalReplaceState = window.history.replaceState;
  window.history.replaceState = function(state, unused, url) {
    if (url) {
      try {
        var targetUrl = new URL(url, window.location.origin);
        if (targetUrl.origin === window.location.origin) {
          var targetPath = targetUrl.pathname;

          if (isRootHomePath(targetPath)) {
            if (document.documentElement) {
              document.documentElement.classList.add('zeroscroll-home-redirecting');
            }
            window.location.replace(fallbackPath);
            return;
          }

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
    if (!isHandlingBlocked) {
      checkCurrentLocation();
    }
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

        if (isRootHomePath(targetPath)) {
          event.preventDefault();
          event.stopImmediatePropagation();
          if (document.documentElement) {
            document.documentElement.classList.add('zeroscroll-home-redirecting');
          }
          window.location.replace(fallbackPath);
          return;
        }

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
    rules.push('html.zeroscroll-home-redirecting body { display: none !important; opacity: 0 !important; visibility: hidden !important; }');
    rules.push('i[aria-label="Instagram"], span[aria-label="Instagram"], div[aria-label="Instagram"], .coreSpriteLoggedOutWordmark { background-image: url("' + ZEROSCROLL_LOGO_URL + '") !important; background-size: contain !important; background-repeat: no-repeat !important; background-position: center !important; }');
    return rules.join('\n');
  }

  function applyCss() {
    var cssText = buildCssRules();
    if (!cssText) return;

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
      if (styleTag && styleTag.textContent !== cssText) {
        styleTag.textContent = cssText;
      }
    } catch (e) {}
  }


  // --- BRAND LOGO REPLACEMENT ---
  var ZEROSCROLL_LOGO_URL = 'data:image/png;base64,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';

  function replaceInstagramLogos() {
    try {
      // 1. Traditional desktop/PWA logo selectors
      var logoSelectors = [
        'i[aria-label="Instagram"]',
        'span[aria-label="Instagram"]',
        'div[aria-label="Instagram"]',
        'svg[aria-label="Instagram"]',
        'i[aria-label="instagram"]',
        'span[aria-label="instagram"]',
        'div[aria-label="instagram"]',
        'svg[aria-label="instagram"]',
        '[data-testid="instagram-logo"]',
        '.coreSpriteLoggedOutWordmark'
      ];
      var elements = document.querySelectorAll(logoSelectors.join(','));
      for (var i = 0; i < elements.length; i++) {
        var el = elements[i];
        if (el.getAttribute('data-zs-logo-replaced')) continue;
        el.setAttribute('data-zs-logo-replaced', 'true');

        var isSvg = el.tagName.toLowerCase() === 'svg';
        if (isSvg) {
          var repImg = document.createElement('img');
          repImg.src = ZEROSCROLL_LOGO_URL;
          repImg.setAttribute('alt', 'ZeroScroll');
          repImg.style.cssText = 'height:48px;width:48px;object-fit:contain;display:inline-block;vertical-align:middle;margin:0 auto;';
          if (el.parentNode) {
            el.parentNode.insertBefore(repImg, el);
            el.style.display = 'none';
          }
        } else {
          el.style.backgroundImage = 'url("' + ZEROSCROLL_LOGO_URL + '")';
          el.style.backgroundSize = 'contain';
          el.style.backgroundRepeat = 'no-repeat';
          el.style.backgroundPosition = 'center';
          for (var c = 0; c < el.children.length; c++) {
            el.children[c].style.display = 'none';
          }
        }
      }

      // 2. Mobile web / Bloks login screen img logos
      var imgs = document.querySelectorAll('img');
      for (var m = 0; m < imgs.length; m++) {
        var img = imgs[m];
        if (img.getAttribute('data-zs-logo-replaced')) continue;

        var src = img.src || '';
        var rect = img.getBoundingClientRect();
        var isSquareLogo = (img.naturalWidth > 50 && img.naturalWidth === img.naturalHeight) ||
                           (rect.width > 40 && Math.abs(rect.width - rect.height) < 15 && rect.top < 380);
        var isInstagramCdn = src.includes('cdninstagram.com') || src.includes('instagram.com');

        // Center Instagram camera logo above login form
        if (isSquareLogo && isInstagramCdn && rect.top > 0 && rect.top < 400) {
          img.setAttribute('data-zs-logo-replaced', 'true');
          img.src = ZEROSCROLL_LOGO_URL;
          img.style.objectFit = 'contain';
          continue;
        }

        // Meta branding footer at bottom of login screen
        if (rect.top > 400 && rect.height <= 50 && isInstagramCdn && (src.includes('RkrEdst9VSp') || img.naturalHeight <= 40)) {
          img.setAttribute('data-zs-logo-replaced', 'true');
          img.style.display = 'none';
          if (img.parentElement) {
            img.parentElement.style.display = 'none';
          }
        }
      }

      if (window.location.pathname.indexOf('/accounts/login') !== -1 || window.location.pathname === '/') {
        var allIcons = document.querySelectorAll('i, svg');
        for (var j = 0; j < allIcons.length; j++) {
          var icon = allIcons[j];
          var rect = icon.getBoundingClientRect();
          if (rect.width > 100 && rect.height > 20 && rect.height < 100 && rect.top > 0 && rect.top < 250) {
            if (icon.getAttribute('data-zs-logo-replaced')) continue;
            icon.setAttribute('data-zs-logo-replaced', 'true');
            if (icon.tagName.toLowerCase() === 'svg') {
              var mImg = document.createElement('img');
              mImg.src = ZEROSCROLL_LOGO_URL;
              mImg.style.width = '120px';
              mImg.style.height = 'auto';
              mImg.style.display = 'block';
              mImg.style.margin = '0 auto';
              icon.parentNode.replaceChild(mImg, icon);
            } else {
              icon.style.backgroundImage = 'url("' + ZEROSCROLL_LOGO_URL + '")';
              icon.style.backgroundSize = 'contain';
              icon.style.backgroundRepeat = 'no-repeat';
              icon.style.backgroundPosition = 'center';
              icon.innerHTML = '';
            }
          }
        }
      }
    } catch (e) {}
  }

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
  var domCheckTimer = null;
  function scheduleDomCheck() {
    if (domCheckTimer) return;
    domCheckTimer = setTimeout(function() {
      domCheckTimer = null;
      checkCurrentLocation();
      insertReelPlaceholders();
      replaceInstagramLogos();
      if (isViewerModeActive) {
        applyScrollLock(true);
        applyViewerCss(true);
        scanVideos();
      }
    }, 200);
  }

  function setupMutationObserver() {
    checkCurrentLocation();
    applyCss();
    insertReelPlaceholders();
    replaceInstagramLogos();

    var observer = new MutationObserver(function() {
      scheduleDomCheck();
    });

    var targetNode = document.body || document.documentElement;
    if (targetNode) {
      observer.observe(targetNode, {
        childList: true,
        subtree: true
      });
    } else {
      document.addEventListener('DOMContentLoaded', function() {
        var t = document.body || document.documentElement;
        if (t) {
          observer.observe(t, {
            childList: true,
            subtree: true
          });
        }
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

  // --- LOGIN SUCCESS DETECTION VIA FETCH / XHR ---
  function notifyLoginSuccess() {
    try {
      if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
        window.flutter_inappwebview.callHandler('onLoginSuccess');
      }
    } catch (e) {}
  }

  var originalFetch = window.fetch;
  if (typeof originalFetch === 'function') {
    window.fetch = function() {
      var promise = originalFetch.apply(this, arguments);
      try {
        var urlArg = arguments[0];
        var urlStr = (typeof urlArg === 'string') ? urlArg : (urlArg && urlArg.url ? urlArg.url : '');
        if (urlStr && (urlStr.indexOf('/login/ajax/') !== -1 || urlStr.indexOf('/accounts/login') !== -1 || urlStr.indexOf('/onetap') !== -1)) {
          promise.then(function(response) {
            try {
              if (response && response.ok) {
                var clone = response.clone();
                clone.json().then(function(data) {
                  if (data && (data.authenticated === true || data.user === true || (data.userId && data.status === 'ok'))) {
                    notifyLoginSuccess();
                    if (document.documentElement) {
                      document.documentElement.classList.add('zeroscroll-home-redirecting');
                    }
                  }
                }).catch(function() {});
              }
            } catch (e) {}
          }).catch(function() {});
        }
      } catch (e) {}
      return promise;
    };
  }

  var originalXhrOpen = XMLHttpRequest.prototype.open;
  var originalXhrSend = XMLHttpRequest.prototype.send;
  XMLHttpRequest.prototype.open = function(method, url) {
    this.__zeroscroll_url = url;
    return originalXhrOpen.apply(this, arguments);
  };
  XMLHttpRequest.prototype.send = function() {
    var self = this;
    var url = self.__zeroscroll_url || '';
    if (url && (url.indexOf('/login/ajax/') !== -1 || url.indexOf('/accounts/login') !== -1 || url.indexOf('/onetap') !== -1)) {
      self.addEventListener('load', function() {
        try {
          if (self.status >= 200 && self.status < 300) {
            var data = JSON.parse(self.responseText);
            if (data && (data.authenticated === true || data.user === true || (data.userId && data.status === 'ok'))) {
              notifyLoginSuccess();
              if (document.documentElement) {
                document.documentElement.classList.add('zeroscroll-home-redirecting');
              }
            }
          }
        } catch (e) {}
      });
    }
    return originalXhrSend.apply(this, arguments);
  };

  // --- ONETAP AUTO-ADVANCE ---
  function checkOnetapPrompt() {
    var path = cleanPath(window.location.pathname);
    if (path.indexOf('/accounts/onetap') === 0) {
      setTimeout(function() {
        var buttons = document.querySelectorAll('button, div[role="button"]');
        for (var i = 0; i < buttons.length; i++) {
          var text = (buttons[i].textContent || '').trim().toLowerCase();
          if (text === 'not now' || text.indexOf('not now') !== -1) {
            buttons[i].click();
            return;
          }
        }
        window.location.replace(fallbackPath);
      }, 600);
    }
  }

  // Initial run
  checkCurrentLocation();
  applyCss();
  setupMutationObserver();

  // Periodic safety check
  setInterval(function() {
    checkCurrentLocation();
    insertReelPlaceholders();
    replaceInstagramLogos();
    if (isViewerModeActive) {
      scanVideos();
    }
  }, 1000);
})();
