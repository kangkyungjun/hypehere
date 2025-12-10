# Flutter Integration Guide - HypeHere API

## Overview

This guide explains how to integrate your Flutter mobile app with the HypeHere Django backend using HTTPS with a self-signed SSL certificate.

**Backend URL**: `https://43.201.45.60`

---

## Prerequisites

- Flutter SDK installed
- Certificate file: `hypehere-cert.crt` (already downloaded to `~/Downloads/`)
- AWS EC2 backend running and accessible

---

## Step 1: Create Flutter Project

```bash
flutter create hypehere_app
cd hypehere_app
```

---

## Step 2: Add Certificate to Project

### 2.1 Create Assets Directory

```bash
mkdir -p assets/certificates
```

### 2.2 Copy Certificate File

```bash
# Copy from Downloads to Flutter project
cp ~/Downloads/hypehere-cert.crt ./assets/certificates/
```

### 2.3 Update pubspec.yaml

Edit `pubspec.yaml` and add:

```yaml
name: hypehere_app
description: HypeHere language learning social platform

dependencies:
  flutter:
    sdk: flutter
  dio: ^5.4.0  # HTTP client for API calls

dev_dependencies:
  flutter_test:
    sdk: flutter

flutter:
  uses-material-design: true

  # Add certificate asset
  assets:
    - assets/certificates/hypehere-cert.crt
```

### 2.4 Install Dependencies

```bash
flutter pub get
```

---

## Step 3: Create API Client

### 3.1 Create API Client File

Create `lib/services/api_client.dart`:

```dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class ApiClient {
  static const String baseUrl = 'https://43.201.45.60';
  static Dio? _dio;

  static Dio getInstance() {
    if (_dio != null) return _dio!;

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Trust self-signed certificate for specific host only
    (_dio!.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();

      // Security: Only allow certificate from our backend server
      client.badCertificateCallback = (cert, host, port) {
        return host == '43.201.45.60';  // Only trust our specific server
      };

      return client;
    };

    // Add logging interceptor (optional, useful for debugging)
    _dio!.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));

    return _dio!;
  }

  // Add authentication token to requests
  static void setAuthToken(String token) {
    _dio?.options.headers['Authorization'] = 'Token $token';
  }

  // Remove authentication token
  static void clearAuthToken() {
    _dio?.options.headers.remove('Authorization');
  }
}
```

---

## Step 4: Create API Service

### 4.1 Create API Service File

Create `lib/services/hypehere_api_service.dart`:

