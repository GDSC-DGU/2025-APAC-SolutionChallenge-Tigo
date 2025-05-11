class UserBriefState {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  const UserBriefState({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
  });

  factory UserBriefState.initial() {
    return const UserBriefState(
      uid: '',
      email: '',
      displayName: '',
      photoUrl: '',
    );
  }

  UserBriefState copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
  }) {
    return UserBriefState(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
