import 'package:get_storage/get_storage.dart';
import 'package:tigo/data/provider/user/user_local_provider.dart';

class UserLocalProviderImpl implements UserLocalProvider {
  UserLocalProviderImpl({required GetStorage storage}) : _storage = storage;

  final GetStorage _storage;

  /* ------------------------------------------------------------ */
  /* ------------------------ Initialize ------------------------ */
  /* ------------------------------------------------------------ */
  @override
  Future<void> onInit() async {
    await _storage.writeIfNull(ULPExtension.isFirstRun, true);
    await _storage.writeIfNull(ULPExtension.isSynced, false);
  }

  /// Initialize the user data.
  @override
  Future<void> onReady() async {
    // User Setting
    await _storage.writeIfNull(ULPExtension.isNotificationActive, true);
    await _storage.writeIfNull(ULPExtension.notificationHour, 8);
    await _storage.writeIfNull(ULPExtension.notificationMinute, 0);

    // User Brief Information
    await _storage.writeIfNull(ULPExtension.id, 'GUEST');
    await _storage.writeIfNull(ULPExtension.nickname, 'GUEST');

    // User Detail Information
    await _storage.writeIfNull(ULPExtension.totalPositiveDeltaCO2, 0.0);
    await _storage.writeIfNull(ULPExtension.totalNegativeDeltaCO2, 0.0);

    // Character State
    await _storage.writeIfNull(ULPExtension.healthCondition, true);
    await _storage.writeIfNull(ULPExtension.mentalCondition, true);
    await _storage.writeIfNull(ULPExtension.cashCondition, true);
  }

  @override
  Future<void> dispose() async {
    await _storage.erase();

    await _storage.write(ULPExtension.isFirstRun, false);
    await _storage.write(ULPExtension.isSynced, false);

    await _storage.write(ULPExtension.isNotificationActive, false);
    await _storage.write(ULPExtension.notificationHour, 0);
    await _storage.write(ULPExtension.notificationMinute, 0);

    await _storage.write(ULPExtension.id, 'GUEST');
    await _storage.write(ULPExtension.nickname, 'GUEST');

    await _storage.write(ULPExtension.totalPositiveDeltaCO2, 0.0);
    await _storage.write(ULPExtension.totalNegativeDeltaCO2, 0.0);

    await _storage.write(ULPExtension.healthCondition, true);
    await _storage.write(ULPExtension.mentalCondition, true);
    await _storage.write(ULPExtension.cashCondition, true);
  }

  @override
  bool getFirstRun() {
    return _storage.read(ULPExtension.isFirstRun)!;
  }

  @override
  bool getSynced() {
    return _storage.read(ULPExtension.isSynced)!;
  }

  @override
  Future<void> setFirstRun(bool isFirstRun) async {
    await _storage.write(ULPExtension.isFirstRun, isFirstRun);
  }

  @override
  Future<void> setSynced(bool isSynced) async {
    await _storage.write(ULPExtension.isSynced, isSynced);
  }

  /* ------------------------------------------------------------ */
  /* -------------------------- Getter -------------------------- */
  /* ------------------------------------------------------------ */
  /// Get the user's alarm active state.
  @override
  bool getNotificationActive() {
    return _storage.read(ULPExtension.isNotificationActive) ?? false;
  }

  /// Get the user's alarm hour.
  @override
  int getNotificationHour() {
    return _storage.read(ULPExtension.notificationHour) ?? 8;
  }

  /// Get the user's alarm minute.
  @override
  int getNotificationMinute() {
    return _storage.read(ULPExtension.notificationMinute) ?? 0;
  }

  /// Get the user's id.
  @override
  String getId() {
    return _storage.read(ULPExtension.id) ?? 'GUEST';
  }

  /// Get the user's nickname.
  @override
  String getNickname() {
    return _storage.read(ULPExtension.nickname) ?? 'GUEST';
  }

  /// Get the user's email.
  @override
  String getEmail() {
    return _storage.read(ULPExtension.email) ?? '';
  }

  /// Get the user's photo url.
  @override
  String getPhotoUrl() {
    return _storage.read(ULPExtension.photoUrl) ?? '';
  }

  /* ------------------------------------------------------------ */
  /* -------------------------- Setter -------------------------- */
  /* ------------------------------------------------------------ */
  /// Set the user's alarm active state.
  @override
  Future<void> setNotificationActive(bool isActive) async {
    await _storage.write(ULPExtension.isNotificationActive, isActive);
  }

  /// Set the user's alarm hour.
  @override
  Future<void> setNotificationHour(int hour) async {
    await _storage.write(ULPExtension.notificationHour, hour);
  }

  /// Set the user's alarm minute.
  @override
  Future<void> setNotificationMinute(int minute) async {
    await _storage.write(ULPExtension.notificationMinute, minute);
  }

  /// Set the user's id.
  @override
  Future<void> setId(String id) async {
    await _storage.write(ULPExtension.id, id);
  }

  /// Set the user's nickname.
  @override
  Future<void> setNickname(String nickname) async {
    await _storage.write(ULPExtension.nickname, nickname);
  }

  /// Set the user's email.
  @override
  Future<void> setEmail(String email) async {
    await _storage.write(ULPExtension.email, email);
  }

  /// Set the user's photo url.
  @override
  Future<void> setPhotoUrl(String photoUrl) async {
    await _storage.write(ULPExtension.photoUrl, photoUrl);
  }
}

extension ULPExtension on UserLocalProviderImpl {
  // Initialize Setting
  static const String isFirstRun = 'is_first_run';
  static const String isSynced = 'is_synced';

  // System Information
  static const String isNotificationActive = 'is_notification_active';
  static const String notificationHour = 'notification_hour';
  static const String notificationMinute = 'notification_minute';

  // User Brief Information
  static const String id = 'id';
  static const String nickname = 'nickname';

  // User Detail Information
  static const String totalPositiveDeltaCO2 = 'total_positive_delta_co2';
  static const String totalNegativeDeltaCO2 = 'total_negative_delta_co2';

  // Character State
  static const String healthCondition = 'health_condition';
  static const String mentalCondition = 'mental_condition';
  static const String cashCondition = 'cash_condition';

  // User Brief Information
  static const String displayName = 'display_name';
  static const String email = 'email';
  static const String photoUrl = 'photo_url';
}
