import 'package:tigo/core/wrapper/state_wrapper.dart';

abstract class AsyncConditionUseCase<Type, Condition> {
  Future<StateWrapper<Type>> execute(Condition condition);
}
