import 'mosque_catalog.dart';

abstract class MosqueCache {
  Future<List<MosqueCatalog>> readAll();
  Future<MosqueCatalog?> readLast();
  Future<void> save(MosqueCatalog catalog);
  Future<void> markLast(String key);
}
