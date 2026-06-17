
abstract class NameFeatureRepository {
  Future<void> create(Map<String, dynamic> data);
  Future<Map<String, dynamic>> read(String id);
  Future<void> update(String id, Map<String, dynamic> data);
  Future<void> delete(String id);
}
