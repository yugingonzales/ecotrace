import 'package:http/http.dart' as http;

/// Checks whether the internet is genuinely reachable, as opposed to merely
/// having a network transport attached.
abstract class InternetProbe {
  /// Resolves to `true` only when a real request completes successfully.

  /// Implementations must swallow their own errors and return `false` — a
  /// thrown exception here would escape into the connectivity stream.
  Future<bool> isReachable();
}

/// [InternetProbe] that performs a short-timeout HTTP request against a tiny,
/// stable endpoint.
///
class HttpInternetProbe implements InternetProbe {
  HttpInternetProbe({Uri? endpoint}) : _endpoint = endpoint ?? defaultEndpoint;

  /// Public, stable, and returns a tiny response.
  static final Uri defaultEndpoint = Uri.parse(
    'https://www.gstatic.com/generate_204',
  );

  final Uri _endpoint;

  /// Short enough that a dead link fails fast, long enough to survive a slow
  /// mobile handshake.
  static const Duration timeout = Duration(seconds: 5);

  @override
  Future<bool> isReachable() async {
    final client = http.Client();
    try {
      final response = await client.head(_endpoint).timeout(timeout);
      return response.statusCode >= 200 && response.statusCode < 400;
    } on Object {
      return false;
    } finally {
      client.close();
    }
  }
}

/// Probe whose answer is read from a mutable field, so a test can flip
/// reachability without rebuilding the controller.
class ScriptedProbe implements InternetProbe {
  ScriptedProbe(this.answer);

  bool answer;

  @override
  Future<bool> isReachable() async => answer;
}
