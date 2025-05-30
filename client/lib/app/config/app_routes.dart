// ignore_for_file: constant_identifier_names

abstract class AppRoutes {
  // 스플래시, 온보딩, 로그인
  static const String SPLASH = '/splash';
  static const String ON_BOARDING = '/on-boarding';
  static const String SIGN_IN = '/sign-in';

  // 루트 탭
  static const String ROOT = '/';

  // 앱 설정
  static const String APP_SETTING = '/app-setting';

  // Gemini 라이브 챗봇 화면
  static const String GEMINI_LIVE_CHAT = '/gemini-live-chat';

  // Tigo 계획표 생성중 화면
  static const String TIGO_PLAN_CHAT = '/tigo-plan-chat';

  // 계획표 리스트 화면
  static const String PLAN_LIST = '/plan-list';

  // 계획표 생성중
  static const String TIGO_PLAN_CREATING = '/tigo-plan-creating';

  // 계획표 테스트 화면
  static const String QUICK_PLAN_TEST = '/quick-plan-test';

  // Tigo 계획표 생성완료 화면
  static const String TIGO_PLAN_COMPLETED = '/tigo-plan-completed';
}
