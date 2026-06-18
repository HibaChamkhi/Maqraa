import 'package:http_interceptor/http_interceptor.dart';
import 'package:injectable/injectable.dart';
import 'auth_interceptor.dart';
import 'client_factory.dart';

abstract class HttpInterceptor {
  InterceptedHttp httpInterceptor();
}

@Injectable(as: HttpInterceptor)
class HttpInterceptorImpl implements HttpInterceptor {
  final AuthenticatedHttpClient httpClient;

  const HttpInterceptorImpl({
    required this.httpClient,
  });

  @override
  InterceptedHttp httpInterceptor() {
    // Platform-appropriate client (IOClient natively, BrowserClient on web).
    return InterceptedHttp.build(
      client: createHttpClient(),
      interceptors: [httpClient],
    );
  }
}
