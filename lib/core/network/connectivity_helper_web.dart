// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web connectivity check.
///
/// `dart:io` socket lookups are unavailable in the browser, so we rely on the
/// browser's own online/offline signal (`navigator.onLine`). When the browser
/// reports offline this is reliably false; when it reports online the actual
/// request will still surface a real network error if connectivity is lost.
Future<bool> hasConnection() async {
  return html.window.navigator.onLine ?? true;
}
