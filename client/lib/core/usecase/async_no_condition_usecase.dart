import 'package:tigo/core/wrapper/state_wrapper.dart';

abstract class AsyncNoConditionUseCase<Type> {
  Future<StateWrapper<Type>> execute();
}
