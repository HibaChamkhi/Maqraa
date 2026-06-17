// Cross-platform connectivity check.
//
// Picks an implementation based on the platform at compile time:
//   * native (mobile/desktop) -> connectivity_helper_io.dart  (socket lookup)
//   * web                     -> connectivity_helper_web.dart  (navigator.onLine)
export 'connectivity_helper_io.dart'
    if (dart.library.html) 'connectivity_helper_web.dart';
