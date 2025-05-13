abstract class UserRemoteProvider {
  /* ------------------------------------------------------------ */
  /* ------------------------ Initialize ------------------------ */
  /* ------------------------------------------------------------ */

  /* ------------------------------------------------------------ */
  /* -------------------------Getter----------------------------- */
  /* ------------------------------------------------------------ */
  // System Information
  Future<bool> getNotificationActive();

  // User Brief Information
  Future<String> getId();
  Future<String> getNickname();
  Future<String> getEmail();
  Future<String> getPhotoUrl();

  /* ------------------------------------------------------------ */
  /* -------------------------- Setter -------------------------- */
  /* ------------------------------------------------------------ */
  // System Information
  Future<void> setNotificationActive(bool isActive);
  Future<void> setDeviceToken(String token);
  Future<void> setDeviceLanguage(String language);

  // User Brief Information
  Future<void> setId(String id);
  Future<void> setNickname(String nickname);
  Future<void> setEmail(String email);
  Future<void> setPhotoUrl(String photoUrl);

  /* ------------------------------------------------------------ */
  /* --------------------------- Read --------------------------- */
  /* ------------------------------------------------------------ */
  Future<List<dynamic>> getUsers(String searchWord);
}
