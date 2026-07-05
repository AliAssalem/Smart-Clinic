import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/auth_models.dart';

class AuthDatasource {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  AuthDatasource(this._apiClient, this._storage);

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final result = AuthResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      await _storage.saveToken(result.accessToken);
      await _storage.saveUserData(result.user.toJsonString());
      await _storage.saveRole(result.user.role);
      return result;
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<AuthResponseModel> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    int? specialtyId,
    double? consultationFee,
  }) async {
    try {
      final data = <String, dynamic>{
        'full_name': fullName,
        'email': email,
        'password': password,
        'role': role,
        if (specialtyId != null) 'specialty_id': specialtyId,
        if (consultationFee != null) 'consultation_fee': consultationFee,
      };
      final response = await _apiClient.dio.post('/auth/register', data: data);
      final result = AuthResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      await _storage.saveToken(result.accessToken);
      await _storage.saveUserData(result.user.toJsonString());
      await _storage.saveRole(result.user.role);
      return result;
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final response = await _apiClient.dio.get('/auth/profile');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }

  Future<UserModel?> getCachedUser() async {
    final jsonString = await _storage.getUserData();
    if (jsonString == null) return null;
    return UserModel.fromJsonString(jsonString);
  }

  Future<bool> hasValidSession() async {
    return await _storage.hasToken();
  }
}
