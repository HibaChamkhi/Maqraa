import 'package:injectable/injectable.dart';

import 'connectivity_helper.dart' as connectivity;

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

@Injectable(as: NetworkInfo)
class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl();

  @override
  Future<bool> get isConnected => connectivity.hasConnection();
}
