import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/config.dart';
import '../../../core/models/login_model/user_model.dart';

class ApiService {
  /// Legacy endpoint — fetches all users from the server.
  /// Used by LoginBloc to perform client-side credential validation.
  static const String endpointUrl = "${Config.baseUrl}/user";

  /// New server-side login endpoint.
  static const String loginUrl = "${Config.baseUrl}/api/login";

  /// Fetch all users from the server (client-side auth approach).
  Future<List<User>> fetchUsers() async {
    print("Fetching users from endpoint: $endpointUrl");
    final response = await http.get(Uri.parse(endpointUrl));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<User> users =
          body.map((dynamic item) => User.fromJson(item)).toList();
      print("Users fetched successfully: ${users.length} users");
      return users;
    } else {
      print(
          "Failed to load users. Status Code: ${response.statusCode}");
      throw Exception('Failed to load users');
    }
  }

  /// Server-side login — sends credentials to the backend and validates there.
  /// Returns the authenticated [User] on success.
  /// Throws an [Exception] with the error message on failure.
  Future<User> loginWithCredentials(String userId, String password) async {
    print("Logging in via server-side endpoint: $loginUrl");

    final response = await http.post(
      Uri.parse(loginUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'password': password}),
    );

    final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && jsonBody['success'] == true) {
      final user = User.fromJson(jsonBody['user'] as Map<String, dynamic>);
      print("Server login successful for user: ${user.name}");
      return user;
    } else {
      final error = jsonBody['error'] ?? 'Login failed';
      print("Server login failed: $error");
      throw Exception(error);
    }
  }
}
