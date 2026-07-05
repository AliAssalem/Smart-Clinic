class AppConstants {
  AppConstants._();

  // API
  static const String baseUrl = 'http://192.168.10.122:3000/api/v1';
  // For physical device use your machine IP: 'http://192.168.x.x:3000/api/v1'

  // Storage Keys
  static const String tokenKey = 'access_token';
  static const String userKey = 'user_data';
  static const String roleKey = 'user_role';

  // Timeouts
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;

  // Pagination
  static const int pageSize = 20;
}
