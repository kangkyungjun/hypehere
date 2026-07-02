import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../exceptions/api_error_codes.dart';
import '../exceptions/api_exception.dart';
import '../models/admin_dashboard.dart';
import '../models/management_record.dart';
import 'auth_service.dart';

/// 어드민 대시보드 API (Master 전용 — 서버가 403으로 최종 게이트).
/// 모든 호출 Django Token 인증.
class AdminApiClient {
  static final String _baseUrl =
      dotenv.env['API_BASE_URL'] ?? 'http://43.201.45.60:8001';

  final http.Client _httpClient;
  final AuthService _authService;

  AdminApiClient({http.Client? httpClient, AuthService? authService})
    : _httpClient = httpClient ?? http.Client(),
      _authService = authService ?? AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      throw ApiException(
        ApiErrorCode.loginRequired,
        debugMessage: 'Admin requires login',
      );
    }
    return {'Authorization': 'Token $token'};
  }

  Future<http.Response> _get(String path, {Map<String, String>? params}) async {
    final headers = await _headers();
    final uri = Uri.parse(
      '$_baseUrl$path',
    ).replace(queryParameters: params?.isNotEmpty == true ? params : null);
    return _httpClient
        .get(uri, headers: headers)
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Admin request timeout'),
        );
  }

  Future<AdminSummary> getSummary() async {
    final res = await _get('/api/v1/admin/dashboard/summary');
    if (res.statusCode == 200) {
      return AdminSummary.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw ApiException(
        ApiErrorCode.loginRequired,
        statusCode: res.statusCode,
      );
    }
    throw ApiException(ApiErrorCode.serverError, statusCode: res.statusCode);
  }

  Future<List<AdminUserPoint>> getUsersSeries({String range = '30d'}) async {
    final res = await _get(
      '/api/v1/admin/dashboard/users',
      params: {'range': range},
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list
          .map((e) => AdminUserPoint.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw ApiException(
        ApiErrorCode.loginRequired,
        statusCode: res.statusCode,
      );
    }
    throw ApiException(ApiErrorCode.serverError, statusCode: res.statusCode);
  }

  // ── 경영·운영 관리 (ops) ──

  Future<Map<String, String>> _jsonHeaders() async {
    final h = await _headers();
    h['Content-Type'] = 'application/json';
    return h;
  }

  Future<List<ManagementRecord>> getOpsRecords({
    String? kind,
    String? category,
  }) async {
    final params = <String, String>{};
    if (kind != null) params['kind'] = kind;
    if (category != null) params['category'] = category;
    final res = await _get('/api/v1/admin/ops/records', params: params);
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => ManagementRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw _err(res.statusCode);
  }

  Future<ManagementRecord> createOpsRecord(Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl/api/v1/admin/ops/records');
    final res = await _httpClient
        .post(uri, headers: await _jsonHeaders(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200 || res.statusCode == 201) {
      return ManagementRecord.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    throw _err(res.statusCode);
  }

  Future<ManagementRecord> updateOpsRecord(
    int id,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$_baseUrl/api/v1/admin/ops/records/$id');
    final res = await _httpClient
        .patch(uri, headers: await _jsonHeaders(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return ManagementRecord.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    throw _err(res.statusCode);
  }

  Future<void> deleteOpsRecord(int id) async {
    final uri = Uri.parse('$_baseUrl/api/v1/admin/ops/records/$id');
    final res = await _httpClient
        .delete(uri, headers: await _headers())
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw _err(res.statusCode);
  }

  Future<OpsSummary> getOpsSummary({String? month}) async {
    final res = await _get(
      '/api/v1/admin/ops/summary',
      params: month != null ? {'month': month} : null,
    );
    if (res.statusCode == 200) {
      return OpsSummary.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw _err(res.statusCode);
  }

  Future<CategoryBreakdown> getOpsCategoryBreakdown({String? month}) async {
    final res = await _get(
      '/api/v1/admin/ops/category-breakdown',
      params: month != null ? {'month': month} : null,
    );
    if (res.statusCode == 200) {
      return CategoryBreakdown.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    throw _err(res.statusCode);
  }

  Future<List<OpsMonthlyPoint>> getOpsMonthly({int months = 12}) async {
    final res = await _get(
      '/api/v1/admin/ops/monthly',
      params: {'months': '$months'},
    );
    if (res.statusCode == 200) {
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      return (j['months'] as List)
          .map((e) => OpsMonthlyPoint.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw _err(res.statusCode);
  }

  // ── 자산 처분/상태변경 이력 추가 ──
  Future<ManagementRecord> addAssetDisposal(
    int recordId, {
    String kind = 'disposed',
    String? date, // YYYY-MM-DD, null이면 서버가 오늘로 채움
    String? reason,
    String? toStatus, // 폐기/불용/사용중 등 — 동시에 status 갱신
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/api/v1/admin/ops/records/$recordId/disposal',
    );
    final body = <String, dynamic>{
      'kind': kind,
      if (date != null) 'date': date,
      if (reason != null) 'reason': reason,
      if (toStatus != null) 'to_status': toStatus,
    };
    final res = await _httpClient
        .post(uri, headers: await _jsonHeaders(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return ManagementRecord.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    throw _err(res.statusCode);
  }

  // ── 계획 체크리스트 ──
  /// 체크리스트 N개를 한 번에 추가(plan 글에만 허용). 한 트랜잭션.
  /// 반환: 업데이트된 record(전체 subTasks 포함).
  Future<ManagementRecord> addSubTasksBulk(
    int recordId, {
    required List<String> titles,
    String? assignee,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/api/v1/admin/ops/records/$recordId/subtasks/bulk',
    );
    final body = <String, dynamic>{
      'titles': titles,
      if (assignee != null && assignee.isNotEmpty) 'assignee': assignee,
    };
    final res = await _httpClient
        .post(uri, headers: await _jsonHeaders(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      return ManagementRecord.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    throw _err(res.statusCode);
  }

  Future<ManagementRecord> addSubTask(
    int recordId, {
    required String title,
    String? assignee,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/api/v1/admin/ops/records/$recordId/subtasks',
    );
    final body = <String, dynamic>{
      'title': title,
      if (assignee != null && assignee.isNotEmpty) 'assignee': assignee,
    };
    final res = await _httpClient
        .post(uri, headers: await _jsonHeaders(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return ManagementRecord.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    throw _err(res.statusCode);
  }

  Future<ManagementRecord> patchSubTask(
    int recordId,
    int subTaskId, {
    String? title,
    String? assignee,
    bool? done,
    SubTaskStatus? status,
    String? resolutionNote, // status=failed|blocked 일 때 선택
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/api/v1/admin/ops/records/$recordId/subtasks/$subTaskId',
    );
    final body = <String, dynamic>{
      if (title != null) 'title': title,
      if (assignee != null) 'assignee': assignee,
      if (done != null) 'done': done,
      if (status != null) 'status': status.wire,
      if (resolutionNote != null) 'resolution_note': resolutionNote,
    };
    final res = await _httpClient
        .patch(uri, headers: await _jsonHeaders(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return ManagementRecord.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    throw _err(res.statusCode);
  }

  Future<ManagementRecord> deleteSubTask(int recordId, int subTaskId) async {
    final uri = Uri.parse(
      '$_baseUrl/api/v1/admin/ops/records/$recordId/subtasks/$subTaskId',
    );
    final res = await _httpClient
        .delete(uri, headers: await _headers())
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return ManagementRecord.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    throw _err(res.statusCode);
  }

  /// SubTask 코멘트 추가 — 진행 현황 한 줄.
  Future<ManagementRecord> addSubTaskComment(
    int recordId,
    int subTaskId, {
    required String body,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/api/v1/admin/ops/records/$recordId/subtasks/$subTaskId/comments',
    );
    final res = await _httpClient
        .post(
          uri,
          headers: await _jsonHeaders(),
          body: jsonEncode({'body': body}),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return ManagementRecord.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    throw _err(res.statusCode);
  }

  /// SubTask 코멘트 삭제 — 본인 또는 Master만(서버 가드).
  Future<ManagementRecord> deleteSubTaskComment(
    int recordId,
    int subTaskId,
    int commentId,
  ) async {
    final uri = Uri.parse(
      '$_baseUrl/api/v1/admin/ops/records/$recordId/subtasks/$subTaskId/comments/$commentId',
    );
    final res = await _httpClient
        .delete(uri, headers: await _headers())
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return ManagementRecord.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    throw _err(res.statusCode);
  }

  /// SubTask 순서 재정렬 — 드래그 후 신규 id 순서 배열을 보냄.
  /// 보내지 않은 id가 있으면 서버가 기존 순서로 뒤에 붙임(안전).
  Future<ManagementRecord> reorderSubTasks(
    int recordId, {
    required List<int> orderedIds,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/api/v1/admin/ops/records/$recordId/subtasks/reorder',
    );
    final res = await _httpClient
        .post(
          uri,
          headers: await _jsonHeaders(),
          body: jsonEncode({'order': orderedIds}),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return ManagementRecord.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    throw _err(res.statusCode);
  }

  ApiException _err(int code) => (code == 401 || code == 403)
      ? ApiException(ApiErrorCode.loginRequired, statusCode: code)
      : ApiException(ApiErrorCode.serverError, statusCode: code);

  void dispose() => _httpClient.close();
}
