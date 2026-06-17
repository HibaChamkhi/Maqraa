import 'dart:io';

/// Native connectivity check via a DNS/socket lookup.
Future<bool> hasConnection() async {
  try {
    final result = await InternetAddress.lookup('example.com')
        .timeout(const Duration(seconds: 5));
    return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
  } on SocketException {
    return false;
  } catch (_) {
    return false;
  }
}
