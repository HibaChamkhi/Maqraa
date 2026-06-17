import 'dart:io';

import 'package:http/http.dart';
import 'package:http/io_client.dart';

/// Native (mobile/desktop) HTTP client.
///
/// Uses an [IOClient] wrapping a [HttpClient] that accepts self-signed /
/// invalid certificates, mirroring the original behaviour.
Client createHttpClient() {
  final httpClient = HttpClient()
    ..badCertificateCallback =
        ((X509Certificate cert, String host, int port) => true);
  return IOClient(httpClient);
}
