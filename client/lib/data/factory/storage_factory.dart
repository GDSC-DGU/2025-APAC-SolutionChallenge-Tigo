import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tigo/data/provider/common/system_provider.dart';
import 'package:tigo/data/provider/common/system_provider_impl.dart';

class StorageFactory {
  static late final GetStorage _normalStorage;
  static late final FlutterSecureStorage _secureStorage;

  static SystemProvider? _systemProvider;

  static SystemProvider get systemProvider => _systemProvider!;

  static Future<void> onInit() async {
    await GetStorage.init();

    _normalStorage = GetStorage();
    _secureStorage = const FlutterSecureStorage();
  }

  static Future<void> onReady() async {
    _systemProvider = SystemProviderImpl(
      normalStorage: _normalStorage,
      secureStorage: _secureStorage,
    );

    await _systemProvider!.onInit();
  }
}
