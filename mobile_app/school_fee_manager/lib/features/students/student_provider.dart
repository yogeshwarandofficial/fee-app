import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_fee_manager/core/api/dio_client.dart';
import 'package:school_fee_manager/core/models/student.dart';
import 'package:school_fee_manager/features/students/student_repository.dart';

// ── Repository provider ─────────────────────────────────────────────────────
final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository(DioClient());
});

// ── Filter state ─────────────────────────────────────────────────────────────
class StudentFilterState {
  const StudentFilterState({
    this.gradeId,
    this.sectionId,
    this.status,
    this.search = '',
  });

  final String? gradeId;
  final String? sectionId;
  final String? status;
  final String  search;

  StudentFilterState copyWith({
    Object? gradeId   = _sentinel,
    Object? sectionId = _sentinel,
    Object? status    = _sentinel,
    String? search,
  }) {
    return StudentFilterState(
      gradeId:   gradeId   == _sentinel ? this.gradeId   : gradeId   as String?,
      sectionId: sectionId == _sentinel ? this.sectionId : sectionId as String?,
      status:    status    == _sentinel ? this.status    : status    as String?,
      search:    search    ?? this.search,
    );
  }
}

const _sentinel = Object();

class StudentFilterNotifier extends Notifier<StudentFilterState> {
  @override
  StudentFilterState build() => const StudentFilterState();

  void setGrade(String? id) {
    state = state.copyWith(gradeId: id, sectionId: null);
  }

  void setSection(String? id) {
    state = state.copyWith(sectionId: id);
  }

  void setStatus(String? s) {
    state = state.copyWith(status: s);
  }

  void setSearch(String s) {
    state = state.copyWith(search: s);
  }

  void reset() {
    state = const StudentFilterState();
  }
}

final studentFilterProvider =
    NotifierProvider<StudentFilterNotifier, StudentFilterState>(
  StudentFilterNotifier.new,
);

// ── Selection state ─────────────────────────────────────────────────────────
class StudentSelectionNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggle(String id) {
    final s = Set<String>.from(state);
    if (s.contains(id)) {
      s.remove(id);
    } else {
      s.add(id);
    }
    state = s;
  }

  void selectAll(List<String> ids) {
    state = Set<String>.from(ids);
  }

  void clearAll() {
    state = {};
  }
}

final studentSelectionProvider =
    NotifierProvider<StudentSelectionNotifier, Set<String>>(
  StudentSelectionNotifier.new,
);

// ── Paginated student list state ─────────────────────────────────────────────
class StudentListState {
  const StudentListState({
    this.students    = const [],
    this.isLoading   = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.totalPages  = 1,
    this.total       = 0,
  });

  final List<Student> students;
  final bool          isLoading;
  final bool          isLoadingMore;
  final String?       error;
  final int           currentPage;
  final int           totalPages;
  final int           total;

  bool get hasMore => currentPage < totalPages;

  StudentListState copyWith({
    List<Student>? students,
    bool?          isLoading,
    bool?          isLoadingMore,
    Object?        error = _sentinel,
    int?           currentPage,
    int?           totalPages,
    int?           total,
  }) {
    return StudentListState(
      students:      students      ?? this.students,
      isLoading:     isLoading     ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error:         error == _sentinel ? this.error : error as String?,
      currentPage:   currentPage   ?? this.currentPage,
      totalPages:    totalPages    ?? this.totalPages,
      total:         total         ?? this.total,
    );
  }
}

class StudentListNotifier extends Notifier<StudentListState> {
  @override
  StudentListState build() {
    // Watch filters so list auto-refreshes when filters change
    ref.watch(studentFilterProvider);
    _load();
    return const StudentListState(isLoading: true);
  }

  Future<void> _load() async {
    final filter = ref.read(studentFilterProvider);
    final repo   = ref.read(studentRepositoryProvider);
    try {
      final result = await repo.fetchStudents(
        gradeId:   filter.gradeId,
        sectionId: filter.sectionId,
        status:    filter.status,
        search:    filter.search.isEmpty ? null : filter.search,
        page:      1,
      );
      state = StudentListState(
        students:    result.students,
        currentPage: result.page,
        totalPages:  result.totalPages,
        total:       result.total,
      );
    } catch (e) {
      state = StudentListState(error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    await _load();
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    final filter = ref.read(studentFilterProvider);
    final repo   = ref.read(studentRepositoryProvider);
    try {
      final result = await repo.fetchStudents(
        gradeId:   filter.gradeId,
        sectionId: filter.sectionId,
        status:    filter.status,
        search:    filter.search.isEmpty ? null : filter.search,
        page:      state.currentPage + 1,
      );
      state = state.copyWith(
        students:      [...state.students, ...result.students],
        currentPage:   result.page,
        totalPages:    result.totalPages,
        total:         result.total,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

final studentListProvider =
    NotifierProvider<StudentListNotifier, StudentListState>(
  StudentListNotifier.new,
);

// ── Single student provider ──────────────────────────────────────────────────
final studentDetailProvider = FutureProvider.family<Student, String>((ref, id) async {
  final repo = ref.watch(studentRepositoryProvider);
  return repo.fetchStudent(id);
});

// ── Transaction history provider ─────────────────────────────────────────────
final studentHistoryProvider =
    FutureProvider.family<List<Transaction>, String>((ref, id) async {
  final repo = ref.watch(studentRepositoryProvider);
  return repo.fetchHistory(id);
});
