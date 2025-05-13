abstract class UserLocalProvider {
  /* ------------------------------------------------------------ */
  /* ------------------------ Initialize ------------------------ */
  /* ------------------------------------------------------------ */
  Future<void> onInit();
  Future<void> onReady();
  Future<void> dispose();

  bool getFirstRun();
  bool getSynced();

  Future<void> setFirstRun(bool isFirstRun);
  Future<void> setSynced(bool isSynced);

  /* ------------------------------------------------------------ */
  /* -------------------------Getter----------------------------- */
  /* ------------------------------------------------------------ */
  // System Information
  bool getNotificationActive();
  int getNotificationHour();
  int getNotificationMinute();

  // User Brief Information
  String getId();
  String getNickname();
  String getEmail();
  String getPhotoUrl();

  /* ------------------------------------------------------------ */
  /* -------------------------- Setter -------------------------- */
  /* ------------------------------------------------------------ */
  // System Information
  Future<void> setNotificationActive(bool isActive);
  Future<void> setNotificationHour(int hour);
  Future<void> setNotificationMinute(int minute);

  // User Brief Information
  Future<void> setId(String id);
  Future<void> setNickname(String nickname);
  Future<void> setEmail(String email);
  Future<void> setPhotoUrl(String photoUrl);
}
