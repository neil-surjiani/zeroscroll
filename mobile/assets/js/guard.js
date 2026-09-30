(function() {
  'use strict';

  if (window.__ZEROSCROLL_GUARD_INITIALIZED__) {
    return;
  }
  window.__ZEROSCROLL_GUARD_INITIALIZED__ = true;

  const config = window.__ZEROSCROLL_CONFIG__ || {};
  const fallbackPath = config.fallbackPath || '/direct/inbox/';
  const allowedPatterns = (config.allowedPaths || []).map(function(p) {
    return new RegExp(p);
  });
  const blockedPatterns = (config.alwaysBlockedPaths || []).map(function(p) {
    return new RegExp(p);
  });
  const hideSelectors = config.hideSelectors || [];
  const customCss = config.customCss || '';

  function cleanPath(pathname) {
    if (!pathname) return '/';
    var clean = pathname.split('?')[0].split('#')[0];
    return clean || '/';
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

    // Default deny: any other route (like profiles or unhandled discovery tabs) is blocked
    return false;
  }

  var isHandlingBlocked = false;

  function notifyFlutterBlocked(path, originalUrl) {
    console.warn('[ZeroScroll Guard] Blocked prohibited navigation:', path);
    try {
      if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
        window.flutter_inappwebview.callHandler('onNavigationBlocked', {
          path: path,
          url: originalUrl || window.location.href
        });
      }
    } catch (e) {
      // Handler not ready or failed
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

  function checkCurrentLocation() {
    var currentPath = window.location.pathname;
    if (!isPathAllowed(currentPath)) {
      blockNavigation(currentPath);
    }
  }

  // LAYER 2: Wrap History API (pushState & replaceState)
  var originalPushState = window.history.pushState;
  window.history.pushState = function(state, unused, url) {
    if (url) {
      try {
        var targetUrl = new URL(url, window.location.origin);
        if (targetUrl.origin === window.location.origin) {
          if (!isPathAllowed(targetUrl.pathname)) {
            blockNavigation(targetUrl.pathname);
            return;
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
          if (!isPathAllowed(targetUrl.pathname)) {
            blockNavigation(targetUrl.pathname);
            return;
          }
        }
      } catch (err) {}
    }
    var result = originalReplaceState.apply(this, arguments);
    checkCurrentLocation();
    return result;
  };

  // Listen to popstate and hashchange (back button, forward button, hash changes)
  window.addEventListener('popstate', function() {
    checkCurrentLocation();
  }, true);

  window.addEventListener('hashchange', function() {
    checkCurrentLocation();
  }, true);

  // Intercept anchor clicks in the capture phase before SPAs intercept them
  document.addEventListener('click', function(event) {
    try {
      var anchor = event.target && event.target.closest ? event.target.closest('a') : null;
      if (!anchor || !anchor.href) return;

      var targetUrl = new URL(anchor.href, window.location.origin);
      if (targetUrl.origin === window.location.origin) {
        if (!isPathAllowed(targetUrl.pathname)) {
          event.preventDefault();
          event.stopImmediatePropagation();
          blockNavigation(targetUrl.pathname);
        }
      }
    } catch (e) {}
  }, true);

  // LAYER 3: CSS Injection with style element and adoptedStyleSheets fallback
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

    // 1. Try injecting <style> element
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

    // 2. CSP Fallback: If style tag failed or if adoptedStyleSheets is supported
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
  }

  // DOM MutationObserver for dynamic React/SPA rendering & re-injections
  function setupMutationObserver() {
    checkCurrentLocation();
    applyCss();

    var observer = new MutationObserver(function() {
      // Verify location on significant DOM re-renders
      checkCurrentLocation();
      // Ensure style element or adopted stylesheet remains active
      applyCss();
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

  // Initial check & run
  checkCurrentLocation();
  applyCss();
  setupMutationObserver();

  // Periodic heartbeat safety check for silent background URL changes
  setInterval(checkCurrentLocation, 250);
})();
