import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final SecureStorageService _instance =
      SecureStorageService._internal();

  factory SecureStorageService() {
    return _instance;
  }

  SecureStorageService._internal();

  final _secureStorage = const FlutterSecureStorage();

  // Keys for tokens
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';

  static const String _accessTokenExpiryKey = 'access_token_expiry';
  static const String _refreshTokenExpiryKey = 'refresh_token_expiry';

  Future<void> saveAccessToken(String token, {int days = 5}) async {
    final expiryDate =
        DateTime.now().add(Duration(days: days)).toIso8601String();

    await _secureStorage.write(key: 'accessToken', value: token);
    await _secureStorage.write(key: 'accessTokenExpiry', value: expiryDate);
  }

  Future<void> saveTokens(
    String accessToken,
    String refreshToken, {
    required DateTime accessTokenExpiresAt,
    required DateTime refreshTokenExpiresAt,
  }) async {
    await _secureStorage.write(key: _keyAccessToken, value: accessToken);
    await _secureStorage.write(key: _keyRefreshToken, value: refreshToken);
    await _secureStorage.write(
      key: _accessTokenExpiryKey,
      value: accessTokenExpiresAt.toIso8601String(),
    );
    await _secureStorage.write(
      key: _refreshTokenExpiryKey,
      value: refreshTokenExpiresAt.toIso8601String(),
    );
  }

  Future<String?> getAccessToken() => _secureStorage.read(key: _keyAccessToken);

  Future<String?> getRefreshToken() =>
      _secureStorage.read(key: _keyRefreshToken);

  Future<DateTime?> getAccessTokenExpiry() async {
    final isoString = await _secureStorage.read(key: _accessTokenExpiryKey);
    if (isoString == null) return null;
    return DateTime.tryParse(isoString);
  }

  Future<DateTime?> getRefreshTokenExpiry() async {
    final isoString = await _secureStorage.read(key: _refreshTokenExpiryKey);
    if (isoString == null) return null;
    return DateTime.tryParse(isoString);
  }

  Future<void> deleteAllTokens() async {
    await _secureStorage.delete(key: _keyAccessToken);
    await _secureStorage.delete(key: _keyRefreshToken);
    await _secureStorage.delete(key: _accessTokenExpiryKey);
    await _secureStorage.delete(key: _refreshTokenExpiryKey);
  }
}
