import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tigo/app/config/app_routes.dart';
import 'package:tigo/data/factory/storage_factory.dart';
import 'package:tigo/domain/entity/user_brief_state.dart';
import 'package:tigo/core/wrapper/state_wrapper.dart';
import 'package:tigo/domain/repository/user_repository.dart';
import 'package:tigo/presentation/view_model/home/home_view_model.dart';
import 'package:tigo/presentation/view_model/profile/profile_view_model.dart';

class SignInViewModel extends GetxController {
  /* ------------------------------------------------------ */
  /* -------------------- DI Fields ----------------------- */
  /* ------------------------------------------------------ */
  late final FirebaseAuth _firebaseAuth;
  late final UserRepository _userRepository;

  late final String? _beforeRoute;

  /* ------------------------------------------------------ */
  /* ----------------- Private Fields --------------------- */
  /* ------------------------------------------------------ */
  late final Rx<UserBriefState> _userBriefState;
  late final RxBool _isEnableGreyBarrier;

  /* ------------------------------------------------------ */
  /* ----------------- Public Fields ---------------------- */
  /* ------------------------------------------------------ */
  UserBriefState get userBriefState => _userBriefState.value;

  bool get isEnableGreyBarrier => _isEnableGreyBarrier.value;

  @override
  void onInit() async {
    super.onInit();
    // Dependency Injection
    _firebaseAuth = FirebaseAuth.instance;
    _userRepository = Get.find<UserRepository>();

    // Private Fields
    _userBriefState = _userRepository.readUserBriefState().obs;
    _isEnableGreyBarrier = false.obs;
  }


  Future<void> waitForUserDoc(String uid, {int maxRetries = 5}) async {
    final userDocRef = FirebaseFirestore.instance.collection("users").doc(uid);
    int retry = 0;

    while (retry < maxRetries) {
      final snapshot = await userDocRef.get();
      if (snapshot.exists) return;

      retry++;
      await Future.delayed(const Duration(seconds: 1));
    }

    throw Exception("Firestore user doc not created in time");
  }

  Future<bool> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    if (googleUser == null) {
      return false;
    }

    _isEnableGreyBarrier.value = true;
    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create a new credential
    try {
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      _isEnableGreyBarrier.value = false;
      return false;
    }

    print('uid: ${_firebaseAuth.currentUser?.uid}');
    print('email: ${_firebaseAuth.currentUser?.email}');
    print('displayName: ${_firebaseAuth.currentUser?.displayName}');
    print('photoUrl: ${_firebaseAuth.currentUser?.photoURL}');

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await waitForUserDoc(uid); // ✅ Firestore에 사용자 문서 생겼는지 기다림
    }

    // Update User Information
    await _userRepository.updateUserInformation(isSignIn: true);
    // Get.find<HomeViewModel>().fetchUserBriefState();

    StorageFactory.systemProvider.setLogin(true);
    _isEnableGreyBarrier.value = false;
     Get.offAllNamed(AppRoutes.ROOT);
    return true;
  }
}
