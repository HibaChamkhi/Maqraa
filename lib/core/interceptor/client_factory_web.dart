import 'package:http/browser_client.dart';
import 'package:http/http.dart';

/// Web HTTP client.
///
/// `dart:io` is unavailable on the web, so requests go through the browser's
/// fetch/XHR stack via [BrowserClient]. Certificate handling is managed by the
/// browser, so there is no bad-certificate override here.
Client createHttpClient() => BrowserClient();
