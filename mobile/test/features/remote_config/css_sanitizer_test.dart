import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/features/remote_config/domain/css_sanitizer.dart';

void main() {
  group('CssSanitizer', () {
    test('passes clean CSS styles without alterations', () {
      const cleanCss =
          'a[href="/"] { display: none !important; opacity: 0; }';
      expect(CssSanitizer.isSafeCss(cleanCss), isTrue);
      expect(CssSanitizer.sanitizeCss(cleanCss), cleanCss);
    });

    test('strips url() references and replaces with none', () {
      const dangerousCss =
          'body { background: url("https://malicious.com/track.png"); }';
      expect(CssSanitizer.isSafeCss(dangerousCss), isFalse);
      final sanitized = CssSanitizer.sanitizeCss(dangerousCss);
      expect(sanitized, isNot(contains('https://malicious.com/track.png')));
      expect(sanitized, contains('body { background: none; }'));
    });

    test('strips @import rules', () {
      const importCss =
          '@import url("https://evil.com/style.css"); .header { color: red; }';
      expect(CssSanitizer.isSafeCss(importCss), isFalse);
      final sanitized = CssSanitizer.sanitizeCss(importCss);
      expect(sanitized, isNot(contains('https://evil.com/style.css')));
      expect(sanitized, contains('/* stripped @import */'));
      expect(sanitized, contains('.header { color: red; }'));
    });

    test('strips expression() vectors', () {
      const expressionCss =
          '.exploit { width: expression(document.location="https://leak.com"); }';
      expect(CssSanitizer.isSafeCss(expressionCss), isFalse);
      final sanitized = CssSanitizer.sanitizeCss(expressionCss);
      expect(sanitized, isNot(contains('document.location')));
      expect(sanitized, contains('.exploit { width: none; }'));
    });

    test('neuters javascript: pseudo-protocols', () {
      const jsCss =
          '.exploit { background-image: javascript:alert(1); }';
      expect(CssSanitizer.isSafeCss(jsCss), isFalse);
      final sanitized = CssSanitizer.sanitizeCss(jsCss);
      expect(sanitized, isNot(contains('javascript:')));
      expect(sanitized, contains('invalid:alert(1)'));
    });

    test('strips embedded <script> tags', () {
      const scriptCss =
          '</style><script>alert("pwned")</script><style>';
      expect(CssSanitizer.isSafeCss(scriptCss), isFalse);
      final sanitized = CssSanitizer.sanitizeCss(scriptCss);
      expect(sanitized, isNot(contains('<script>')));
      expect(sanitized, isNot(contains('</script>')));
    });

    test('strips -moz-binding and behavior properties', () {
      const legacyCss =
          'div { -moz-binding: url("xbl.xml#test"); behavior: url("test.htc"); }';
      expect(CssSanitizer.isSafeCss(legacyCss), isFalse);
      final sanitized = CssSanitizer.sanitizeCss(legacyCss);
      expect(sanitized, isNot(contains('-moz-binding')));
      expect(sanitized, isNot(contains('behavior')));
    });

    group('Selector Sanitization', () {
      test('accepts safe valid selectors', () {
        expect(CssSanitizer.isSafeSelector("a[href='/']"), isTrue);
        expect(CssSanitizer.isSafeSelector("div[aria-label='Home']"), isTrue);
        expect(CssSanitizer.isSafeSelector("section.stories-tray"), isTrue);
      });

      test('rejects selectors containing script injection or control chars', () {
        expect(CssSanitizer.isSafeSelector('<script>alert(1)</script>'), isFalse);
        expect(CssSanitizer.isSafeSelector('a[href="javascript:alert()"]'), isFalse);
        expect(CssSanitizer.isSafeSelector('div\n.malicious'), isFalse);
        expect(CssSanitizer.isSafeSelector(''), isFalse);
      });

      test('sanitizeSelectors filters out all unsafe entries', () {
        final raw = [
          "a[href='/']",
          '<script>evil()</script>',
          "div[aria-label='Home']",
          'a[javascript:void]',
        ];
        final filtered = CssSanitizer.sanitizeSelectors(raw);
        expect(filtered.length, 2);
        expect(filtered, contains("a[href='/']"));
        expect(filtered, contains("div[aria-label='Home']"));
      });
    });
  });
}
