/// API endpoint configuration for the EcoTrace backend.
library;

class ApiConfig {
  // Override for a physical device with:
  // flutter run --dart-define=ECOTRACE_API_BASE_URL=http://YOUR_PC_LAN_IP:3000/api
  static const String baseUrl = String.fromEnvironment(
    'ECOTRACE_API_BASE_URL',
    defaultValue: 'http://192.168.1.9:3000/api',
  );

  // Auth endpoints
  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';
  static const String profile = '$baseUrl/auth/profile';

  // Health check
  static const String health = '$baseUrl/health';
  static const String events = '$baseUrl/events?status=active';
  static const String joinedEvents = '$baseUrl/events/joined';
  static const String alerts = '$baseUrl/alerts';
}
