import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tigo/data/provider/common/system_provider.dart';

class SystemProviderImpl implements SystemProvider {
  SystemProviderImpl({
    required GetStorage normalStorage,
    required FlutterSecureStorage secureStorage,
  }) : _normalStorage = normalStorage,
       _secureStorage = secureStorage;

  final GetStorage _normalStorage;
  final FlutterSecureStorage _secureStorage;

  static const String _isLoginKey = 'isLogin';
  static const String _isFirstRunKey = 'isFirstRun';

  @override
  Future<void> onInit() async {
    await _normalStorage.writeIfNull(_isFirstRunKey, true);
  }

  @override
  bool get isLogin => _normalStorage.read(_isLoginKey) ?? false;

  @override
  Future<void> setLogin(bool value) async {
    await _normalStorage.write(_isLoginKey, value);
  }

  @override
  bool getFirstRun() {
    return _normalStorage.read(_isFirstRunKey) ?? true;
  }

  @override
  Future<void> setFirstRun(bool isFirstRun) async {
    await _normalStorage.write(_isFirstRunKey, isFirstRun);
  }
}
