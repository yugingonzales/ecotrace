/// API endpoint configuration for the EcoTrace backend.
///
/// Physical Android devices must use the PC's LAN IP address because `localhost`
/// refers to the phone itself. The Android emulator uses `10.0.2.2` to reach the
/// host machine's `localhost`.
class ApiConfig {
  // TODO: Replace with 10.0.2.2 when running on the Android emulator
  static const String baseUrl = 'http://192.168.1.79:3000/api';

  // Auth endpoints
  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';
  static const String profile = '$baseUrl/auth/profile';

  // Health check
  static const String health = '$baseUrl/health';
}
