/// Utility for sanitizing remote CSS and CSS selectors before injection.
///
/// Strips or rejects external references, URL requests, script injections,
/// legacy CSS expressions, and ensures that remote configuration cannot leak data
/// or execute arbitrary JavaScript code.
class CssSanitizer {
  CssSanitizer._();

  // Forbidden patterns in CSS
  static final RegExp _urlPattern = RegExp(
    r'url\s*\([^)]*\)',
    caseSensitive: false,
    multiLine: true,
  );

  static final RegExp _importPattern = RegExp(
    r'@import[^;]+;?',
    caseSensitive: false,
    multiLine: true,
  );

  static final RegExp _expressionPattern = RegExp(
    r'expression\s*\([^)]*\)',
    caseSensitive: false,
    multiLine: true,
  );

  static final RegExp _javascriptProtocolPattern = RegExp(
    r'javascript\s*:',
    caseSensitive: false,
  );

  static final RegExp _scriptTagPattern = RegExp(
    r'<\/?script[^>]*>',
    caseSensitive: false,
  );

  static final RegExp _mozBindingPattern = RegExp(
    r'-moz-binding\s*:[^;]+;?',
    caseSensitive: false,
  );

  static final RegExp _behaviorPattern = RegExp(
    r'behavior\s*:[^;]+;?',
    caseSensitive: false,
  );

  static final RegExp _imageSetPattern = RegExp(
    r'(-webkit-)?image-set\s*\([^)]*\)',
    caseSensitive: false,
  );

  /// Checks whether the provided CSS contains any unsafe external references
  /// or script injection vectors.
  static bool isSafeCss(String css) {
    if (css.isEmpty) return true;
    if (_urlPattern.hasMatch(css)) return false;
    if (_importPattern.hasMatch(css)) return false;
    if (_expressionPattern.hasMatch(css)) return false;
    if (_javascriptProtocolPattern.hasMatch(css)) return false;
    if (_scriptTagPattern.hasMatch(css)) return false;
    if (_mozBindingPattern.hasMatch(css)) return false;
    if (_behaviorPattern.hasMatch(css)) return false;
    if (_imageSetPattern.hasMatch(css)) return false;
    return true;
  }

  /// Sanitizes CSS by removing or neutering all unsafe patterns:
  /// - `url(...)` -> `none`
  /// - `@import ...;` -> stripped
  /// - `expression(...)` -> `none`
  /// - `javascript:` -> `invalid:`
  /// - `<script...>` -> stripped
  /// - `-moz-binding` / `behavior:` -> stripped
  static String sanitizeCss(String css) {
    if (css.isEmpty) return '';

    var sanitized = css;

    // Strip script tags
    sanitized = sanitized.replaceAll(_scriptTagPattern, '');

    // Strip @import rules
    sanitized = sanitized.replaceAll(_importPattern, '/* stripped @import */');

    // Neuter url() references
    sanitized = sanitized.replaceAll(_urlPattern, 'none');

    // Neuter image-set()
    sanitized = sanitized.replaceAll(_imageSetPattern, 'none');

    // Neuter expression()
    sanitized = sanitized.replaceAll(_expressionPattern, 'none');

    // Neuter javascript: pseudo protocol
    sanitized = sanitized.replaceAll(_javascriptProtocolPattern, 'invalid:');

    // Strip -moz-binding and behavior
    sanitized = sanitized.replaceAll(_mozBindingPattern, '');
    sanitized = sanitized.replaceAll(_behaviorPattern, '');

    return sanitized.trim();
  }

  /// Validates that a CSS selector does not contain script injection or malicious tokens.
  static bool isSafeSelector(String selector) {
    final s = selector.trim();
    if (s.isEmpty) return false;
    if (_scriptTagPattern.hasMatch(s)) return false;
    if (_javascriptProtocolPattern.hasMatch(s)) return false;
    if (s.contains('\x00') || s.contains('\r') || s.contains('\n')) return false;
    return true;
  }

  /// Filters a list of CSS selectors, removing any invalid or unsafe selectors.
  static List<String> sanitizeSelectors(List<String> selectors) {
    return selectors
        .map((s) => s.trim())
        .where((s) => isSafeSelector(s))
        .toList();
  }
}
