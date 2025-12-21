import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../config/app_config.dart';
import '../utils/network_utils.dart';

/// Main WebView Screen
/// Loads the Django web application with full functionality
class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  double _loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _checkNetworkConnection();
  }

  /// Initialize WebView controller with settings
  void _initializeWebView() async {
    print('[WEBVIEW] Initializing with base URL: ${AppConfig.baseUrl}');

    // Platform-specific configurations for cookie support
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('[WEBVIEW] Page started: $url');
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress / 100;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
              _loadingProgress = 1.0;
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('[WEBVIEW] ERROR - URL: ${error.url}');
            print('[WEBVIEW] ERROR - Description: ${error.description}');
            print('[WEBVIEW] ERROR - Error code: ${error.errorCode}');
            print('[WEBVIEW] ERROR - Type: ${error.errorType}');
            setState(() {
              _hasError = true;
              _errorMessage = error.description;
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            print('[WEBVIEW] Navigation request: ${request.url}');
            // Allow all navigation
            return NavigationDecision.navigate;
          },
        ),
      );

    // Enable cookies for Android
    if (_controller.platform is AndroidWebViewController) {
      final androidController = _controller.platform as AndroidWebViewController;
      await androidController.setMediaPlaybackRequiresUserGesture(false);
      print('[WEBVIEW] Android cookies enabled');
    }

    // Load the page
    await _controller.loadRequest(Uri.parse(AppConfig.baseUrl));
  }

  /// Check network connection before loading
  Future<void> _checkNetworkConnection() async {
    final hasNetwork = await NetworkUtils.hasNetworkConnection();

    if (!hasNetwork) {
      setState(() {
        _hasError = true;
        _errorMessage = AppConfig.networkErrorMessage;
        _isLoading = false;
      });
      return;
    }

    final canReach = await NetworkUtils.canReachServer();

    if (!canReach) {
      setState(() {
        _hasError = true;
        _errorMessage = AppConfig.serverErrorMessage;
        _isLoading = false;
      });
    }
  }

  /// Reload the web page
  Future<void> _reload() async {
    setState(() {
      _hasError = false;
      _isLoading = true;
    });

    await _checkNetworkConnection();

    if (!_hasError) {
      await _controller.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: Stack(
            children: [
          // WebView
          if (!_hasError)
            WebViewWidget(controller: _controller),

          // Error Screen
          if (_hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Connection Error',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),

          // Loading Progress Indicator
          if (_isLoading && !_hasError)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _loadingProgress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

          // Loading Overlay (initial load)
          if (_isLoading && _loadingProgress < 0.1)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading HypeHere...'),
                  ],
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
