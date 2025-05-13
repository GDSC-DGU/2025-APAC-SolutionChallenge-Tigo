import 'package:get/get.dart';
import 'package:tigo/data/repository/user/user_repository_impl.dart';
import 'package:tigo/domain/repository/user_repository.dart';

class InitBinding extends Bindings {
  @override
  void dependencies() {
    // Providers
    // Get.putAsync<AnalysisProvider>(
    //       () async => AnalysisProviderImpl(),
    // );
    // Get.putAsync<NotificationProvider>(
    //       () async => NotificationProviderImpl(),
    // );

    // Repositories
    // Get.putAsync<ActionHistoryRepository>(
    //       () async => ActionHistoryRepositoryImpl(),
    // );
    // Get.putAsync<ChallengeHistoryRepository>(
    //       () async => ChallengeHistoryRepositoryImpl(),
    // );
    Get.putAsync<UserRepository>(() async => UserRepositoryImpl());
    // Get.putAsync<AnalysisRepository>(
    //       () async => AnalysisRepositoryImpl(),
    // );
    // Get.putAsync<FollowRepository>(
    //       () async => FollowRepositoryImpl(),
    // );
    // Get.putAsync<FriendRepository>(
    //       () async => FriendRepositoryImpl(),
    // );
    // Get.putAsync<NotificationRepository>(
    //       () async => NotificationRepositoryImpl(),
    // );
  }
}
