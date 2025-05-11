import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tigo/core/wrapper/state_wrapper.dart';
import 'package:tigo/domain/entity/user_brief_state.dart';
import 'user_provider.dart';

class UserProviderImpl implements UserProvider {
  @override
  Future<StateWrapper<UserBriefState>> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return StateWrapper(success: false, message: "구글 로그인 취소", data: null);
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCredential.user;
      if (user == null) {
        return StateWrapper(success: false, message: "유저 정보 없음", data: null);
      }
      final userBrief = UserBriefState(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoURL,
      );
      return StateWrapper(success: true, data: userBrief);
    } catch (e) {
      return StateWrapper(success: false, message: e.toString(), data: null);
    }
  }

  @override
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  }

  @override
  Future<UserBriefState?> getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return UserBriefState(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }
}
