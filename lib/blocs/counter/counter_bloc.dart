import 'package:flutter_bloc/flutter_bloc.dart';
import 'counter_event.dart';
import 'counter_state.dart';

class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(const CounterState(count: 0)) {
    on<IncrementCounter>((event, emit) {
      emit(state.copyWith(count: state.count + 1));
    });

    on<DecrementCounter>((event, emit) {
      emit(state.copyWith(count: state.count - 1));
    });

    on<ResetCounter>((event, emit) {
      emit(const CounterState(count: 0));
    });
  }
}
