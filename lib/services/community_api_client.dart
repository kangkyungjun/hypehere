import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/community/post.dart';
import '../models/community/comment.dart';
import 'auth_service.dart';

class CommunityApiClient {
  static final String _baseUrl =
      dotenv.env['COMMUNITY_API_BASE_URL'] ?? 'http://43.201.45.60:8000/api/community';
  final AuthService _authService = AuthService();

  // Helper method to get headers with auth token
  Future<Map<String, String>> _getHeaders({bool requiresAuth = false}) async {
    final headers = {'Content-Type': 'application/json'};

    if (requiresAuth) {
      final token = await _authService.getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Token $token';
      }
    }

    return headers;
  }

  // Handle authenticated requests
  Future<http.Response> _makeAuthenticatedRequest(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    final headers = await _getHeaders(requiresAuth: true);
    final response = await request(headers);

    // If unauthorized, clear tokens (DRF Token doesn't support refresh)
    if (response.statusCode == 401) {
      await _authService.clearTokens();
    }

    return response;
  }

  // Get all posts or filter by ticker
  Future<List<Post>> getPosts({String? ticker}) async {
    var url = '$_baseUrl/posts/';
    if (ticker != null) {
      url += '?ticker=$ticker';
    }

    // Use auth if available, but don't require it
    final headers = await _getHeaders(requiresAuth: false);
    final token = await _authService.getAccessToken();
    if (token != null) {
      headers['Authorization'] = 'Token $token';
    }

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['results'] as List;
      return results.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load posts');
    }
  }

  // Get single post by ID
  Future<Post> getPost(int id) async {
    // Use auth if available, but don't require it
    final headers = await _getHeaders(requiresAuth: false);
    final token = await _authService.getAccessToken();
    if (token != null) {
      headers['Authorization'] = 'Token $token';
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/posts/$id/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Post.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load post');
    }
  }

  // Create new post (requires auth)
  Future<Post> createPost({
    required String title,
    required String content,
    required String ticker,
  }) async {
    final response = await _makeAuthenticatedRequest((headers) {
      return http.post(
        Uri.parse('$_baseUrl/posts/'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'content': content,
          'ticker': ticker,
        }),
      );
    });

    if (response.statusCode == 201) {
      return Post.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Login required');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error.toString());
    }
  }

  // Like a post (requires auth)
  Future<void> likePost(int postId) async {
    final response = await _makeAuthenticatedRequest((headers) {
      return http.post(
        Uri.parse('$_baseUrl/posts/$postId/like/'),
        headers: headers,
      );
    });

    if (response.statusCode == 400) {
      // Already liked - that's okay, no error
      return;
    } else if (response.statusCode != 201) {
      throw Exception('Failed to like post');
    }
  }

  // Unlike a post (requires auth)
  Future<void> unlikePost(int postId) async {
    final response = await _makeAuthenticatedRequest((headers) {
      return http.delete(
        Uri.parse('$_baseUrl/posts/$postId/unlike/'),
        headers: headers,
      );
    });

    if (response.statusCode == 404) {
      // Not liked - that's okay, no error
      return;
    } else if (response.statusCode != 204) {
      throw Exception('Failed to unlike post');
    }
  }

  // Get comments for a post
  Future<List<Comment>> getComments(int postId) async {
    // Use auth if available, but don't require it
    final headers = await _getHeaders(requiresAuth: false);
    final token = await _authService.getAccessToken();
    if (token != null) {
      headers['Authorization'] = 'Token $token';
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/posts/$postId/comments/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List results = data is List ? data : data['results'] as List;
      return results.map((json) => Comment.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load comments');
    }
  }

  // Create a comment (requires auth)
  Future<Comment> createComment({
    required int postId,
    required String content,
  }) async {
    final response = await _makeAuthenticatedRequest((headers) {
      return http.post(
        Uri.parse('$_baseUrl/posts/$postId/comments/'),
        headers: headers,
        body: jsonEncode({'content': content}),
      );
    });

    if (response.statusCode == 201) {
      return Comment.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Login required');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error.toString());
    }
  }

  // Get current user's posts (requires auth)
  Future<({List<Post> items, int count})> getMyPosts() async {
    final response = await _makeAuthenticatedRequest((headers) {
      return http.get(
        Uri.parse('$_baseUrl/posts/my/'),
        headers: headers,
      );
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['results'] as List;
      final items = results.map((json) => Post.fromJson(json)).toList();
      final count = data['count'] as int? ?? items.length;
      return (items: items, count: count);
    } else if (response.statusCode == 401) {
      throw Exception('Login required');
    } else {
      throw Exception('Failed to load my posts');
    }
  }

  // Get current user's comments (requires auth)
  Future<({List<Comment> items, int count})> getMyComments() async {
    final response = await _makeAuthenticatedRequest((headers) {
      return http.get(
        Uri.parse('$_baseUrl/posts/comments/my/'),
        headers: headers,
      );
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['results'] as List;
      final items = results.map((json) => Comment.fromJson(json)).toList();
      final count = data['count'] as int? ?? items.length;
      return (items: items, count: count);
    } else if (response.statusCode == 401) {
      throw Exception('Login required');
    } else {
      throw Exception('Failed to load my comments');
    }
  }

  // ========================================
  // MarketLens 권한 관리 API (Manager/Master 전용)
  // ========================================

  /// 사용자 검색 (Manager/Master 전용)
  ///
  /// GET http://43.201.45.60:8000/api/accounts/users/search/?q=<query>
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      throw Exception('검색어를 입력해주세요');
    }

    final accountsBaseUrl =
        dotenv.env['AUTH_API_BASE_URL'] ?? 'http://43.201.45.60:8002/api/accounts';
    final url = '$accountsBaseUrl/users/search/?q=${Uri.encodeComponent(query)}';

    final response = await _makeAuthenticatedRequest((headers) {
      return http.get(Uri.parse(url), headers: headers);
    });

    if (response.statusCode == 200) {
      final List<dynamic> results = jsonDecode(response.body);
      return results.cast<Map<String, dynamic>>();
    } else if (response.statusCode == 401) {
      throw Exception('로그인이 필요합니다');
    } else if (response.statusCode == 403) {
      throw Exception('권한이 없습니다. Manager 이상만 접근 가능합니다.');
    } else {
      throw Exception('사용자 검색 실패: ${response.body}');
    }
  }

  /// Gold로 승급 (Manager/Master 전용)
  ///
  /// PATCH http://43.201.45.60:8000/api/accounts/users/<id>/promote-to-gold/
  Future<Map<String, dynamic>> promoteToGold(int userId) async {
    final accountsBaseUrl =
        dotenv.env['AUTH_API_BASE_URL'] ?? 'http://43.201.45.60:8002/api/accounts';
    final url = '$accountsBaseUrl/users/$userId/promote-to-gold/';

    final response = await _makeAuthenticatedRequest((headers) {
      return http.patch(Uri.parse(url), headers: headers);
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('로그인이 필요합니다');
    } else if (response.statusCode == 403) {
      throw Exception('권한이 없습니다. Manager 이상만 Gold로 승급할 수 있습니다.');
    } else if (response.statusCode == 400) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Gold 승급 실패');
    } else {
      throw Exception('Gold 승급 실패: ${response.body}');
    }
  }

  /// Manager로 승급 (Master 전용)
  ///
  /// PATCH http://43.201.45.60:8000/api/accounts/users/<id>/promote-to-manager/
  Future<Map<String, dynamic>> promoteToManager(int userId) async {
    final accountsBaseUrl =
        dotenv.env['AUTH_API_BASE_URL'] ?? 'http://43.201.45.60:8002/api/accounts';
    final url = '$accountsBaseUrl/users/$userId/promote-to-manager/';

    final response = await _makeAuthenticatedRequest((headers) {
      return http.patch(Uri.parse(url), headers: headers);
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('로그인이 필요합니다');
    } else if (response.statusCode == 403) {
      throw Exception('권한이 없습니다. Master만 Manager로 승급할 수 있습니다.');
    } else if (response.statusCode == 400) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Manager 승급 실패');
    } else {
      throw Exception('Manager 승급 실패: ${response.body}');
    }
  }
}
