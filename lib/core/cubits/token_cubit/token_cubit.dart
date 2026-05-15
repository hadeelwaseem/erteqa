import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenCubit extends Cubit<String?> {
  TokenCubit() : super(null);

  static const String _accessTokenKey = 'accessToken';
  static const String _legacyTokenKey = 'token';

  Future<void> fetchSavedToken() async {
    const storage = FlutterSecureStorage();
    String? token = await storage.read(key: _accessTokenKey);
    token ??= await storage.read(key: _legacyTokenKey);
    emit(token);
  }

  Future<void> storeToken(String token) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: _accessTokenKey, value: token);
    await storage.write(key: _legacyTokenKey, value: token);
    emit(token);
  }

  Future<void> deleteSavedToken() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: _accessTokenKey);
    await storage.delete(key: _legacyTokenKey);
    emit(null);
  }
}
