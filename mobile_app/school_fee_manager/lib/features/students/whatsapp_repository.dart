import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_fee_manager/core/api/dio_client.dart';

/// Result returned by [WhatsAppRepository.sendIndividual].
class IndividualReminderResult {
  const IndividualReminderResult({required this.url});
  final String url;
}

/// Summary returned by [WhatsAppRepository.sendBulk].
class BulkReminderResult {
  const BulkReminderResult({
    required this.totalSelected,
    required this.eligible,
    required this.sent,
    required this.skipped,
  });

  final int totalSelected;
  final int eligible;
  final int sent;
  final int skipped;
}

/// Repository for all WhatsApp reminder API calls.
class WhatsAppRepository {
  WhatsAppRepository(this._dioClient);
  final DioClient _dioClient;

  // ── POST /api/whatsapp/send-individual/:id ────────────────────────────────

  /// Asks the server to build and return a wa.me deep link for [studentId].
  ///
  /// Throws an [Exception] with the server's error message if:
  ///   • The student has no outstanding balance.
  ///   • The phone number is missing or invalid.
  Future<IndividualReminderResult> sendIndividual(String studentId) async {
    try {
      final resp = await _dioClient.dio.post(
        '/whatsapp/send-individual/$studentId',
      );
      final data = resp.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final url = data['data']['url'] as String;
        return IndividualReminderResult(url: url);
      }
      throw Exception(data['error'] ?? 'Failed to generate WhatsApp link.');
    } on DioException catch (e) {
      throw Exception(_parseError(e));
    }
  }

  // ── POST /api/whatsapp/send-bulk ──────────────────────────────────────────

  /// Dispatches bulk reminders for [studentIds] through the server provider.
  ///
  /// Never throws on partial failures — the server handles per-student errors.
  Future<BulkReminderResult> sendBulk(List<String> studentIds) async {
    try {
      final resp = await _dioClient.dio.post(
        '/whatsapp/send-bulk',
        data: {'student_ids': studentIds},
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        final d = body['data'] as Map<String, dynamic>;
        return BulkReminderResult(
          totalSelected: (d['totalSelected'] as num?)?.toInt() ?? 0,
          eligible:      (d['eligible']      as num?)?.toInt() ?? 0,
          sent:          (d['sent']          as num?)?.toInt() ?? 0,
          skipped:       (d['skipped']       as num?)?.toInt() ?? 0,
        );
      }
      throw Exception(body['error'] ?? 'Bulk send failed.');
    } on DioException catch (e) {
      throw Exception(_parseError(e));
    }
  }

  // ── Error classifier ─────────────────────────────────────────────────────

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

// ── Provider ─────────────────────────────────────────────────────────────────

final whatsAppRepositoryProvider = Provider<WhatsAppRepository>((ref) {
  return WhatsAppRepository(DioClient());
});
