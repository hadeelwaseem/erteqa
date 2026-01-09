import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SharedPreferencesCubit extends Cubit<dynamic> {
  SharedPreferencesCubit() : super(null);

  late final SharedPreferences prefs;
  Future<void> setup() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> setUsername(String username) async {
    await prefs.setString('username', username);
  }

  Future<void> setId(String id) async {
    await prefs.setString('id', id);
  }

  String? getUsername() {
    final String? username = prefs.getString('username');
    return username;
  }

  String? getId() {
    final String? id = prefs.getString('id');
    return id;
  }

  Future<void> deleteAll() async {
    prefs.clear();
  }

  Future<void> deleteId() async {
    await prefs.remove('id');
  }
}
