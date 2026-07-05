import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_fee_manager/core/api/dio_client.dart';

class AllocationPreview {
  const AllocationPreview({
    required this.matchedCount,
    required this.sampleStudentNames,
  });

  final int matchedCount;
  final List<String> sampleStudentNames;

  factory AllocationPreview.fromJson(Map<String, dynamic> json) {
    return AllocationPreview(
      matchedCount: (json['matchedCount'] as num?)?.toInt() ?? 0,
      sampleStudentNames: (json['sampleStudentNames'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

class AllocationResult {
  const AllocationResult({
    required this.matchedCount,
    required this.modifiedCount,
  });

  final int matchedCount;
  final int modifiedCount;

  factory AllocationResult.fromJson(Map<String, dynamic> json) {
    return AllocationResult(
      matchedCount: (json['matchedCount'] as num?)?.toInt() ?? 0,
      modifiedCount: (json['modifiedCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class AllocationLogEntry {
  const AllocationLogEntry({
    required this.logId,
    required this.timestamp,
    required this.feeCategory,
    required this.targetScope,
    required this.amount,
    required this.description,
  });

  final String logId;
  final DateTime timestamp;
  final String feeCategory;
  final Map<String, dynamic> targetScope;
  final num amount;
  final String description;

  factory AllocationLogEntry.fromJson(Map<String, dynamic> json) {
    return AllocationLogEntry(
      logId: (json['log_id'] as String?) ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      feeCategory: (json['fee_category'] as String?) ?? '',
      targetScope: (json['target_scope'] as Map<String, dynamic>?) ?? {},
      amount: (json['amount'] as num?) ?? 0,
      description: (json['description'] as String?) ?? '',
    );
  }
}

class PaginatedAllocationLogs {
  const PaginatedAllocationLogs({
    required this.logs,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  final List<AllocationLogEntry> logs;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  factory PaginatedAllocationLogs.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
    return PaginatedAllocationLogs(
      logs: ((data['logs'] as List<dynamic>?) ?? [])
          .map((e) => AllocationLogEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (pagination['total'] as int?) ?? 0,
      page: (pagination['page'] as int?) ?? 1,
      limit: (pagination['limit'] as int?) ?? 20,
      totalPages: (pagination['totalPages'] as int?) ?? 1,
    );
  }
}

class AllocationRepository {
  AllocationRepository(this._dioClient);
  final DioClient _dioClient;

  Future<AllocationPreview> previewAllocation({
    required String feeCategory,
    required Map<String, dynamic> target,
    required int amount,
    required String description,
  }) async {
    try {
      final resp = await _dioClient.dio.post(
        '/allocations/preview',
        data: {
          'fee_category': feeCategory,
          'target': target,
          'amount': amount,
          'description': description,
        },
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        return AllocationPreview.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw Exception(body['error'] ?? 'Preview failed.');
    } on DioException catch (e) {
      throw Exception(_parseError(e));
    }
  }

  Future<AllocationResult> executeAllocation({
    required String feeCategory,
    required Map<String, dynamic> target,
    required int amount,
    required String description,
  }) async {
    try {
      final resp = await _dioClient.dio.post(
        '/allocations',
        data: {
          'fee_category': feeCategory,
          'target': target,
          'amount': amount,
          'description': description,
        },
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        return AllocationResult.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw Exception(body['error'] ?? 'Allocation failed.');
    } on DioException catch (e) {
      throw Exception(_parseError(e));
    }
  }

  Future<PaginatedAllocationLogs> getLogs({int page = 1, int limit = 20}) async {
    try {
      final resp = await _dioClient.dio.get(
        '/allocations/log',
        queryParameters: {'page': page, 'limit': limit},
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        return PaginatedAllocationLogs.fromJson(body);
      }
      throw Exception(body['error'] ?? 'Failed to load logs.');
    } on DioException catch (e) {
      throw Exception(_parseError(e));
    }
  }

  Future<Uint8List> downloadExport() async {
    try {
      final resp = await _dioClient.dio.get<List<int>>(
        '/allocations/log/export',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(resp.data!);
    } on DioException catch (e) {
      throw Exception(_parseError(e));
    }
  }

  String _parseError(DioException e) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic> && data['error'] != null) {
        return data['error'] as String;
      }
    }
    return e.message ?? 'Network error. Please try again.';
  }
}

final allocationRepositoryProvider = Provider<AllocationRepository>((ref) {
  return AllocationRepository(DioClient());
});

// A provider for logs
final allocationLogProvider = FutureProvider.autoDispose<PaginatedAllocationLogs>((ref) async {
  final repo = ref.watch(allocationRepositoryProvider);
  return await repo.getLogs();
});
