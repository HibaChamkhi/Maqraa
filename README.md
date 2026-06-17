# maqraa

A cross-platform Flutter project (mobile, desktop, and **web**).

## Running on the web

After pulling these changes, refresh dependencies and regenerate DI code, then run:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # regenerates injection.config.dart
flutter run -d chrome                                       # dev
flutter build web                                           # production -> build/web
```

### Web compatibility notes

- `dart:io` no longer leaks into shared code. The HTTP client is created through
  a conditional-import factory (`lib/core/interceptor/client_factory.dart`):
  `IOClient` (with a bad-cert override) natively, `BrowserClient` on web.
- `internet_connection_checker` (native-only) was removed. Connectivity is now
  checked via a conditional-import helper (`lib/core/network/connectivity_helper.dart`):
  a socket lookup natively, `navigator.onLine` on web.
- The login UI is now responsive — the form is centered and width-capped so it
  reads well on wide desktop/web viewports instead of stretching edge to edge.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
