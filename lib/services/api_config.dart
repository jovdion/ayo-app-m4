class ApiConfig {
  static const String baseUrl =
      'https://ayo-app-backend-870764645625.asia-southeast2.run.app';

  // Auth endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';

  // Chat endpoints
  static const String sendMessageEndpoint = '/api/chat/send';
  static const String getMessagesEndpoint = '/api/chat/messages';

  // User endpoints
  static const String getUsersEndpoint = '/api/users';
  static const String getUserProfileEndpoint = '/api/users/profile';
  static const String updateProfileEndpoint = '/api/users/profile';
}
