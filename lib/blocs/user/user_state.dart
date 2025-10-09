class UserState {
  final String username;
  final String email;

  const UserState({required this.username, required this.email});

  UserState copyWith({String? username, String? email}) {
    return UserState(
      username: username ?? this.username,
      email: email ?? this.email,
    );
  }
}
