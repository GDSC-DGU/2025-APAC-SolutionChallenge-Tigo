import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tigo/app/utility/security_util.dart';
import 'package:tigo/data/provider/user/user_remote_provider.dart';

class UserRemoteProviderImpl implements UserRemoteProvider {
  const UserRemoteProviderImpl({required FirebaseFirestore storage})
    : _storage = storage;

  final FirebaseFirestore _storage;

  /* ------------------------- Getter ------------------------- */
  @override
  Future<bool> getNotificationActive() async {
    String uid = SecurityUtil.auth.currentUser!.uid;

    return await _storage
        .collection('users')
        .doc(uid)
        .get()
        .then((value) => value.data()![URPExtension.isNotificationActive]);
  }

  /// Get the user's id.
  @override
  Future<String> getId() async {
    String uid = SecurityUtil.auth.currentUser!.uid;

    return await _storage
        .collection('users')
        .doc(uid)
        .get()
        .then((value) => value.data()![URPExtension.id]);
  }

  @override
  Future<String> getNickname() async {
    String uid = SecurityUtil.auth.currentUser!.uid;

    return await _storage
        .collection('users')
        .doc(uid)
        .get()
        .then((value) => value.data()![URPExtension.nickname]);
  }

  @override
  Future<String> getEmail() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await _storage.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) return '';
    return data[URPExtension.email] ?? '';
  }

  @override
  Future<String> getPhotoUrl() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await _storage.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) return '';
    return data[URPExtension.photoUrl] ?? '';
  }

  /* ------------------------- Setter ------------------------- */
  @override
  Future<void> setNotificationActive(bool isActive) {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    return _storage.collection('users').doc(uid).update({
      URPExtension.isNotificationActive: isActive,
    });
  }

  @override
  Future<void> setDeviceToken(String token) {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    return _storage.collection('users').doc(uid).update({
      URPExtension.deviceToken: token,
    });
  }

  @override
  Future<void> setDeviceLanguage(String language) {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    return _storage.collection('users').doc(uid).update({
      URPExtension.deviceLanguage: language,
    });
  }

  @override
  Future<void> setId(String id) {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    return _storage.collection('users').doc(uid).update({URPExtension.id: id});
  }

  /// Set the user's nickname.
  @override
  Future<void> setNickname(String nickname) {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    return _storage.collection('users').doc(uid).update({
      URPExtension.nickname: nickname,
    });
  }

  /// Set the user's email.
  @override
  Future<void> setEmail(String email) {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    return _storage.collection('users').doc(uid).update({
      URPExtension.email: email,
    });
  }

  @override
  Future<void> setPhotoUrl(String photoUrl) {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    return _storage.collection('users').doc(uid).update({
      URPExtension.photoUrl: photoUrl,
    });
  }

  /* -------------------------- Read -------------------------- */
  @override
  Future<List<dynamic>> getUsers(String searchWord) async {
    List<dynamic> result = await _storage
        .collection('users')
        .where('display_name', isGreaterThanOrEqualTo: searchWord)
        .where('display_name', isLessThan: '${searchWord}z')
        .get()
        .then((value) => value.docs.map((e) => e.data()).toList());

    String uid = FirebaseAuth.instance.currentUser!.uid;
    return result.where((element) => element['id'] != uid).toList();
  }
}

extension URPExtension on UserRemoteProviderImpl {
  // System Information
  static const String isNotificationActive = 'is_notification_active';
  static const String deviceToken = 'device_token';
  static const String deviceLanguage = 'device_language';

  // User Brief Information
  static const String id = 'id';
  static const String nickname = 'nickname';
  static const String email = 'email';
  static const String photoUrl = 'photo_url';
}
