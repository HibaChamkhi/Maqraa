

abstract class AuthRepository {
  Future<void> register(Map<String, dynamic> userInfo) ;
  Future<void> login(String email, String password);
  Future<void> logout();
}
