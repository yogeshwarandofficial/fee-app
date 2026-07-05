import 'package:dio/dio.dart';
import 'package:school_fee_manager/core/api/dio_client.dart';
import 'package:school_fee_manager/core/models/student.dart';

class StudentRepository {
  StudentRepository(this._dioClient);
  final DioClient _dioClient;

  // ── List (paginated + filtered) ─────────────────────────────────────────────
  Future<PaginatedStudents> fetchStudents({
    String? gradeId,
    String? sectionId,
    String? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'limit': limit};
      if (gradeId   != null && gradeId.isNotEmpty)   params['grade_id']   = gradeId;
      if (sectionId != null && sectionId.isNotEmpty) params['section_id'] = sectionId;
      if (status    != null && status.isNotEmpty)    params['status']     = status;
      if (search    != null && search.isNotEmpty)    params['search']     = search;

      final resp = await _dioClient.dio.get('/students', queryParameters: params);
      return PaginatedStudents.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ── Single student ──────────────────────────────────────────────────────────
  Future<Student> fetchStudent(String id) async {
    try {
      final resp = await _dioClient.dio.get('/students/$id');
      return Student.fromJson(resp.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ── Transaction history ─────────────────────────────────────────────────────
  Future<List<Transaction>> fetchHistory(String id) async {
    try {
      final resp = await _dioClient.dio.get('/students/$id/history');
      final list = resp.data['data'] as List<dynamic>? ?? [];
      return list.map((e) => Transaction.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ── Create ──────────────────────────────────────────────────────────────────
  Future<Student> createStudent(Map<String, dynamic> data) async {
    try {
      final resp = await _dioClient.dio.post('/students', data: data);
      return Student.fromJson(resp.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ── Update ──────────────────────────────────────────────────────────────────
  Future<Student> updateStudent(String id, Map<String, dynamic> data) async {
    try {
      final resp = await _dioClient.dio.put('/students/$id', data: data);
      return Student.fromJson(resp.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ── Record payment ──────────────────────────────────────────────────────────
  Future<void> recordPayment(String id, String feeCategory, num amount) async {
    try {
      await _dioClient.dio.put('/students/$id/fees', data: {
        'fee_category': feeCategory,
        'amount': amount,
      });
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ── Add other fee ───────────────────────────────────────────────────────────
  Future<Student> addOtherFee(String id, String description, num amount) async {
    try {
      final resp = await _dioClient.dio.post('/students/$id/other-fee', data: {
        'fee_description': description,
        'amount': amount,
      });
      return Student.fromJson(resp.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ── Delete ──────────────────────────────────────────────────────────────────
  Future<void> deleteStudent(String id) async {
    try {
      await _dioClient.dio.delete('/students/$id');
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ── Export — returns the raw URL so the download is handled separately ──────
  String exportUrl({
    String? gradeId,
    String? sectionId,
    String? status,
    String? search,
    List<String>? ids,
  }) {
    final params = <String>[];
    if (gradeId   != null && gradeId.isNotEmpty)   params.add('grade_id=$gradeId');
    if (sectionId != null && sectionId.isNotEmpty) params.add('section_id=$sectionId');
    if (status    != null && status.isNotEmpty)    params.add('status=$status');
    if (search    != null && search.isNotEmpty)    params.add('search=${Uri.encodeComponent(search)}');
    if (ids       != null && ids.isNotEmpty)       params.add('ids=${ids.join(',')}');
    final base = _dioClient.dio.options.baseUrl;
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    return '$base/students/export$query';
  }

  // ── Download export as bytes ────────────────────────────────────────────────
  Future<List<int>> downloadExport({
    String? gradeId,
    String? sectionId,
    String? status,
    String? search,
    List<String>? ids,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (gradeId   != null && gradeId.isNotEmpty)   params['grade_id']   = gradeId;
      if (sectionId != null && sectionId.isNotEmpty) params['section_id'] = sectionId;
      if (status    != null && status.isNotEmpty)    params['status']     = status;
      if (search    != null && search.isNotEmpty)    params['search']     = search;
      if (ids       != null && ids.isNotEmpty)       params['ids']        = ids.join(',');

      final resp = await _dioClient.dio.get(
        '/students/export',
        queryParameters: params,
        options: Options(responseType: ResponseType.bytes),
      );
      return resp.data as List<int>;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Exception _parseError(DioException e) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic> && data['error'] != null) {
        return Exception(data['error']);
      }
    }
    return Exception(e.message ?? 'Unknown network error');
  }
}
