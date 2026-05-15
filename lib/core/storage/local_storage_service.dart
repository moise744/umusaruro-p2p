import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:umusaruro_p2p/core/constants/app_constants.dart';
import 'package:flutter/foundation.dart';

/// LocalStorageService handles local data persistence using Hive
class LocalStorageService {
  static const String _boxName = 'umusaruro_box';
  late Box<dynamic> _box;
  Future<void>? _initFuture;

  /// Initialize Hive and open the box
  Future<void> init() async {
    if (_initFuture != null) {
      return _initFuture;
    }

    _initFuture = _init();
    return _initFuture;
  }

  Future<void> _init() async {
    try {
      // Set Hive directory to app documents
      final appDir = await getApplicationDocumentsDirectory();
      Hive.init(appDir.path);

      // Open the box
      _box = await Hive.openBox(_boxName);
    } catch (e) {
      debugPrint('Error initializing LocalStorageService: $e');
      rethrow;
    }
  }

  /// Save a value
  Future<void> save(String key, dynamic value) async {
    await init();
    await _box.put(key, value);
  }

  /// Get a value
  Future<T?> get<T>(String key, {T? defaultValue}) async {
    await init();
    try {
      return _box.get(key, defaultValue: defaultValue) as T?;
    } catch (e) {
      return defaultValue;
    }
  }

  /// Delete a value
  Future<void> delete(String key) async {
    await init();
    await _box.delete(key);
  }

  /// Clear all data
  Future<void> clear() async {
    await init();
    await _box.clear();
  }

  /// Check if key exists
  Future<bool> exists(String key) async {
    await init();
    return _box.containsKey(key);
  }

  Future<bool> isOnboardingDone() async {
    await init();
    return _box.get(AppConstants.onboardingDoneKey, defaultValue: false)
        as bool;
  }

  Future<void> setOnboardingDone() async {
    await init();
    await _box.put(AppConstants.onboardingDoneKey, true);
  }

  /// Get box
  Future<Box<dynamic>> getBox() async {
    await init();
    return _box;
  }
}
