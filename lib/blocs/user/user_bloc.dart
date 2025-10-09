import 'package:flutter_bloc/flutter_bloc.dart';
import 'user_event.dart';
import 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc() : super(const UserState(username: 'Guest', email: '')) {
    on<UpdateUsername>((event, emit) {
      emit(state.copyWith(username: event.username));
    });

    on<UpdateEmail>((event, emit) {
      emit(state.copyWith(email: event.email));
    });

    on<ClearUser>((event, emit) {
      emit(const UserState(username: 'Guest', email: ''));
    });
  }
}
