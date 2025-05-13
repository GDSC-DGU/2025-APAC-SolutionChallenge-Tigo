class UserBriefState {
  final String id;
  final String? email;
  final String? nickname;
  final String? photoUrl;

  const UserBriefState({
    required this.id,
    this.email,
    this.nickname,
    this.photoUrl,
  });

  UserBriefState copyWith({
    String? id,
    String? email,
    String? nickname,
    String? photoUrl,
  }) {
    return UserBriefState(
      id: id ?? this.id,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  factory UserBriefState.initial() {
    return const UserBriefState(
      id: '',
      email: '',
      nickname: '',
      photoUrl: '',
    );
  }
}
