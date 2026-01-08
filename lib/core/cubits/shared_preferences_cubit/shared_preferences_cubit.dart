// ignore_for_file: must_call_super

//import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

//part 'shared_preferences_state.dart';

class SharedPreferencesCubit extends Cubit<dynamic> {
  SharedPreferencesCubit() : super(null);

  late final SharedPreferences prefs;
  Future<void> setup() async {
    prefs = await SharedPreferences.getInstance();
  }

  // Future<void> nothing() async {}

  Future<void> setUsername(String username) async {
    await prefs.setString('username', username);
  }

  Future<void> setId(String id) async {
    await prefs.setString('id', id);
  }
  // Future<void> tempId(String id) async {
  //   await prefs.setString('id', id);
  // }

  Future<void> setFatherName(String fatherName) async {
    await prefs.setString('fatherName', fatherName);
  }

  Future<void> setGrade(String grade) async {
    // emit(SharedPreferencesInitial());

    await prefs.setString('grade', grade);

    // emit(GradeUpdatedState(gradeId: grade));
  }

  Future<void> setpoints(int points) async {
    // int? lastPoints = getPoints();
    // lastPoints ??= 0;
    await prefs.setInt('points', points);
  }

  Future<void> setLastpoints(int lastPoints) async {
    // int? lastPoints = getPoints();
    // lastPoints ??= 0;
    await prefs.setInt('last_points', lastPoints);
  }

  String? getUsername() {
    final String? username = prefs.getString('username');
    return username;
  }

  String? getFatherName() {
    final String? fatherName = prefs.getString('fatherName');
    return fatherName;
  }

  String? getGrade() {
    final String? grade = prefs.getString('grade');
    return grade;
  }

  String? getId() {
    final String? id = prefs.getString('id');
    return id;
    // return null;
  }

  int? getPoints() {
    final int? points = prefs.getInt('points');
    return points;
  }

  int? getLastPoints() {
    final int? points = prefs.getInt('last_points');
    return points;
  }

  Future<void> deleteAll() async {
    prefs.clear();
  }

  Future<void> deleteId() async {
    await prefs.remove('id');
  }

  // @override
  // Future<void> close() {
  //   return nothing();
  // }
}
