import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/game.dart';
import '../models/session.dart';

class ApiService {
  static const String baseUrl = 'http://localhost/LFG/api/';
  
  static Uri _buildUri(String route, [Map<String, String>? extraParams]) {
    final params = {'route': route};
    if (extraParams != null) {
      params.addAll(extraParams);
    }
    return Uri.parse(baseUrl).replace(queryParameters: params);
  }

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
    };
    final userId = prefs.getString('userId');
    if (userId != null) {
      headers['X-User-Id'] = userId;
    }
    return headers;
  }

  static dynamic _handleResponse(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(body);
    } else {
      try {
        final error = jsonDecode(body);
        throw Exception(error['error'] ?? 'Request failed with status ${response.statusCode}');
      } catch (e) {
        throw Exception('Request failed with status ${response.statusCode}: $body');
      }
    }
  }

  // ==================== AUTH ENDPOINTS ====================
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        _buildUri('auth/register'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        _buildUri('auth/login'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final result = _handleResponse(response);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', result['user']['id'].toString());
      
      return result;
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
  }

  static Future<User> getUser(int userId) async {
    try {
      final response = await http.get(
        _buildUri('auth/user/$userId'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      );

      final data = _handleResponse(response);
      return User.fromJson(data);
    } catch (e) {
      throw Exception('Get user error: $e');
    }
  }

  // ==================== GAME ENDPOINTS ====================
  static Future<Map<String, dynamic>> addGame({
    required String title,
    String? platform,
    String? genre,
    int? releaseYear,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        _buildUri('games/add'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'platform': platform,
          'genre': genre,
          'release_year': releaseYear,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Add game error: $e');
    }
  }

  static Future<List<Game>> getUserGames(int userId, {String? platform, String? genre, String? search}) async {
    try {
      final extraParams = <String, String>{};
      if (platform != null) extraParams['platform'] = platform;
      if (genre != null) extraParams['genre'] = genre;
      if (search != null) extraParams['search'] = search;

      final response = await http.get(
        _buildUri('games/user/$userId', extraParams),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      );

      final data = _handleResponse(response) as List;
      return data.map((game) => Game.fromJson(game)).toList();
    } catch (e) {
      throw Exception('Get games error: $e');
    }
  }

  static Future<void> deleteGame(int gameId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        _buildUri('games/$gameId'),
        headers: headers,
      );

      _handleResponse(response);
    } catch (e) {
      throw Exception('Delete game error: $e');
    }
  }

  // ==================== FRIEND ENDPOINTS ====================
  static Future<Map<String, dynamic>> addFriend(String friendEmail) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        _buildUri('friends/add'),
        headers: headers,
        body: jsonEncode({'friendEmail': friendEmail}),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Add friend error: $e');
    }
  }

  static Future<List<User>> getFriends(int userId) async {
    try {
      final response = await http.get(
        _buildUri('friends/$userId'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      );

      final data = _handleResponse(response) as List;
      return data.map((friend) => User.fromJson(friend)).toList();
    } catch (e) {
      throw Exception('Get friends error: $e');
    }
  }

  static Future<List<Game>> getFriendGames(int userId, int friendId) async {
    try {
      final response = await http.get(
        _buildUri('friends/$userId/games/$friendId'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      );

      final data = _handleResponse(response) as List;
      return data.map((game) => Game.fromJson(game)).toList();
    } catch (e) {
      throw Exception('Get friend games error: $e');
    }
  }

  // ==================== SESSION ENDPOINTS ====================
  static Future<List<Session>> getSessionFeed(int userId) async {
    try {
      final response = await http.get(
        _buildUri('sessions/feed/$userId'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      );

      final data = _handleResponse(response) as List;
      return data.map((session) => Session.fromJson(session)).toList();
    } catch (e) {
      throw Exception('Get session feed error: $e');
    }
  }

  static Future<List<SessionAttendee>> getSessionRsvps(int sessionId) async {
    try {
      final response = await http.get(
        _buildUri('sessions/$sessionId/rsvps'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      );

      final data = _handleResponse(response) as List;
      return data.map((rsvp) => SessionAttendee.fromJson(rsvp)).toList();
    } catch (e) {
      throw Exception('Get session RSVPs error: $e');
    }
  }

  static Future<Map<String, dynamic>> createSession({
    required int gameId,
    required DateTime sessionDateTime,
    String? location,
    int? maxPlayers,
    String? note,
    List<int>? invitedFriendIds,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        _buildUri('sessions/create'),
        headers: headers,
        body: jsonEncode({
          'gameId': gameId,
          'session_datetime': sessionDateTime.toIso8601String(),
          'location': location,
          'max_players': maxPlayers,
          'note': note,
          'invitedFriendIds': invitedFriendIds,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Create session error: $e');
    }
  }

  static Future<List<Session>> getUserSessions(int userId, {String? status}) async {
    try {
      final extraParams = status != null ? {'status': status} : null;
      
      final response = await http.get(
        _buildUri('sessions/user/$userId', extraParams),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      );

      final data = _handleResponse(response) as List;
      return data.map((session) => Session.fromJson(session)).toList();
    } catch (e) {
      throw Exception('Get sessions error: $e');
    }
  }

  static Future<Session> getSessionDetails(int sessionId) async {
    try {
      final response = await http.get(
        _buildUri('sessions/$sessionId'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      );

      final data = _handleResponse(response);
      return Session.fromJson(data);
    } catch (e) {
      throw Exception('Get session details error: $e');
    }
  }

  static Future<void> rsvpSession(int sessionId, String rsvpStatus) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        _buildUri('sessions/$sessionId/rsvp'),
        headers: headers,
        body: jsonEncode({'rsvpStatus': rsvpStatus}),
      );

      _handleResponse(response);
    } catch (e) {
      throw Exception('RSVP error: $e');
    }
  }

  static Future<void> markAttendance(int sessionId, List<int> attendedUserIds) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        _buildUri('sessions/$sessionId/attendance'),
        headers: headers,
        body: jsonEncode({'attendedUserIds': attendedUserIds}),
      );

      _handleResponse(response);
    } catch (e) {
      throw Exception('Mark attendance error: $e');
    }
  }

  // ==================== HELPER METHODS ====================
  static Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> testApi() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('API connection error: $e');
    }
  }

  static Future<User> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      
      if (userId == null) {
        throw Exception('No user logged in');
      }
      
      return getUser(int.parse(userId));
    } catch (e) {
      throw Exception('Get current user error: $e');
    }
  }
}