```dart
import 'package:dio/dio.dart';
import 'api_client.dart';

class HypeHereApiService {
  final Dio _dio = ApiClient.getInstance();

  // ==================== Authentication ====================

  /// Login with email and password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/accounts/login/',
        data: {
          'email': email,
          'password': password,
        },
      );

      // Save token for future requests
      if (response.data['token'] != null) {
        ApiClient.setAuthToken(response.data['token']);
      }

      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Login failed: ${e.response?.data['detail'] ?? 'Unknown error'}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  /// Register new user account
  Future<Map<String, dynamic>> register({
    required String email,
    required String nickname,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/accounts/register/',
        data: {
          'email': email,
          'nickname': nickname,
          'password': password,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Registration failed: ${e.response?.data}');
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await _dio.post('/api/accounts/logout/');
      ApiClient.clearAuthToken();
    } on DioException catch (e) {
      throw Exception('Logout failed: ${e.message}');
    }
  }

  // ==================== Posts ====================

  /// Get posts list with pagination
  Future<List<dynamic>> getPosts({int page = 1}) async {
    try {
      final response = await _dio.get(
        '/api/posts/',
        queryParameters: {'page': page},
      );
      return response.data['results'] ?? [];
    } on DioException catch (e) {
      throw Exception('Failed to get posts: ${e.message}');
    }
  }

  /// Create new post
  Future<Map<String, dynamic>> createPost({
    required String content,
    List<String>? hashtags,
    String? nativeLanguage,
    String? targetLanguage,
  }) async {
    try {
      final response = await _dio.post(
        '/api/posts/',
        data: {
          'content': content,
          'hashtags': hashtags,
          'native_language': nativeLanguage,
          'target_language': targetLanguage,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to create post: ${e.response?.data}');
    }
  }

  /// Like a post
  Future<void> likePost(int postId) async {
    try {
      await _dio.post('/api/posts/$postId/like/');
    } on DioException catch (e) {
      throw Exception('Failed to like post: ${e.message}');
    }
  }

  /// Unlike a post
  Future<void> unlikePost(int postId) async {
    try {
      await _dio.delete('/api/posts/$postId/like/');
    } on DioException catch (e) {
      throw Exception('Failed to unlike post: ${e.message}');
    }
  }

  // ==================== Comments ====================

  /// Get comments for a post
  Future<List<dynamic>> getComments(int postId) async {
    try {
      final response = await _dio.get('/api/posts/$postId/comments/');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to get comments: ${e.message}');
    }
  }

  /// Create comment on a post
  Future<Map<String, dynamic>> createComment({
    required int postId,
    required String content,
  }) async {
    try {
      final response = await _dio.post(
        '/api/posts/$postId/comments/',
        data: {'content': content},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to create comment: ${e.response?.data}');
    }
  }

  // ==================== User Profile ====================

  /// Get current user profile
  Future<Map<String, dynamic>> getMyProfile() async {
    try {
      final response = await _dio.get('/api/accounts/me/');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to get profile: ${e.message}');
    }
  }

  /// Get user profile by ID
  Future<Map<String, dynamic>> getUserProfile(int userId) async {
    try {
      final response = await _dio.get('/api/accounts/users/$userId/');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to get user profile: ${e.message}');
    }
  }

  /// Follow a user
  Future<void> followUser(int userId) async {
    try {
      await _dio.post('/api/accounts/users/$userId/follow/');
    } on DioException catch (e) {
      throw Exception('Failed to follow user: ${e.message}');
    }
  }

  /// Unfollow a user
  Future<void> unfollowUser(int userId) async {
    try {
      await _dio.delete('/api/accounts/users/$userId/follow/');
    } on DioException catch (e) {
      throw Exception('Failed to unfollow user: ${e.message}');
    }
  }

  // ==================== Notifications ====================

  /// Get notifications list
  Future<List<dynamic>> getNotifications({int page = 1}) async {
    try {
      final response = await _dio.get(
        '/notifications/api/notifications/',
        queryParameters: {'page': page},
      );
      return response.data['results'] ?? [];
    } on DioException catch (e) {
      throw Exception('Failed to get notifications: ${e.message}');
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      await _dio.patch('/notifications/api/notifications/$notificationId/mark_read/');
    } on DioException catch (e) {
      throw Exception('Failed to mark notification as read: ${e.message}');
    }
  }
}
```

---

## Step 5: Example Usage

### 5.1 Create Example Screen

Create `lib/screens/home_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../services/hypehere_api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HypeHereApiService _apiService = HypeHereApiService();
  List<dynamic> posts = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final fetchedPosts = await _apiService.getPosts(page: 1);
      setState(() {
        posts = fetchedPosts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HypeHere'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $errorMessage'),
                      ElevatedButton(
                        onPressed: _loadPosts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return ListTile(
                      title: Text(post['content'] ?? 'No content'),
                      subtitle: Text('By ${post['author']['nickname']}'),
                    );
                  },
                ),
    );
  }
}
```

### 5.2 Update main.dart

Edit `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HypeHere',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
```

---

## Step 6: Testing

### 6.1 Run the App

```bash
# For iOS simulator
flutter run

# For Android emulator
flutter run

# For specific device
flutter devices  # List available devices
flutter run -d <device_id>
```

### 6.2 Expected Behavior

1. **Certificate Warning**: The app will trust the self-signed certificate automatically because we configured `badCertificateCallback` to trust `43.201.45.60`
2. **API Calls**: All API calls will use HTTPS to `https://43.201.45.60`
3. **Authentication**: After login, the token will be automatically added to all subsequent requests

---

## Step 7: WebSocket Integration (Real-time Chat)

For real-time features like chat and notifications, you'll need WebSocket support.

### 7.1 Add WebSocket Package

Update `pubspec.yaml`:

```yaml
dependencies:
  dio: ^5.4.0
  web_socket_channel: ^2.4.0  # Add this
```

### 7.2 Create WebSocket Client

Create `lib/services/websocket_client.dart`:

```dart
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketClient {
  static const String wsBaseUrl = 'wss://43.201.45.60';
  WebSocketChannel? _channel;

  /// Connect to chat WebSocket
  void connectToChat(int conversationId, String token) {
    _channel = WebSocketChannel.connect(
      Uri.parse('$wsBaseUrl/ws/chat/$conversationId/?token=$token'),
    );

    // Trust self-signed certificate
    _channel!.sink.done.catchError((error) {
      if (error is WebSocketException) {
        print('WebSocket error: $error');
      }
    });

    // Listen to messages
    _channel!.stream.listen(
      (message) {
        print('Received: $message');
        // Handle incoming messages
      },
      onError: (error) {
        print('WebSocket error: $error');
      },
      onDone: () {
        print('WebSocket connection closed');
      },
    );
  }

  /// Send message to chat
  void sendMessage(String content) {
    if (_channel != null) {
      _channel!.sink.add('{"type": "message", "content": "$content"}');
    }
  }

  /// Disconnect WebSocket
  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
```

