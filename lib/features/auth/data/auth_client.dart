import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/api_config.dart';

/// Authentication API client for registration and login.
class AuthClient {
  /// Registers a new user account.
  ///
  /// The backend assigns the `volunteer` role server-side regardless of the
  /// submitted staff type. Returns the JWT token and user profile on success.
  ///
  /// Throws [AuthException] with a user-friendly message on failure.
  static Future<AuthResponse> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    String? middleName,
    required String lastName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
          'firstName': firstName.trim(),
          if (middleName != null && middleName.trim().isNotEmpty)
            'middleName': middleName.trim(),
          'lastName': lastName.trim(),
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthResponse(
          token: data['token'] as String,
          user: _parseUser(data['user'] as Map<String, dynamic>),
        );
      }

      // Parse known error responses
      final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
      final error = errorBody['error'] as String?;
      final message = errorBody['message'] as String?;

      if (error == 'email_exists') {
        throw AuthException('An account with this email already exists.');
      } else if (error == 'invalid_request') {
        final details = errorBody['details'] as List?;
        if (details != null && details.isNotEmpty) {
          throw AuthException(
            'Please check your input: ${details.map((d) => d['message']).join(', ')}',
          );
        }
        throw AuthException(message ?? 'Please check the submitted fields.');
      }

      throw AuthException(message ?? 'Registration failed. Please try again.');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        'Cannot reach the server. Check your internet connection.',
      );
    }
  }

  /// Logs in an existing user.
  ///
  /// Returns the JWT token and user profile on success.
  /// Throws [AuthException] with a user-friendly message on failure.
  static Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.login),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthResponse(
          token: data['token'] as String,
          user: _parseUser(data['user'] as Map<String, dynamic>),
        );
      }

      // Parse known error responses
      final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
      final error = errorBody['error'] as String?;
      final message = errorBody['message'] as String?;

      if (error == 'account_not_found') {
        throw AuthException('No account was found for this username.');
      } else if (error == 'incorrect_password') {
        throw AuthException('The password is incorrect.');
      } else if (error == 'invalid_request') {
        throw AuthException('Please provide a valid username and password.');
      }

      throw AuthException(message ?? 'Login failed. Please try again.');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        'Cannot reach the server. Check your internet connection.',
      );
    }
  }

  static User _parseUser(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      middleName: json['middleName'] as String?,
      lastName: json['lastName'] as String,
      role: json['role'] as String,
    );
  }
}

/// Authentication response containing the JWT token and user profile.
class AuthResponse {
  const AuthResponse({required this.token, required this.user});

  final String token;
  final User user;
}

/// Stores the authenticated mobile session only when the user opts in.
class AuthSession {
  static const _tokenKey = 'auth.token';
  static const _userKey = 'auth.user';

  static Future<void> save(AuthResponse response) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_tokenKey, response.token);
    await preferences.setStringList(_userKey, [
      response.user.id.toString(),
      response.user.email,
      response.user.firstName,
      response.user.middleName ?? '',
      response.user.lastName,
      response.user.role,
    ]);
  }

  static Future<AuthResponse?> restore() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString(_tokenKey);
    final values = preferences.getStringList(_userKey);
    if (token == null || values == null || values.length != 6) return null;

    final id = int.tryParse(values[0]);
    if (id == null) return null;
    return AuthResponse(
      token: token,
      user: User(
        id: id,
        email: values[1],
        firstName: values[2],
        middleName: values[3].isEmpty ? null : values[3],
        lastName: values[4],
        role: values[5],
      ),
    );
  }

  static Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
    await preferences.remove(_userKey);
  }
}

/// User profile returned from authentication endpoints.
class User {
  const User({
    required this.id,
    required this.email,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.role,
  });

  final int id;
  final String email;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String role;

  String get fullName {
    final middle = middleName;
    return middle != null && middle.isNotEmpty
        ? '$firstName $middle $lastName'
        : '$firstName $lastName';
  }
}

/// Authentication error with a user-friendly message.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
