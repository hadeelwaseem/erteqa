import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenCubit extends Cubit<String?> {
  TokenCubit() : super(null);

  Future<void> fetchSavedToken() async {
    const storage = FlutterSecureStorage();
    // Read value
    String? token = await storage.read(key: 'token');
    emit(token);
  }

  Future<void> storeToken(String token) async {
    const storage = FlutterSecureStorage();
    // Read value
    await storage.write(key: 'token', value: token);
    emit(token);
  }

  Future<void> deleteSavedToken() async {
    const storage = FlutterSecureStorage();
    // Read value
    await storage.delete(key: 'token');
    emit(null);
  }
}