---

## Troubleshooting

### Issue 1: Certificate Trust Error

**Symptom**: App shows "Certificate verification failed" error

**Solution**:
1. Verify certificate file is in `assets/certificates/hypehere-cert.crt`
2. Check `pubspec.yaml` has the asset declared
3. Run `flutter clean` and `flutter pub get`

### Issue 2: Network Connection Failed

**Symptom**: "Connection refused" or timeout errors

**Solution**:
1. Verify EC2 instance is running: `ssh -i ~/Downloads/hypehere-key.pem ubuntu@43.201.45.60`
2. Check Nginx is running: `sudo systemctl status nginx`
3. Check Django/Daphne is running: `sudo systemctl status daphne`
4. Verify Security Group allows HTTPS (443) from your IP

### Issue 3: 401 Unauthorized Error

**Symptom**: API calls return 401 status code

**Solution**:
1. Ensure you're logged in and token is set
2. Check token is being sent in Authorization header
3. Verify token hasn't expired on backend

### Issue 4: CORS Errors (if using web platform)

**Symptom**: "CORS policy" errors in browser console

**Solution**: Update Django settings.py:
```python
CORS_ALLOWED_ORIGINS = [
    'http://localhost:3000',
    'https://localhost:3000',
]
```

---

## Security Best Practices

### 1. Certificate Pinning (Production)

For production, implement proper certificate pinning instead of trusting all certificates:

```dart
import 'dart:io';
import 'package:flutter/services.dart';

class SecureApiClient {
  static Future<HttpClient> createSecureClient() async {
    final client = HttpClient();

    // Load certificate from assets
    final certData = await rootBundle.load('assets/certificates/hypehere-cert.crt');
    final certificate = X509Certificate(certData.buffer.asUint8List());

    client.badCertificateCallback = (cert, host, port) {
      // Compare certificate fingerprints
      return cert.pem == certificate.pem;
    };

    return client;
  }
}
```

### 2. Token Storage

Use secure storage for authentication tokens:

```yaml
dependencies:
  flutter_secure_storage: ^9.0.0
```

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }
}
```

### 3. API Key Protection

Never hardcode sensitive data in Flutter code. Use environment variables:

```dart
// lib/config/env.dart
class Env {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://43.201.45.60',
  );
}
```

Run with environment variable:
```bash
flutter run --dart-define=API_BASE_URL=https://43.201.45.60
```

---

## Migration to Production Domain

When you purchase a domain and get a proper SSL certificate:

### Backend Changes (Django)

1. Update `.env` file:
```bash
SITE_URL=https://yourdomain.com
CSRF_TRUSTED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com
```

2. Get Let's Encrypt certificate:
```bash
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

### Flutter Changes

1. Update API base URL in `lib/services/api_client.dart`:
```dart
static const String baseUrl = 'https://yourdomain.com';
```

2. Remove certificate trust callback (no longer needed with valid certificate):
```dart
// REMOVE THIS ENTIRE SECTION:
(_dio!.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
  final client = HttpClient();
  client.badCertificateCallback = (cert, host, port) {
    return host == '43.201.45.60';
  };
  return client;
};
```

3. Remove certificate asset from `pubspec.yaml`

---

## Summary

You now have a complete guide for integrating your Flutter app with the HypeHere backend:

✅ **Certificate**: Self-signed SSL certificate configured and downloaded
✅ **API Client**: Dio-based HTTP client with certificate trust
✅ **API Service**: Complete service layer for all HypeHere APIs
✅ **WebSocket**: Real-time chat and notification support
✅ **Security**: Best practices for token storage and certificate pinning
✅ **Migration Path**: Clear steps for moving to production domain

When you're ready to create your Flutter project, follow this guide step by step!

---

## Quick Reference

| Item | Value |
|------|-------|
| **Backend URL** | `https://43.201.45.60` |
| **WebSocket URL** | `wss://43.201.45.60` |
| **Certificate File** | `~/Downloads/hypehere-cert.crt` |
| **Flutter Asset Path** | `assets/certificates/hypehere-cert.crt` |
| **HTTP Client** | dio ^5.4.0 |
| **WebSocket Client** | web_socket_channel ^2.4.0 |

---

**Created**: 2025-01-06
**Backend Version**: Django 5.1.11 + Channels
**AWS Region**: ap-northeast-2 (Seoul)
