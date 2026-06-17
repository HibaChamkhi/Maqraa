// Cross-platform HTTP client factory.
//
// Picks an implementation based on the platform at compile time:
//   * native (mobile/desktop) -> client_factory_io.dart   (dart:io IOClient)
//   * web                     -> client_factory_web.dart   (BrowserClient)
//
// Importing this file alone never pulls in `dart:io`, so the code compiles
// for Flutter web.
export 'client_factory_io.dart'
    if (dart.library.html) 'client_factory_web.dart';
