import 'package:tigo/core/wrapper/state_wrapper.dart';
import 'package:tigo/domain/entity/user_brief_state.dart';

abstract class UserRepository {
  Future<StateWrapper<UserBriefState>> signInWithGoogle();
}