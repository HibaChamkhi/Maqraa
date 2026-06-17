import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../domain/auth/repositories/auth_repository.dart';
import '../data_sources/remote/auth_data_source.dart';

@Injectable(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<void> register(Map<String, dynamic> userInfo) async {
    // Perform the network request to register
    final response = await remoteDataSource.register(userInfo);
    response.fold(
      (exception) {
        throw exception;
      },
      (success) {
        // Handle successful response
        // Optionally return success if needed
      },
    );
  }

  @override
  Future<void> login(String email, String password) async {
    // Perform the network request to login
    final response = await remoteDataSource.login(email, password);
    response.fold(
      (exception) {
        // Handle the exception
        throw exception;
      },
      (success) {
        // Handle successful response
        // Optionally return success if needed
      },
    );
  }

  @override
  Future<void> logout() async {
    // Perform the network request to logout
    final response = await remoteDataSource.logout();
    response.fold(
      (exception) {
        // Handle the exception
        throw exception;
      },
      (success) {
        // Handle successful response
        // Optionally return success if needed
      },
    );
  }

}
