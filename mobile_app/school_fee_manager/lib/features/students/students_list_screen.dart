import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_fee_manager/core/models/master_config.dart';
import 'package:school_fee_manager/core/models/student.dart';
import 'package:school_fee_manager/core/services/export_service.dart';
import 'package:school_fee_manager/core/theme/app_theme.dart';
import 'package:school_fee_manager/core/utils/currency_formatter.dart';
import 'package:school_fee_manager/features/master_config/master_config_provider.dart';
import 'package:school_fee_manager/features/students/add_student_sheet.dart';
import 'package:school_fee_manager/features/students/edit_student_sheet.dart';
import 'package:school_fee_manager/features/students/student_dialogs.dart';
import 'package:school_fee_manager/features/students/student_provider.dart';
import 'package:school_fee_manager/features/students/whatsapp_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentsListScreen extends ConsumerStatefulWidget {
  const StudentsListScreen({super.key});

  @override
  ConsumerState<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends ConsumerState<StudentsListScreen> {
  final _searchCtrl   = TextEditingController();
  final _scrollCtrl   = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(studentListProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(studentFilterProvider.notifier).setSearch(q);
    });
  }

  // ── WhatsApp bulk send ───────────────────────────────────────────────────

  bool _bulkSending = false;

  Future<void> _sendBulkWhatsApp() async {
    final selection = ref.read(studentSelectionProvider);
    if (selection.isEmpty) return;

    setState(() => _bulkSending = true);

    try {
      final repo   = ref.read(whatsAppRepositoryProvider);
      final result = await repo.sendBulk(selection.toList());

      if (!mounted) return;

      // Show summary dialog
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Color(0xFF25D366), size: 24),
              SizedBox(width: 10),
              Text('WhatsApp Reminder Summary'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SummaryRow(label: 'Selected', value: result.totalSelected),
              _SummaryRow(label: 'Eligible', value: result.eligible),
              _SummaryRow(
                label: 'Sent',
                value: result.sent,
                valueColor: const Color(0xFF25D366),
              ),
              _SummaryRow(
                label: 'Skipped',
                value: result.skipped,
                valueColor: result.skipped > 0 ? AppTheme.warningColor : null,
              ),
              if (result.skipped > 0) ...[
                const SizedBox(height: 12),
                const Text(
                  'Skipped students either have no outstanding balance or a missing phone number.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );

      // Clear selection and return to normal mode
      if (mounted) {
        ref.read(studentSelectionProvider.notifier).clearAll();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bulk send failed: ${e.toString().replaceAll("Exception: ", "")}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _bulkSending = false);
    }
  }

  Future<void> _exportSelected() async {
    final selection = ref.read(studentSelectionProvider);
    final filter    = ref.read(studentFilterProvider);
    final repo      = ref.read(studentRepositoryProvider);

    if (selection.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Row(children: [
        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
        SizedBox(width: 12),
        Text('Preparing export…'),
      ])),
    );

    try {
      final bytes = await repo.downloadExport(
        gradeId:   filter.gradeId,
        sectionId: filter.sectionId,
        status:    filter.status,
        search:    filter.search.isEmpty ? null : filter.search,
        ids:       selection.toList(),
      );

      final timestamp = DateTime.now();
      final filename  = 'Students_Export_'
          '${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}'
          '_${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}.xlsx';

      final tempDir  = await ExportService.getTemporaryDir();
      final filePath = await ExportService.saveFile('$tempDir/$filename', bytes);
      await ExportService.shareFile(filePath);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export ready!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _refreshList() {
    ref.read(studentListProvider.notifier).refresh();
  }

  void _openMenu(BuildContext context, Student s) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _StudentMenu(
        student:     s,
        onRefresh:   _refreshList,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listState  = ref.watch(studentListProvider);
    final filter     = ref.watch(studentFilterProvider);
    final selection  = ref.watch(studentSelectionProvider);
    final gradesAsync = ref.watch(gradesProvider);

    final allIds = listState.students.map((s) => s.id).toList();
    final allSelected = allIds.isNotEmpty && selection.containsAll(allIds);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Students'),
            if (listState.total > 0)
              Text('${listState.total} total',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshList,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => AddStudentSheet(onSuccess: _refreshList),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged:  _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by name or student ID…',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(studentFilterProvider.notifier).setSearch('');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),

          // ── Filter row ──────────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                // Grade filter
                gradesAsync.when(
                  data: (grades) => _FilterChip(
                    label: filter.gradeId != null
                        ? grades.firstWhere((g) => g.id == filter.gradeId,
                                orElse: () => MasterConfig(id: '', type: 'grade', name: 'Grade'))
                            .name
                        : 'All Grades',
                    isActive: filter.gradeId != null,
                    onTap: () => _showGradeFilter(context, grades),
                  ),
                  loading: () => const _FilterChip(label: 'Loading…', isActive: false),
                  error:   (_, _) => const SizedBox(),
                ),
                const SizedBox(width: 8),
                // Section filter — only available when grade is selected
                if (filter.gradeId != null)
                  Consumer(builder: (context, ref, _) {
                    final secsAsync = ref.watch(sectionsProvider(filter.gradeId!));
                    return secsAsync.when(
                      data: (secs) => Row(children: [
                        _FilterChip(
                          label: filter.sectionId != null
                              ? secs.firstWhere((s) => s.id == filter.sectionId,
                                      orElse: () =>
                                          MasterConfig(id: '', type: 'section', name: 'Section'))
                                  .name
                              : 'All Sections',
                          isActive: filter.sectionId != null,
                          onTap: () => _showSectionFilter(context, secs),
                        ),
                        const SizedBox(width: 8),
                      ]),
                      loading: () => const SizedBox(),
                      error:   (_, _) => const SizedBox(),
                    );
                  }),
                // Status filter
                _FilterChip(
                  label: filter.status == 'cleared'
                      ? 'Cleared'
                      : filter.status == 'pending'
                          ? 'Pending'
                          : 'All Status',
                  isActive: filter.status != null,
                  onTap: () => _showStatusFilter(context),
                ),
                // Clear all
                if (filter.gradeId != null || filter.sectionId != null || filter.status != null) ...[
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('Clear'),
                    avatar: const Icon(Icons.close, size: 14),
                    onPressed: () => ref.read(studentFilterProvider.notifier).reset(),
                  ),
                ],
              ],
            ),
          ),

          // ── Bulk actions bar ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              border: Border(bottom: BorderSide(color: AppTheme.dividerColor)),
            ),
            child: Row(
              children: [
                // Select All checkbox
                InkWell(
                  onTap: () {
                    if (allSelected) {
                      ref.read(studentSelectionProvider.notifier).clearAll();
                    } else {
                      ref.read(studentSelectionProvider.notifier).selectAll(allIds);
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: allSelected,
                        tristate: !allSelected && selection.isNotEmpty,
                        onChanged: (_) {
                          if (allSelected) {
                            ref.read(studentSelectionProvider.notifier).clearAll();
                          } else {
                            ref.read(studentSelectionProvider.notifier).selectAll(allIds);
                          }
                        },
                      ),
                      Text(
                        allSelected ? 'Deselect All' : 'Select All',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true, // Keep items aligned to the right when they fit
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selection.isNotEmpty) ...[
                          Text(
                            '${selection.length} selected',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppTheme.accentColor),
                          ),
                          const SizedBox(width: 8),
                          // Export Excel
                          OutlinedButton.icon(
                            onPressed: _exportSelected,
                            icon: const Icon(Icons.download_outlined, size: 16),
                            label: const Text('Excel'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Bulk WhatsApp Reminder
                          _bulkSending
                              ? const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF25D366),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Sending reminders…',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                )
                              : OutlinedButton.icon(
                                  onPressed: _sendBulkWhatsApp,
                                  icon: const Icon(
                                    Icons.message_outlined,
                                    size: 16,
                                    color: Color(0xFF25D366),
                                  ),
                                  label: const Text('WhatsApp'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    textStyle: const TextStyle(fontSize: 12),
                                    side: const BorderSide(color: Color(0xFF25D366)),
                                    foregroundColor: const Color(0xFF25D366),
                                  ),
                                ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Student list ────────────────────────────────────────────────
          Expanded(
            child: listState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : listState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: AppTheme.errorColor),
                            const SizedBox(height: 12),
                            Text(listState.error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppTheme.errorColor)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _refreshList,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : listState.students.isEmpty
                        ? const _EmptyState()
                        : ListView.builder(
                            controller: _scrollCtrl,
                            itemCount:  listState.students.length + (listState.isLoadingMore ? 1 : 0),
                            itemBuilder: (context, i) {
                              if (i == listState.students.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              final s  = listState.students[i];
                              final selected = selection.contains(s.id);
                              return _StudentCard(
                                student:  s,
                                selected: selected,
                                onToggle: () =>
                                    ref.read(studentSelectionProvider.notifier).toggle(s.id),
                                onMenu: () => _openMenu(context, s),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  void _showGradeFilter(BuildContext context, List<MasterConfig> grades) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _FilterSheet(
        title: 'Filter by Grade',
        items: [
          const _FilterItem(id: null, name: 'All Grades'),
          ...grades.map((g) => _FilterItem(id: g.id, name: g.name)),
        ],
        selectedId: ref.read(studentFilterProvider).gradeId,
        onSelected: (id) {
          ref.read(studentFilterProvider.notifier).setGrade(id);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showSectionFilter(BuildContext context, List<MasterConfig> sections) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _FilterSheet(
        title: 'Filter by Section',
        items: [
          const _FilterItem(id: null, name: 'All Sections'),
          ...sections.map((s) => _FilterItem(id: s.id, name: s.name)),
        ],
        selectedId: ref.read(studentFilterProvider).sectionId,
        onSelected: (id) {
          ref.read(studentFilterProvider.notifier).setSection(id);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showStatusFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _FilterSheet(
        title: 'Filter by Status',
        items: const [
          _FilterItem(id: null,      name: 'All Status'),
          _FilterItem(id: 'cleared', name: 'Cleared'),
          _FilterItem(id: 'pending', name: 'Pending'),
        ],
        selectedId: ref.read(studentFilterProvider).status,
        onSelected: (id) {
          ref.read(studentFilterProvider.notifier).setStatus(id);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Student Card
// ─────────────────────────────────────────────────────────────────────────────
class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.student,
    required this.selected,
    required this.onToggle,
    required this.onMenu,
  });

  final Student      student;
  final bool         selected;
  final VoidCallback onToggle;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final s  = student;
    final fg = selected ? AppTheme.primaryColor : AppTheme.textPrimary;
    final totalDue = s.balances.tuition.due + s.balances.transport.due + s.balances.other.due;

    return Card(
      color: selected
          ? AppTheme.primaryColor.withAlpha(12)
          : AppTheme.surfaceColor,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppTheme.primaryColor.withAlpha(50) : AppTheme.dividerColor,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Header Row: Checkbox, Avatar, Info, Menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(value: selected, onChanged: (_) => onToggle()),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryColor.withAlpha(20),
                  backgroundImage: s.avatarUrl != null && s.avatarUrl!.isNotEmpty
                      ? NetworkImage(s.avatarUrl!)
                      : null,
                  child: s.avatarUrl == null || s.avatarUrl!.isEmpty
                      ? Text(
                          s.fullName.isNotEmpty ? s.fullName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              s.fullName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: fg,
                                    fontWeight: FontWeight.bold,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: s.isCleared
                                  ? AppTheme.successColor
                                  : AppTheme.warningColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${s.studentId}  •  ${s.gradeName} ${s.sectionName}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                // Total Due Badge
                if (totalDue > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Due: ${CurrencyFormatter.formatINR(totalDue)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warningColor,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: onMenu,
                  tooltip: 'Actions',
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Fee Breakdown Inner Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _FeeRow(
                    icon:  Icons.school_outlined,
                    label: 'Tuition',
                    paid:  s.balances.tuition.paid,
                    due:   s.balances.tuition.due,
                  ),
                  const SizedBox(height: 12),
                  _FeeRow(
                    icon:  Icons.directions_bus_outlined,
                    label: 'Transport',
                    paid:  s.balances.transport.paid,
                    due:   s.balances.transport.due,
                  ),
                  const SizedBox(height: 12),
                  _FeeRow(
                    icon:  Icons.receipt_outlined,
                    label: 'Other',
                    paid:  s.balances.other.paid,
                    due:   s.balances.other.due,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  const _FeeRow({
    required this.icon,
    required this.label,
    required this.paid,
    required this.due,
  });

  final IconData icon;
  final String   label;
  final num      paid;
  final num      due;

  @override
  Widget build(BuildContext context) {
    final total = paid + due;
    final progress = total > 0 ? (paid / total).clamp(0.0, 1.0) : 1.0;
    final hasDue = due > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const Spacer(),
            Text(
              'Paid: ${CurrencyFormatter.formatINR(paid)}',
              style: const TextStyle(fontSize: 11, color: AppTheme.successColor, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 12),
            Text(
              'Due: ${CurrencyFormatter.formatINR(due)}',
              style: TextStyle(
                fontSize: 11,
                color: hasDue ? AppTheme.warningColor : AppTheme.textSecondary,
                fontWeight: hasDue ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total == 0 ? 1.0 : progress,
            backgroundColor: hasDue ? AppTheme.warningColor.withAlpha(30) : AppTheme.successColor.withAlpha(30),
            valueColor: AlwaysStoppedAnimation<Color>(
              total == 0 ? AppTheme.dividerColor : AppTheme.successColor,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Student menu (three-dot)
// ─────────────────────────────────────────────────────────────────────────────
class _StudentMenu extends ConsumerWidget {
  const _StudentMenu({required this.student, required this.onRefresh});
  final Student      student;
  final VoidCallback onRefresh;

  void _open(BuildContext context, Widget sheet, {bool isDialog = false}) {
    Navigator.pop(context); // close menu first
    if (isDialog) {
      showDialog(context: context, builder: (_) => sheet);
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => sheet,
      );
    }
  }

  Future<void> _sendWhatsApp(BuildContext context, WidgetRef ref) async {
    Navigator.pop(context); // close menu sheet first

    final repo = ref.read(whatsAppRepositoryProvider);

    // Show a brief loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(children: [
          SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2, color: Colors.white,
            ),
          ),
          SizedBox(width: 12),
          Text('Generating WhatsApp link…'),
        ]),
        duration: Duration(seconds: 10),
      ),
    );

    try {
      final result = await repo.sendIndividual(student.id);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      final uri = Uri.parse(result.url);
      final canLaunch = await canLaunchUrl(uri);
      if (!context.mounted) return;
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp is not installed on this device.'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('View Student Profile'),
              onTap: () => _open(
                context,
                StudentProfileSheet(student: student),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.history_outlined),
              title: const Text('View Fee History'),
              onTap: () => _open(
                context,
                FeeHistorySheet(studentId: student.id, studentName: student.fullName),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Update Fees'),
              onTap: () => _open(
                context,
                UpdateFeesSheet(student: student, onSuccess: onRefresh),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_card_outlined),
              title: const Text('Add Other Fee'),
              onTap: () => _open(
                context,
                AddOtherFeeSheet(student: student, onSuccess: onRefresh),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Student'),
              onTap: () => _open(
                context,
                EditStudentSheet(student: student, onSuccess: onRefresh),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.send_outlined, color: Color(0xFF25D366)),
              title: const Text('Send WhatsApp Reminder'),
              subtitle: const Text('Opens WhatsApp with a pre-filled message',
                  style: TextStyle(fontSize: 11)),
              onTap: () => _sendWhatsApp(context, ref),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
              title: const Text('Delete Student',
                  style: TextStyle(color: AppTheme.errorColor)),
              onTap: () => _open(
                context,
                DeleteStudentDialog(student: student, onSuccess: onRefresh),
                isDialog: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter chips + sheets
// ─────────────────────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isActive,
    this.onTap,
  });

  final String        label;
  final bool          isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isActive,
      onSelected: (_) => onTap?.call(),
      selectedColor: AppTheme.primaryColor.withAlpha(20),
      checkmarkColor: AppTheme.primaryColor,
    );
  }
}

class _FilterItem {
  const _FilterItem({required this.id, required this.name});
  final String? id;
  final String  name;
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({
    required this.title,
    required this.items,
    required this.selectedId,
    required this.onSelected,
  });

  final String              title;
  final List<_FilterItem>   items;
  final String?             selectedId;
  final void Function(String?) onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(title, style: Theme.of(context).textTheme.titleMedium),
            ),
            const Divider(height: 1),
            ...items.map((item) => ListTile(
                  title: Text(item.name),
                  trailing: item.id == selectedId
                      ? const Icon(Icons.check, color: AppTheme.primaryColor)
                      : null,
                  onTap: () => onSelected(item.id),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 64, color: AppTheme.dividerColor),
          SizedBox(height: 16),
          Text('No students found',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
          SizedBox(height: 8),
          Text('Adjust your filters or add a new student.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Summary row — used in the bulk WhatsApp result dialog
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final int    value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const Spacer(),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
