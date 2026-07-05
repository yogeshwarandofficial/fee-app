import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_fee_manager/core/api/dio_client.dart';
import 'package:school_fee_manager/core/models/master_config.dart';

// ── Repository ──────────────────────────────────────────────────────────────

class MasterConfigRepository {
  MasterConfigRepository(this._dioClient);
  final DioClient _dioClient;

  Future<List<MasterConfig>> fetchConfigs({String? type, String? parentId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (type != null) queryParams['type'] = type;
      if (parentId != null) queryParams['parent_id'] = parentId;

      final response = await _dioClient.dio.get('/master-config', queryParameters: queryParams);
      final data = response.data['data'] as List<dynamic>;
      return data.map((e) => MasterConfig.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<MasterConfig> createConfig(String type, String name, {String? parentId}) async {
    try {
      final data = {'type': type, 'name': name};
      if (parentId != null) data['parent_id'] = parentId;

      final response = await _dioClient.dio.post('/master-config', data: data);
      return MasterConfig.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<MasterConfig> updateConfig(String id, String name) async {
    try {
      final response = await _dioClient.dio.put('/master-config/$id', data: {'name': name});
      return MasterConfig.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<void> deleteConfig(String id) async {
    try {
      await _dioClient.dio.delete('/master-config/$id');
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Exception _parseError(DioException e) {
    if (e.response != null && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic> && data['error'] != null) {
        return Exception(data['error']);
      }
    }
    return Exception(e.message ?? 'Unknown error occurred');
  }
}

// ── Providers ───────────────────────────────────────────────────────────────

final masterConfigRepositoryProvider = Provider<MasterConfigRepository>((ref) {
  return MasterConfigRepository(DioClient());
});

// Grades Provider
final gradesProvider = FutureProvider<List<MasterConfig>>((ref) async {
  final repo = ref.watch(masterConfigRepositoryProvider);
  return repo.fetchConfigs(type: 'grade');
});

// Routes Provider
final routesProvider = FutureProvider<List<MasterConfig>>((ref) async {
  final repo = ref.watch(masterConfigRepositoryProvider);
  return repo.fetchConfigs(type: 'route');
});

// Sections Provider (requires a grade ID)
final sectionsProvider = FutureProvider.family<List<MasterConfig>, String>((ref, gradeId) async {
  final repo = ref.watch(masterConfigRepositoryProvider);
  return repo.fetchConfigs(type: 'section', parentId: gradeId);
});

class SelectedGradeForSectionsNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  
  void updateState(String? val) {
    state = val;
  }
}

final selectedGradeForSectionsProvider = NotifierProvider<SelectedGradeForSectionsNotifier, String?>(
  SelectedGradeForSectionsNotifier.new,
);
