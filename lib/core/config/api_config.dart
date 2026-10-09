/// API endpoint configuration for the EcoTrace backend.

class ApiConfig {
  // TODO: Replace with 10.0.2.2 when running on the Android emulator
  static const String baseUrl = 'http://192.168.1.42:3000/api';

  // Auth endpoints
  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';
  static const String profile = '$baseUrl/auth/profile';

  // Health check
  static const String health = '$baseUrl/health';
}
