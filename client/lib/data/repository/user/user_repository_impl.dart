import 'package:tigo/core/wrapper/state_wrapper.dart';
import 'package:tigo/domain/entity/user_brief_state.dart';
import 'package:tigo/data/provider/user/user_provider.dart';
import 'package:tigo/domain/repository/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final UserProvider _userProvider;

  UserRepositoryImpl(this._userProvider);

  @override
  Future<StateWrapper<UserBriefState>> signInWithGoogle() {
    return _userProvider.signInWithGoogle();
  }
}
