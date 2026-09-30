import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/zero_scroll_web_view_controller.dart';

/// Provider exposing the active [ZeroScrollWebViewController] instance.
final webViewControllerProvider = StateProvider<ZeroScrollWebViewController?>(
  (ref) => null,
);
