abstract class UserEvent {}

class UpdateUsername extends UserEvent {
  final String username;

  UpdateUsername(this.username);
}

class UpdateEmail extends UserEvent {
  final String email;

  UpdateEmail(this.email);
}

class ClearUser extends UserEvent {}
