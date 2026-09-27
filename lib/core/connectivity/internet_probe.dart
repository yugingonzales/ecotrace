import 'package:http/http.dart' as http;

/// Checks whether the internet is genuinely reachable, as opposed to merely
/// having a network transport attached.
///
/// `connectivity_plus` cannot answer this: it reports which interface is up
/// (wifi/mobile/ethernet/none) and nothing more. A device with mobile data
/// enabled but no active plan, no data allowance, or a captive-portal
/// interception still reports `mobile`, so a transport-only check reports a
/// connection the user cannot actually use.
///
/// The probe is defined as an interface so the controller can be driven
/// deterministically in tests without touching the network, and so the
/// endpoint can be swapped for an internal host without changing call sites.
abstract class InternetProbe {
  /// Resolves to `true` only when a real request completes successfully.
  ///
  /// Implementations must swallow their own errors and return `false` — a
  /// thrown exception here would escape into the connectivity stream.
  Future<bool> isReachable();
}

/// [InternetProbe] that performs a short-timeout HTTP request against a tiny,
/// stable endpoint.
///
/// Design notes:
/// - The endpoint is a constant so a deployment behind a private network can
///   repoint it in one place.
/// - A `HEAD` is used so no response body is transferred; the connection is
///   established and the server answers either way.
/// - The timeout is short and deliberately aggressive. This runs on app
///   startup and on every transport change, and a probe that hangs for the
///   platform default would leave the status pinned in a stale state.
/// - DNS failures, refused connections, TLS errors and timeouts all mean the
///   same thing to a caller: not reachable.
class HttpInternetProbe implements InternetProbe {
  HttpInternetProbe({Uri? endpoint}) : _endpoint = endpoint ?? defaultEndpoint;

  /// Public, stable, and returns a tiny response.
  static final Uri defaultEndpoint =
      Uri.parse('https://www.gstatic.com/generate_204');

  final Uri _endpoint;

  /// Short enough that a dead link fails fast, long enough to survive a slow
  /// mobile handshake.
  static const Duration timeout = Duration(seconds: 5);

  @override
  Future<bool> isReachable() async {
    // A fresh client per call keeps ownership trivial — there is nothing to
    // leak or to close on the wrong side. Pooling buys nothing for a single
    // HEAD, and closing promptly releases the keep-alive socket instead of
    // leaving it open on a device that may be on metered data.
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
