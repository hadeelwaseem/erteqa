// // ignore_for_file: avoid_print

// import 'package:flutter_bloc/flutter_bloc.dart';

// class AppBlocObserver extends BlocObserver {
//   @override
//   void onEvent(Bloc bloc, Object? event) {
//     print('${DateTime.now()}: ${bloc.runtimeType} dispatching event $event');
//     super.onEvent(bloc, event);
//   }

//   @override
//   void onTransition(Bloc bloc, Transition transition) {
//     print(
//         '${DateTime.now()}: ${bloc.runtimeType} transitioning from ${transition.currentState} to ${transition.nextState} due to event ${transition.event}');
//     super.onTransition(bloc, transition);
//   }

//   @override
//   void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
//     print(
//         '${DateTime.now()}: ${bloc.runtimeType} encountered an error $error with stacktrace $stackTrace');
//     super.onError(bloc, error, stackTrace);
//   }

//   @override
//   void onChange(BlocBase bloc, Change change) {
//     print(
//         '${DateTime.now()}: ${bloc.runtimeType} state changed from ${change.currentState} to ${change.nextState}');
//     super.onChange(bloc, change);
//   }

//   @override
//   void onClose(BlocBase bloc) {
//     print('${DateTime.now()}: ${bloc.runtimeType} is being closed');
//     super.onClose(bloc);
//   }

//   @override
//   void onCreate(BlocBase bloc) {
//     print('${DateTime.now()}: ${bloc.runtimeType} is being created');
//     super.onCreate(bloc);
//   }
// }
