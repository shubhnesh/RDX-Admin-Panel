import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

/// Small persistent cache (survives app restarts, works offline).
/// Stores one JSON snapshot per query key, keeping only the most recent ones.
/// Backed by Hive instead of SharedPreferences.
class InventoryCache {
  static const _boxName = 'inventory_cache_v1';
  static const _prefix = 'snap:';
  static const _indexKey = 'index';
  static const _maxEntries = 12;

  static Future<Box<String>>? _boxFuture;

  /// Opens the box once; safe to call from several places concurrently.
  /// If you already call `Hive.initFlutter()` in main(), the init is a no-op.
  static Future<Box<String>> _box() {
    return _boxFuture ??= () async {
      await Hive.initFlutter();
      return Hive.openBox<String>(_boxName);
    }();
  }

  List<String> _readIndex(Box<String> box) {
    final raw = box.get(_indexKey);
    if (raw == null) return <String>[];
    return List<String>.from(jsonDecode(raw) as List);
  }

  Future<Map<String, dynamic>?> read(String key) async {
    try {
      final box = await _box();
      final raw = box.get('$_prefix$key');
      if (raw == null) return null;
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null; // corrupt/unavailable cache must never break the screen
    }
  }

  Future<void> write(String key, Map<String, dynamic> snapshot) async {
    try {
      final box = await _box();
      await box.put('$_prefix$key', jsonEncode(snapshot));

      final index = _readIndex(box)
        ..remove(key)
        ..add(key);
      final evicted = <String>[];
      while (index.length > _maxEntries) {
        evicted.add('$_prefix${index.removeAt(0)}');
      }
      if (evicted.isNotEmpty) await box.deleteAll(evicted);
      await box.put(_indexKey, jsonEncode(index));
    } catch (_) {}
  }

  /// Call on logout so the next user never sees another account's data.
  Future<void> clear() async {
    try {
      final box = await _box();
      await box.clear();
    } catch (_) {}
  }
}
