import 'package:equatable/equatable.dart';

class AuthTokenResponse extends Equatable {
  const AuthTokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    this.issuedAt,
    this.expiresAt,
    this.username,
    this.userId,
    this.tenantId,
    this.tenantSlug,
    this.roles = const <String>[],
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final DateTime? issuedAt;
  final DateTime? expiresAt;
  final String? username;
  final String? userId;
  final String? tenantId;
  final String? tenantSlug;
  final List<String> roles;

  factory AuthTokenResponse.fromJson(Map<String, dynamic> json) {
    final accessToken = _readString(json, const ['accessToken', 'access_token']);
    final refreshToken = _readString(json, const ['refreshToken', 'refresh_token']);
    if (accessToken == null || refreshToken == null) {
      throw const FormatException('Auth token payload is missing access or refresh token');
    }

    return AuthTokenResponse(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: _readString(json, const ['tokenType', 'token_type']) ?? 'Bearer',
      expiresIn: _readInt(json, const ['expiresIn', 'expires_in']) ?? 0,
      issuedAt: _readDateTime(json, const ['issuedAt', 'issued_at']),
      expiresAt: _readDateTime(json, const ['expiresAt', 'expires_at']),
      username: _readString(json, const ['username']),
      userId: _readString(json, const ['userId', 'user_id']),
      tenantId: _readString(json, const ['tenantId', 'tenant_id']),
      tenantSlug: _readString(json, const ['tenantSlug', 'tenant_slug']),
      roles: _readRoles(json['roles']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'tokenType': tokenType,
        'expiresIn': expiresIn,
        'issuedAt': issuedAt?.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'username': username,
        'userId': userId,
        'tenantId': tenantId,
        'tenantSlug': tenantSlug,
        'roles': roles,
      };

  @override
  List<Object?> get props => [
        accessToken,
        refreshToken,
        tokenType,
        expiresIn,
        issuedAt,
        expiresAt,
        username,
        userId,
        tenantId,
        tenantSlug,
        roles,
      ];

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  static int? _readInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) {
        return value;
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  static DateTime? _readDateTime(Map<String, dynamic> json, List<String> keys) {
    final value = _readString(json, keys);
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  static List<String> _readRoles(dynamic value) {
    if (value is List) {
      return value.whereType<String>().toList(growable: false);
    }
    return const <String>[];
  }
}