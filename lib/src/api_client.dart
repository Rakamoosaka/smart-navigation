import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  ApiClient()
    : _dio = Dio(
        BaseOptions(
          baseUrl: kIsWeb
              ? 'http://localhost:8000'
              : Platform.isAndroid
              ? 'http://10.0.2.2:8000'
              : 'http://localhost:8000',
          connectTimeout: const Duration(seconds: 2),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );

  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _tokenKey = 'access_token_v2';

  Future<Options> _authorized() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) throw StateError('No active session');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<Map<String, dynamic>> login(String sduId, String password) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'sdu_id': sduId, 'password': password},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    await _storage.write(
      key: _tokenKey,
      value: data['access_token'] as String?,
    );
    return data;
  }

  Future<Map<String, dynamic>> register(
    String sduId,
    String fullName,
    String password,
  ) async {
    final response = await _dio.post(
      '/auth/register',
      data: {'sdu_id': sduId, 'full_name': fullName, 'password': password},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    await _storage.write(
      key: _tokenKey,
      value: data['access_token'] as String?,
    );
    return data;
  }

  Future<Map<String, dynamic>> guest() async {
    final response = await _dio.post('/auth/guest');
    final data = Map<String, dynamic>.from(response.data as Map);
    await _storage.write(
      key: _tokenKey,
      value: data['access_token'] as String?,
    );
    return data;
  }

  Future<void> submitReport(String message, int? locationId) async {
    await _dio.post(
      '/reports',
      data: {'message': message, 'location_id': locationId},
      options: await _authorized(),
    );
  }

  Future<Map<String, dynamic>?> restoreUser() async {
    try {
      if (await _storage.read(key: _tokenKey) == null) return null;
      final response = await _dio.get(
        '/users/me',
        options: await _authorized(),
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (error) {
      if (error is DioException && error.response?.statusCode == 401) {
        await logout();
      }
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> locations() async {
    final response = await _dio.get('/locations');
    return (response.data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> announcements() async {
    final response = await _dio.get('/announcements');
    return (response.data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> favorites() async {
    final response = await _dio.get(
      '/users/me/favorites',
      options: await _authorized(),
    );
    return (response.data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> addFavorite(int locationId) async {
    await _dio.post(
      '/users/me/favorites/$locationId',
      options: await _authorized(),
    );
  }

  Future<void> removeFavorite(int locationId) async {
    await _dio.delete(
      '/users/me/favorites/$locationId',
      options: await _authorized(),
    );
  }

  Future<Map<String, dynamic>> preference() async {
    final response = await _dio.get(
      '/users/me/preferences',
      options: await _authorized(),
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> updatePreference(bool accessibleRoutes) async {
    await _dio.put(
      '/users/me/preferences',
      data: {'accessible_routes': accessibleRoutes},
      options: await _authorized(),
    );
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: 'access_token');
  }
}
