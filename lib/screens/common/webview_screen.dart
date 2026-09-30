import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/error_state_view.dart';

/// 인앱 웹뷰 — 뉴스 원문 · 캘린더 결과 · 약관/개인정보처리방침 공용.
///
/// 호출부 4곳이 이 화면을 공유하므로 여기서 고치면 전부 같이 고쳐진다.
/// 개편 전에는 `onPageFinished` 콜백 하나만 등록돼 있어서 아래가 전부 깨져
/// 있었다: 오프라인이면 영구 흰 화면, 안드로이드 백 버튼이 웹 히스토리를
/// 통째로 버림, `mailto:`·`intent://` 같은 비-http 링크가 죽음, 리다이렉트
/// 중에 스피너가 먼저 꺼짐, 페이월을 만나면 빠져나갈 방법이 없음.
class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key, required this.title, required this.url});

  final String title;
  final String url;

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  /// 웹뷰가 스스로 처리할 수 있는 스킴. 나머지는 OS에 넘긴다 —
  /// 그대로 두면 안드로이드는 ERR_UNKNOWN_URL_SCHEME 에러 페이지를 띄우고
  /// iOS WKWebView는 조용히 취소해서 "눌렀는데 아무 일도 안 남"이 된다.
  static const _handledSchemes = {'http', 'https', 'about', 'data', 'blob'};

  late final WebViewController _controller;

  bool _isLoading = true;
  int _progress = 0;
  String? _errorMessage;
  late String _currentUrl = widget.url;
  bool _backgroundApplied = false;
  bool _firstLoadDone = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _onNavigationRequest,
          onPageStarted: _onPageStarted,
          onProgress: _onProgress,
          onPageFinished: _onPageFinished,
          onWebResourceError: _onWebResourceError,
          onHttpError: _onHttpError,
          onUrlChange: _onUrlChange,
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 다크모드에서 매 로드마다 웹뷰 기본 흰 배경이 번쩍이던 것을 막는다.
    // 테마 접근이 필요해 initState가 아니라 여기서 1회만 적용한다.
    if (!_backgroundApplied) {
      _backgroundApplied = true;
      _controller.setBackgroundColor(context.mlColors.cardBackground);
    }
  }

  // ── 델리게이트 ──────────────────────────────────────────────────────────

  Future<NavigationDecision> _onNavigationRequest(
    NavigationRequest request,
  ) async {
    final uri = Uri.tryParse(request.url);
    if (uri == null || _handledSchemes.contains(uri.scheme)) {
      return NavigationDecision.navigate;
    }
    // mailto: / tel: / intent:// / itms-apps:// 등은 OS에 위임한다.
    await _launchExternal(uri);
    return NavigationDecision.prevent;
  }

  void _onPageStarted(String url) {
    if (!mounted) return;
    // 리다이렉트마다 다시 켠다. 예전에는 단방향(true→false)이라 중간
    // 리다이렉트의 onPageFinished가 스피너를 꺼버렸고, 본문이 뜰 때까지
    // 사용자는 빈 화면을 봤다.
    setState(() {
      _isLoading = true;
      _progress = 0;
      _errorMessage = null;
    });
  }

  void _onProgress(int progress) {
    if (!mounted) return;
    setState(() => _progress = progress);
  }

  void _onPageFinished(String url) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _firstLoadDone = true;
    });
  }

  void _onWebResourceError(WebResourceError error) {
    // 서브리소스(광고·폰트·트래커) 실패로 본문을 가리면 안 된다.
    if (error.isForMainFrame == false) return;
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = error.description.isEmpty ? null : error.description;
    });
  }

  void _onHttpError(HttpResponseError error) {
    final status = error.response?.statusCode;
    if (status == null || status < 400) return;
    // `WebResourceRequest`에는 isForMainFrame이 없다(uri 하나뿐). 그래서
    // 요청 URL이 지금 보고 있는 문서와 같을 때만 막다른 길로 취급한다 —
    // 광고·트래커의 404가 본문을 덮어버리는 것을 막는다.
    final failedUrl = error.request?.uri.toString();
    if (failedUrl != null && failedUrl != _currentUrl) return;
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = 'HTTP $status';
    });
  }

  void _onUrlChange(UrlChange change) {
    final url = change.url;
    if (url == null || !mounted) return;
    setState(() => _currentUrl = url);
  }

  // ── 액션 ────────────────────────────────────────────────────────────────

  Future<void> _launchExternal(Uri uri) async {
    final l10n = AppLocalizations.of(context);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) _toast(l10n.webviewNoAppForLink);
    } catch (_) {
      if (mounted) _toast(l10n.webviewNoAppForLink);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _reload() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
      _progress = 0;
    });
    await _controller.loadRequest(Uri.parse(_currentUrl));
  }

  /// 안드로이드 백 버튼 / iOS 엣지 스와이프가 웹 히스토리를 먼저 소비한다.
  /// 이게 없으면 링크를 몇 번 타고 들어간 뒤 뒤로가기 한 번에 화면 전체가
  /// 닫히고 읽던 맥락이 통째로 사라진다.
  Future<void> _handlePop(bool didPop, Object? result) async {
    if (didPop) return;
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  // ── 빌드 ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.mlColors;
    final host = Uri.tryParse(_currentUrl)?.host ?? '';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          // 제목만으로는 리다이렉트로 광고·제휴 도메인에 도착해도 알 수 없다.
          // 현재 호스트를 항상 같이 보여준다.
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppTypography.headlineMedium,
                  fontWeight: AppTypography.bold,
                  color: colors.textPrimary,
                  height: 1.2,
                ),
              ),
              if (host.isNotEmpty)
                Text(
                  host,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    fontWeight: AppTypography.medium,
                    color: colors.textTertiary,
                    height: 1.2,
                  ),
                ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: l10n.refresh,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              onPressed: _reload,
            ),
            PopupMenuButton<_WebViewAction>(
              icon: const Icon(Icons.more_vert_rounded, size: 20),
              onSelected: (action) {
                switch (action) {
                  case _WebViewAction.openInBrowser:
                    final uri = Uri.tryParse(_currentUrl);
                    if (uri != null) _launchExternal(uri);
                  case _WebViewAction.share:
                    Share.share(_currentUrl);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _WebViewAction.openInBrowser,
                  child: Text(l10n.webviewOpenInBrowser),
                ),
                PopupMenuItem(
                  value: _WebViewAction.share,
                  child: Text(l10n.webviewShare),
                ),
              ],
            ),
          ],
          bottom: _isLoading
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(2),
                  child: LinearProgressIndicator(
                    value: _progress == 0 ? null : _progress / 100,
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                    color: colors.accentBlue,
                  ),
                )
              : null,
        ),
        body: _errorMessage != null
            ? ErrorStateView(
                message: l10n.webviewLoadFailed,
                detail: _errorMessage,
                onRetry: _reload,
                retryLabel: l10n.tryAgain,
              )
            : Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  // 스크림은 **첫 로드에만**. 이후 페이지 내 이동까지 덮으면
                  // 읽던 화면이 매번 백지로 깜빡인다 — 그땐 상단 진행바가 알린다.
                  // (예전에는 스크림 없이 스피너만 떠서 이전 페이지와 겹쳤다.)
                  if (_isLoading && !_firstLoadDone)
                    Positioned.fill(
                      child: ColoredBox(
                        color: colors.cardBackground,
                        child: const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.xl),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

enum _WebViewAction { openInBrowser, share }
