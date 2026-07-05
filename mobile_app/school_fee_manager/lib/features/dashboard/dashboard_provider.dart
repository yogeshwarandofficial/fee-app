import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:school_fee_manager/core/api/dio_client.dart';

// ── Models ───────────────────────────────────────────────────────────────────

class DashboardMetrics {
  final int studentStrength;
  final double totalPaid;
  final double pendingDue;
  final Map<String, int> paidVsUnpaidPercentage;
  final List<MonthlyTrend> monthlyCollectionTrend;

  DashboardMetrics({
    required this.studentStrength,
    required this.totalPaid,
    required this.pendingDue,
    required this.paidVsUnpaidPercentage,
    required this.monthlyCollectionTrend,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      studentStrength: json['studentStrength'] ?? 0,
      totalPaid: (json['totalPaid'] ?? 0).toDouble(),
      pendingDue: (json['pendingDue'] ?? 0).toDouble(),
      paidVsUnpaidPercentage: {
        'paid': json['paidVsUnpaidPercentage']?['paid'] ?? 0,
        'unpaid': json['paidVsUnpaidPercentage']?['unpaid'] ?? 0,
      },
      monthlyCollectionTrend: (json['monthlyCollectionTrend'] as List?)
              ?.map((e) => MonthlyTrend.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class MonthlyTrend {
  final String month;
  final double amount;

  MonthlyTrend({required this.month, required this.amount});

  factory MonthlyTrend.fromJson(Map<String, dynamic> json) {
    return MonthlyTrend(
      month: json['month'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }
}

class DashboardGradeFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void updateState(String? val) {
    state = val;
  }
}

final dashboardGradeFilterProvider = NotifierProvider<DashboardGradeFilterNotifier, String?>(
  DashboardGradeFilterNotifier.new,
);

// ── Provider for Dashboard Data ──────────────────────────────────────────────
final dashboardProvider = FutureProvider<DashboardMetrics>((ref) async {
  final apiClient = DioClient();
  final gradeId = ref.watch(dashboardGradeFilterProvider);

  final queryParams = <String, dynamic>{};
  if (gradeId != null && gradeId.isNotEmpty) {
    queryParams['grade_id'] = gradeId;
  }

  final response = await apiClient.dio.get(
    '/dashboard',
    queryParameters: queryParams,
  );

  return DashboardMetrics.fromJson(response.data['data']);
});

// ── Provider for Exporting ───────────────────────────────────────────────────
final dashboardExportProvider = Provider((ref) => DashboardExportService(ref));

class DashboardExportService {
  final Ref _ref;

  DashboardExportService(this._ref);

  Future<void> downloadExcel() async {
    final apiClient = DioClient();
    final gradeId = _ref.read(dashboardGradeFilterProvider);

    final queryParams = <String, dynamic>{};
    if (gradeId != null && gradeId.isNotEmpty) {
      queryParams['grade_id'] = gradeId;
    }

    // Call API using Dio directly for stream download to handle binary
    final response = await apiClient.dio.get(
      '/dashboard/export',
      queryParameters: queryParams,
      options: Options(responseType: ResponseType.bytes),
    );

    // Get temp dir
    final dir = await getTemporaryDirectory();
    
    // Extract filename from headers if possible, else generate one
    String filename = 'Dashboard_Export.xlsx';
    final contentDisposition = response.headers.value('content-disposition');
    if (contentDisposition != null) {
      final match = RegExp(r'filename="([^"]+)"').firstMatch(contentDisposition);
      if (match != null) {
        filename = match.group(1)!;
      }
    }

    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(response.data);

    // Open file
    await OpenFilex.open(file.path);
  }
}
