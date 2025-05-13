import 'package:get_storage/get_storage.dart';
import 'package:tigo/data/provider/user/user_local_provider.dart';
import 'package:tigo/data/provider/user/user_local_provider_impl.dart';

abstract class LocalStorageFactory {
  static GetStorage? _instance;

  static UserLocalProvider? _userLocalProvider;
  static UserLocalProvider get userLocalProvider => _userLocalProvider!;

  static Future<void> onInit() async {
    await GetStorage.init();

    _instance = GetStorage();
    _userLocalProvider = UserLocalProviderImpl(storage: _instance!);

    userLocalProvider.onInit();
  }
}
