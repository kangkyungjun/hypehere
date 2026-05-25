import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../exceptions/api_error_codes.dart';
import '../exceptions/api_exception.dart';
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

  static const _timeout = Duration(seconds: 15);

  // Handle authenticated requests
  Future<http.Response> _makeAuthenticatedRequest(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    final headers = await _getHeaders(requiresAuth: true);
    final response = await request(headers).timeout(_timeout);

    // If unauthorized, clear tokens and throw (DRF Token doesn't support refresh)
    if (response.statusCode == 401) {
      await _authService.clearTokens();
      throw ApiException(ApiErrorCode.sessionExpired, statusCode: 401);
    }

    return response;
  }

  // Get all posts or filter by ticker (with pagination)
  Future<({List<Post> items, int count, bool hasNext})> getPosts({String? ticker, int page = 1}) async {
    var url = '$_baseUrl/posts/?page=$page';
    if (ticker != null) {
      url += '&ticker=$ticker';
    }

    // Use auth if available, but don't require it
    final headers = await _getHeaders(requiresAuth: false);
    final token = await _authService.getAccessToken();
    if (token != null) {
      headers['Authorization'] = 'Token $token';
    }

    final response = await http.get(Uri.parse(url), headers: headers).timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['results'] as List;
      final items = results.map((json) => Post.fromJson(json)).toList();
      final count = data['count'] as int? ?? items.length;
      final hasNext = data['next'] != null;
      return (items: items, count: count, hasNext: hasNext);
    } else {
      throw ApiException(ApiErrorCode.genericError,
          debugMessage: 'Failed to load posts', statusCode: response.statusCode);
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
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      return Post.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(ApiErrorCode.genericError,
          debugMessage: 'Failed to load post', statusCode: response.statusCode);
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
      throw ApiException(ApiErrorCode.loginRequired, statusCode: 401);
    } else {
      final error = jsonDecode(response.body);
      throw ApiException(ApiErrorCode.genericError,
          debugMessage: error.toString(), statusCode: response.statusCode);
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
      throw ApiException(ApiErrorCode.genericError,
          debugMessage: 'Failed to like post', statusCode: response.statusCode);
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
      throw ApiException(ApiErrorCode.genericError,
          debugMessage: 'Failed to unlike post', statusCode: response.statusCode);
    }
  }

  // Like a comment (requires auth) - POST → 201
  Future<void> likeComment(int postId, int commentId) async {
    final response = await _makeAuthenticatedRequest((headers) {
      return http.post(
        Uri.parse('$_baseUrl/posts/$postId/comments/$commentId/like/'),
        headers: headers,
      );
    });

    if (response.statusCode == 400) return; // 이미 좋아요
    if (response.statusCode != 201) {
      throw ApiException(ApiErrorCode.genericError,
          debugMessage: 'Failed to like comment', statusCode: response.statusCode);
    }
  }

  // Unlike a comment (requires auth) - DELETE → 204
  Future<void> unlikeComment(int postId, int commentId) async {
    final response = await _makeAuthenticatedRequest((headers) {
      return http.delete(
        Uri.parse('$_baseUrl/posts/$postId/comments/$commentId/unlike/'),
        headers: headers,
      );
    });

    if (response.statusCode == 404) return; // 이미 취소됨
    if (response.statusCode != 204) {
      throw ApiException(ApiErrorCode.genericError,
          debugMessage: 'Failed to unlike comment', statusCode: response.statusCode);
    }
  }

  // Get comments for a post (paginated)
  Future<({List<Comment> items, int count, bool hasNext})> getComments(int postId, {int page = 1}) async {
    // Use auth if available, but don't require it
    final headers = await _getHeaders(requiresAuth: false);
    final token = await _authService.getAccessToken();
    if (token != null) {
      headers['Authorization'] = 'Token $token';
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/posts/$postId/comments/?page=$page&page_size=10'),
      headers: headers,
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List results = data is List ? data : data['results'] as List;
      final items = results.map((json) => Comment.fromJson(json as Map<String, dynamic>)).toList();
      final count = data is List ? items.length : (data['count'] as int? ?? items.length);
      final hasNext = data is List ? false : data['next'] != null;
      return (items: items, count: count, hasNext: hasNext);
    } else {
      throw ApiException(ApiErrorCode.genericError,
          debugMessage: 'Failed to load comments', statusCode: response.statusCode);
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
      throw ApiException(ApiErrorCode.loginRequired, statusCode: 401);
    } else {
      final error = jsonDecode(response.body);
      throw ApiException(ApiErrorCode.genericError,
          debugMessage: error.toString(), statusCode: response.statusCode);
    }
  }

  // Update a post (requires auth)
  Future<Post> updatePost(int id, {String? title, String? content, String? ticker}) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (content != null) body['content'] = content;
    if (ticker != null) body['ticker'] = ticker;

    final response = await _makeAuthenticatedRequest((headers) {
      return http.put(
        Uri.parse('$_baseUrl/posts/$id/'),
        headers: headers,
        body: jsonEncode(body),
      );
    });

    if (response.statusCode == 200) {
      return Post.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      throw ApiException(ApiErrorCode.loginRequired, statusCode: 401);
    } else if (response.statusCode == 403) {
      throw ApiException(ApiErrorCode.noEditPermission, statusCode: 403);
    } else {
      final error = jsonDecode(response.body);
      throw ApiException(ApiErrorCode.genericError,
          debugMessage: error.toString(), statusCode: response.statusCode);
    }
  }

  // Delete a post (requires auth)
  Future<void> deletePost(int id) async {
    final response = await _makeAuthenticatedRequest((headers) {
      return http.delete(
        Uri.parse('$_baseUrl/posts/$id/'),
        headers: headers,
      );
    });

    if (response.statusCode == 204) {
      return;
    } else if (response.statusCode == 401) {
      throw ApiException(ApiErrorCode.loginRequired, statusCode: 401);
    } else if (response.statusCode == 403) {
      throw ApiException(ApiErrorCode.noDeletePermission, statusCode: 403);
    } else {
      throw ApiException(ApiErrorCode.postDeleteFailed, statusCode: response.statusCode);
    }
  }

  // Update a comment (requires auth)
  Future<Comment> updateComment(int postId, int commentId, {required String content}) async {
    final response = await _makeAuthenticatedRequest((headers) {
      return http.put(
        Uri.parse('$_baseUrl/posts/$postId/comments/$commentId/'),
        headers: headers,
        body: jsonEncode({'content': content}),
      );
    });

    if (response.statusCode == 200) {
      return Comment.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      throw ApiException(ApiErrorCode.loginRequired, statusCode: 401);
    } else if (response.statusCode == 403) {
      throw ApiException(ApiErrorCode.noEditPermission, statusCode: 403);
    } else {
      final error = jsonDecode(response.body);
      throw ApiException(ApiErrorCode.genericError,
          debugMessage: error.toString(), statusCode: response.statusCode);
    }
  }

  // Delete a comment (requires auth)
  Future<void> deleteComment(int postId, int commentId) async {
    final response = await _makeAuthenticatedRequest((headers) {
      return http.delete(
        Uri.parse('$_baseUrl/posts/$postId/comments/$commentId/'),
        headers: headers,
      );
    });

    if (response.statusCode == 204) {
      return;
    } else if (response.statusCode == 401) {
      throw ApiException(ApiErrorCode.loginRequired, statusCode: 401);
    } else if (response.statusCode == 403) {
      throw ApiException(ApiErrorCode.noDeletePermission, statusCode: 403);
    } else {
      throw ApiException(ApiErrorCode.commentDeleteFailed, statusCode: response.statusCode);
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
      throw ApiException(ApiErrorCode.loginRequired, statusCode: 401);
    } else {
      throw ApiException(ApiErrorCode.genericError,
          debugMessage: 'Failed to load my posts', statusCode: response.statusCode);
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
      throw ApiException(ApiErrorCode.loginRequired, statusCode: 401);
    } else {
      throw ApiException(ApiErrorCode.genericError,
          debugMessage: 'Failed to load my comments', statusCode: response.statusCode);
    }
  }

  // Search posts by title/content/hashtags with optional ticker filter
  Future<List<Post>> searchPosts(String query, {String? ticker}) async {
    var url = '$_baseUrl/posts/search/?q=${Uri.encodeComponent(query)}';
    if (ticker != null) {
      url += '&ticker=${Uri.encodeComponent(ticker)}';
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
      // 방어: paginated vs plain list
      final List<dynamic> results = data is List ? data : (data['results'] as List);
      return results.map((json) => Post.fromJson(json)).toList();
    } else {
      throw ApiException(ApiErrorCode.genericError,
          debugMessage: 'Search failed', statusCode: response.statusCode);
    }
  }

  // ========================================
  // MarketLens 권한 관리 API (Manager/Master 전용)
  // ========================================

  /// 사용자 검색/목록 조회 (Manager/Master 전용, 페이지네이션)
  ///
  // GET /api/accounts/users/search/?q=<query>&page=<page>
  // q가 비어있으면 전체 사용자 목록 반환 (최신 가입순)
  Future<({List<Map<String, dynamic>> items, int count, bool hasNext})> getUsers({String? query, int page = 1}) async {
    final accountsBaseUrl =
        dotenv.env['AUTH_API_BASE_URL'] ?? 'http://43.201.45.60:8002/api/accounts';
    var url = '$accountsBaseUrl/users/search/?page=$page';
    if (query != null && query.trim().isNotEmpty) {
      url += '&q=${Uri.encodeComponent(query)}';
    }

    final response = await _makeAuthenticatedRequest((headers) {
      return http.get(Uri.parse(url), headers: headers);
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // 방어: 구버전 서버가 plain List를 반환하는 경우 대응
      if (data is List) {
        final items = data.cast<Map<String, dynamic>>();
        return (items: items, count: items.length, hasNext: false);
      }
      final List<dynamic> results = data['results'] as List;
      final items = results.cast<Map<String, dynamic>>();
      final count = data['count'] as int? ?? items.length;
      final hasNext = data['next'] != null;
      return (items: items, count: count, hasNext: hasNext);
    } else if (response.statusCode == 401) {
      throw ApiException(ApiErrorCode.loginRequired, statusCode: 401);
    } else if (response.statusCode == 403) {
      throw ApiException(ApiErrorCode.managerRequired, statusCode: 403);
    } else {
      throw ApiException(ApiErrorCode.genericError,
          debugMessage: 'User search failed', statusCode: response.statusCode);
    }
  }

  /// 사용자 검색 (하위 호환용 - 기존 searchUsers 래퍼)
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      throw ApiException(ApiErrorCode.searchRequired);
    }
    final result = await getUsers(query: query, page: 1);
    return result.items;
  }

  /// Gold로 승급 (Manager/Master 전용)
  ///
  // PATCH http://43.201.45.60:8000/api/accounts/users/<id>/promote-to-gold/
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
      throw ApiException(ApiErrorCode.loginRequired, statusCode: 401);
    } else if (response.statusCode == 403) {
      throw ApiException(ApiErrorCode.managerRequired, statusCode: 403);
    } else if (response.statusCode == 400) {
      final error = jsonDecode(response.body);
      throw ApiException(ApiErrorCode.genericError,
          debugMessage: error['error'] ?? 'Gold promotion failed', statusCode: 400);
    } else {
      throw ApiException(ApiErrorCode.genericError,
          debugMessage: 'Gold promotion failed', statusCode: response.statusCode);
    }
  }

  /// Manager로 승급 (Master 전용)
  ///
  // PATCH http://43.201.45.60:8000/api/accounts/users/<id>/promote-to-manager/
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
      throw ApiException(ApiErrorCode.loginRequired, statusCode: 401);
    } else if (response.statusCode == 403) {
      throw ApiException(ApiErrorCode.masterRequired, statusCode: 403);
    } else if (response.statusCode == 400) {
      final error = jsonDecode(response.body);
      throw ApiException(ApiErrorCode.genericError,
          debugMessage: error['error'] ?? 'Manager promotion failed', statusCode: 400);
    } else {
      throw ApiException(ApiErrorCode.genericError,
          debugMessage: 'Manager promotion failed', statusCode: response.statusCode);
    }
  }

  // Report a post (requires auth)
  Future<void> reportPost(int postId, {required String reportType, String description = ''}) async {
    final response = await _makeAuthenticatedRequest((headers) {
      return http.post(
        Uri.parse('$_baseUrl/posts/$postId/report/'),
        headers: headers,
        body: jsonEncode({'report_type': reportType, 'description': description}),
      );
    });

    if (response.statusCode == 201) {
      return;
    } else if (response.statusCode == 401) {
      throw ApiException(ApiErrorCode.loginRequired, statusCode: 401);
    } else if (response.statusCode == 400) {
      final error = jsonDecode(response.body);
      final detail = error['detail']?.toString() ?? '';
      if (detail.contains('이미') || detail.contains('already')) {
        throw ApiException(ApiErrorCode.reportAlreadySubmitted,
            debugMessage: detail, statusCode: 400);
      }
      if (detail.contains('자신') || detail.contains('own')) {
        throw ApiException(ApiErrorCode.cannotReportOwnContent,
            debugMessage: detail, statusCode: 400);
      }
      throw ApiException(ApiErrorCode.reportFailed,
          debugMessage: detail, statusCode: 400);
    } else {
      throw ApiException(ApiErrorCode.reportFailed, statusCode: response.statusCode);
    }
  }

  // Report a comment (requires auth)
  Future<void> reportComment(int postId, int commentId, {required String reportType, String description = ''}) async {
    final response = await _makeAuthenticatedRequest((headers) {
      return http.post(
        Uri.parse('$_baseUrl/posts/$postId/comments/$commentId/report/'),
        headers: headers,
        body: jsonEncode({'report_type': reportType, 'description': description}),
      );
    });

    if (response.statusCode == 201) {
      return;
    } else if (response.statusCode == 401) {
      throw ApiException(ApiErrorCode.loginRequired, statusCode: 401);
    } else if (response.statusCode == 400) {
      final error = jsonDecode(response.body);
      final detail = error['detail']?.toString() ?? '';
      if (detail.contains('이미') || detail.contains('already')) {
        throw ApiException(ApiErrorCode.reportAlreadySubmitted,
            debugMessage: detail, statusCode: 400);
      }
      if (detail.contains('자신') || detail.contains('own')) {
        throw ApiException(ApiErrorCode.cannotReportOwnContent,
            debugMessage: detail, statusCode: 400);
      }
      throw ApiException(ApiErrorCode.reportFailed,
          debugMessage: detail, statusCode: 400);
    } else {
      throw ApiException(ApiErrorCode.reportFailed, statusCode: response.statusCode);
    }
  }

  /// Regular로 강등 (Manager→Regular는 Master만, Gold→Regular는 Manager+)
  ///
  // PATCH /api/accounts/users/<id>/demote-to-regular/
  Future<Map<String, dynamic>> demoteToRegular(int userId) async {
    final accountsBaseUrl =
        dotenv.env['AUTH_API_BASE_URL'] ?? 'http://43.201.45.60:8002/api/accounts';
    final url = '$accountsBaseUrl/users/$userId/demote-to-regular/';

    final response = await _makeAuthenticatedRequest((headers) {
      return http.patch(Uri.parse(url), headers: headers);
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw ApiException(ApiErrorCode.loginRequired, statusCode: 401);
    } else if (response.statusCode == 403) {
      final error = jsonDecode(response.body);
      throw ApiException(ApiErrorCode.demotionFailed,
          debugMessage: error['error']?.toString(), statusCode: 403);
    } else if (response.statusCode == 400) {
      final error = jsonDecode(response.body);
      throw ApiException(ApiErrorCode.demotionFailed,
          debugMessage: error['error']?.toString(), statusCode: 400);
    } else {
      throw ApiException(ApiErrorCode.demotionFailed, statusCode: response.statusCode);
    }
  }
}
