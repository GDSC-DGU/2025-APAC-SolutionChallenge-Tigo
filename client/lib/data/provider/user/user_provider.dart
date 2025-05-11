import 'package:tigo/core/wrapper/state_wrapper.dart';
import 'package:tigo/domain/entity/user_brief_state.dart';

abstract class UserProvider {
  Future<StateWrapper<UserBriefState>> signInWithGoogle();
  Future<void> signOut();
  Future<UserBriefState?> getCurrentUser();
}
