import 'package:immich_mobile/domain/models/store.model.dart';
import 'package:immich_mobile/domain/models/user.model.dart';
import 'package:immich_mobile/infrastructure/entities/store.entity.dart';
import 'package:immich_mobile/infrastructure/repositories/db.repository.dart';
import 'package:immich_mobile/infrastructure/repositories/user.repository.dart';
import 'package:isar/isar.dart';

class IsarStoreRepository extends IsarDatabaseRepository {
  final Isar _db;
  final validStoreKeys = StoreKey.values.map((e) => e.id).toSet();

  IsarStoreRepository(super.db) : _db = db;

  Future<bool> deleteAll() async {
    return await transaction(() async {
      await _db.storeValues.clear();
      return true;
    });
  }

  Stream<StoreDto<Object>> watchAll() {
    return _db.storeValues
        .filter()
        .anyOf(validStoreKeys, (query, id) => query.idEqualTo(id))
        .watch(fireImmediately: true)
        .asyncExpand((entities) => Stream.fromFutures(entities.map((e) async => _toUpdateEvent(e))));
  }

  Future<void> delete<T>(StoreKey<T> key) async {
    return await transaction(() async => await _db.storeValues.delete(key.id));
  }

  Future<bool> insert<T>(StoreKey<T> key, T value) async {
    return await transaction(() async {
      await _db.storeValues.put(await _fromValue(key, value));
      return true;
    });
  }

  Future<T?> tryGet<T>(StoreKey<T> key) async {
    final entity = (await _db.storeValues.get(key.id));
    if (entity == null) {
      return null;
    }
    return await _toValue(key, entity);
  }

  Future<bool> update<T>(StoreKey<T> key, T value) async {
    return await transaction(() async {
      await _db.storeValues.put(await _fromValue(key, value));
      return true;
    });
  }

  Stream<T?> watch<T>(StoreKey<T> key) async* {
    yield* _db.storeValues
        .watchObject(key.id, fireImmediately: true)
        .asyncMap((e) async => e == null ? null : await _toValue(key, e));
  }

  Future<StoreDto<Object>> _toUpdateEvent(StoreValue entity) async {
    final key = StoreKey.values.firstWhere((e) => e.id == entity.id) as StoreKey<Object>;
    final value = await _toValue(key, entity);
    return StoreDto(key, value);
  }

  Future<T?> _toValue<T>(StoreKey<T> key, StoreValue entity) async =>
      switch (key.type) {
            const (int) => entity.intValue,
            const (String) => entity.strValue,
            const (bool) => entity.intValue == 1,
            const (DateTime) => entity.intValue == null ? null : DateTime.fromMillisecondsSinceEpoch(entity.intValue!),
            const (UserDto) =>
              entity.strValue == null ? null : await IsarUserRepository(_db).getByUserId(entity.strValue!),
            _ => null,
          }
          as T?;

  Future<StoreValue> _fromValue<T>(StoreKey<T> key, T value) async {
    final (int? intValue, String? strValue) = switch (key.type) {
      const (int) => (value as int, null),
      const (String) => (null, value as String),
      const (bool) => ((value as bool) ? 1 : 0, null),
      const (DateTime) => ((value as DateTime).millisecondsSinceEpoch, null),
      const (UserDto) => (null, (await IsarUserRepository(_db).update(value as UserDto)).id),
      _ => throw UnsupportedError("Unsupported primitive type: ${key.type} for key: ${key.name}"),
    };
    return StoreValue(key.id, intValue: intValue, strValue: strValue);
  }

  Future<List<StoreDto<Object>>> getAll() async {
    final entities = await _db.storeValues.filter().anyOf(validStoreKeys, (query, id) => query.idEqualTo(id)).findAll();
    return Future.wait(entities.map((e) => _toUpdateEvent(e)).toList());
  }
}
