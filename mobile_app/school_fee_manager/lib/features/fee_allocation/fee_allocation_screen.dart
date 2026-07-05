import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_fee_manager/core/services/export_service.dart';
import 'package:school_fee_manager/core/theme/app_theme.dart';
import 'package:school_fee_manager/features/fee_allocation/allocation_repository.dart';
import 'package:school_fee_manager/features/master_config/master_config_provider.dart';
import 'package:school_fee_manager/features/students/student_provider.dart';
import 'package:intl/intl.dart';

class FeeAllocationScreen extends ConsumerStatefulWidget {
  const FeeAllocationScreen({super.key});

  @override
  ConsumerState<FeeAllocationScreen> createState() => _FeeAllocationScreenState();
}

class _FeeAllocationScreenState extends ConsumerState<FeeAllocationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showLogs(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AllocationLogSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Fee Allocation'),
        backgroundColor: const Color(0xFF1E1E2C), // Deep indigo
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'View Allocation Log',
            icon: const Icon(Icons.history_edu),
            onPressed: () => _showLogs(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Tuition'),
            Tab(text: 'Transport'),
            Tab(text: 'Other'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _TuitionAllocationForm(),
          _TransportAllocationForm(),
          _OtherAllocationForm(),
        ],
      ),
    );
  }
}

// ── Shared Card Layout ────────────────────────────────────────────────────────
class _AllocationFormCard extends StatelessWidget {
  const _AllocationFormCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

// ── Common Preview & Execute Logic ────────────────────────────────────────────

Future<void> _handleAllocationSubmit(
  BuildContext context,
  WidgetRef ref,
  String feeCategory,
  Map<String, dynamic> target,
  int amount,
  String description,
) async {
  final repo = ref.read(allocationRepositoryProvider);

  // 1. Show loading for preview
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const Center(child: CircularProgressIndicator()),
  );

  AllocationPreview preview;
  try {
    preview = await repo.previewAllocation(
      feeCategory: feeCategory,
      target: target,
      amount: amount,
      description: description,
    );
    if (!context.mounted) return;
    Navigator.of(context).pop(); // dismiss loading
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context).pop(); // dismiss loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorColor),
    );
    return;
  }

  // 2. Show Modal Confirmation
  if (!context.mounted) return;
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ConfirmationModal(
      amount: amount,
      matchedCount: preview.matchedCount,
      sampleNames: preview.sampleStudentNames,
    ),
  );

  if (confirmed != true || !context.mounted) return;

  // 3. Execute Allocation
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final result = await repo.executeAllocation(
      feeCategory: feeCategory,
      target: target,
      amount: amount,
      description: description,
    );
    if (!context.mounted) return;
    Navigator.of(context).pop(); // dismiss loading

    ref.read(studentListProvider.notifier).refresh(); // Refresh student list
    ref.invalidate(allocationLogProvider); // Refresh log

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Success! ${result.modifiedCount} student(s) updated.'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context).pop(); // dismiss loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorColor),
    );
  }
}

class _ConfirmationModal extends StatelessWidget {
  const _ConfirmationModal({
    required this.amount,
    required this.matchedCount,
    required this.sampleNames,
  });

  final int amount;
  final int matchedCount;
  final List<String> sampleNames;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 56, color: AppTheme.warningColor),
            const SizedBox(height: 16),
            const Text(
              'Confirm Allocation',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary, height: 1.5),
                children: [
                  const TextSpan(text: 'You are about to assign '),
                  TextSpan(
                    text: fmt.format(amount),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                  const TextSpan(text: ' to '),
                  TextSpan(
                    text: '$matchedCount student(s)',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
            if (sampleNames.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('Sample matches:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...sampleNames.map((n) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $n', style: const TextStyle(color: AppTheme.textSecondary)),
                  )),
            ],
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text('Yes, Assign', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// ── Tuition Form ─────────────────────────────────────────────────────────────
class _TuitionAllocationForm extends ConsumerStatefulWidget {
  const _TuitionAllocationForm();

  @override
  ConsumerState<_TuitionAllocationForm> createState() => _TuitionAllocationFormState();
}

class _TuitionAllocationFormState extends ConsumerState<_TuitionAllocationForm> {
  String? _selectedGradeId;
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool get _isValid =>
      _selectedGradeId != null &&
      _amountCtrl.text.trim().isNotEmpty &&
      int.tryParse(_amountCtrl.text.trim()) != null &&
      int.parse(_amountCtrl.text.trim()) > 0 &&
      _descCtrl.text.trim().isNotEmpty;

  void _submit() {
    if (!_isValid) return;
    _handleAllocationSubmit(
      context,
      ref,
      'tuition',
      {'grade_id': _selectedGradeId},
      int.parse(_amountCtrl.text.trim()),
      _descCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradesAsync = ref.watch(gradesProvider);

    return _AllocationFormCard(
      children: [
        const Text('Target Grade', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        gradesAsync.when(
          data: (grades) => DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            hint: const Text('Select a grade (or All)'),
            value: _selectedGradeId,
            items: [
              const DropdownMenuItem(value: 'all', child: Text('All Grades')),
              ...grades.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))),
            ],
            onChanged: (val) => setState(() => _selectedGradeId = val),
          ),
          loading: () => const CircularProgressIndicator(),
          error: (err, _) => Text(err.toString(), style: const TextStyle(color: Colors.red)),
        ),
        const SizedBox(height: 24),
        const Text('Amount (₹)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixText: '₹ ',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 24),
        const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descCtrl,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'e.g. Term 1 Tuition Fee',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _isValid ? _submit : null,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Assign Tuition Fee'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}

// ── Transport Form ────────────────────────────────────────────────────────────
class _TransportAllocationForm extends ConsumerStatefulWidget {
  const _TransportAllocationForm();

  @override
  ConsumerState<_TransportAllocationForm> createState() => _TransportAllocationFormState();
}

class _TransportAllocationFormState extends ConsumerState<_TransportAllocationForm> {
  String? _selectedRouteId;
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool get _isValid =>
      _selectedRouteId != null &&
      _amountCtrl.text.trim().isNotEmpty &&
      int.tryParse(_amountCtrl.text.trim()) != null &&
      int.parse(_amountCtrl.text.trim()) > 0 &&
      _descCtrl.text.trim().isNotEmpty;

  void _submit() {
    if (!_isValid) return;
    _handleAllocationSubmit(
      context,
      ref,
      'transport',
      {'route_id': _selectedRouteId},
      int.parse(_amountCtrl.text.trim()),
      _descCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(routesProvider);

    return _AllocationFormCard(
      children: [
        const Text('Target Route', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        routesAsync.when(
          data: (routes) => DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            hint: const Text('Select a specific route'),
            value: _selectedRouteId,
            items: routes.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))).toList(),
            onChanged: (val) => setState(() => _selectedRouteId = val),
          ),
          loading: () => const CircularProgressIndicator(),
          error: (err, _) => Text(err.toString(), style: const TextStyle(color: Colors.red)),
        ),
        const SizedBox(height: 24),
        const Text('Amount (₹)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixText: '₹ ',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 24),
        const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descCtrl,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'e.g. Q1 Transport Fee',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _isValid ? _submit : null,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Assign Transport Fee'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}

// ── Other Form ────────────────────────────────────────────────────────────────
class _OtherAllocationForm extends ConsumerStatefulWidget {
  const _OtherAllocationForm();

  @override
  ConsumerState<_OtherAllocationForm> createState() => _OtherAllocationFormState();
}

class _OtherAllocationFormState extends ConsumerState<_OtherAllocationForm> {
  String? _selectedGradeId;
  String? _selectedSectionId;
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool get _isValid =>
      _selectedGradeId != null &&
      _amountCtrl.text.trim().isNotEmpty &&
      int.tryParse(_amountCtrl.text.trim()) != null &&
      int.parse(_amountCtrl.text.trim()) > 0 &&
      _descCtrl.text.trim().isNotEmpty;

  void _submit() {
    if (!_isValid) return;
    _handleAllocationSubmit(
      context,
      ref,
      'other',
      {
        'grade_id': _selectedGradeId,
        'section_id': _selectedSectionId ?? 'all',
      },
      int.parse(_amountCtrl.text.trim()),
      _descCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradesAsync = ref.watch(gradesProvider);
    final sectionsAsync = _selectedGradeId != null ? ref.watch(sectionsProvider(_selectedGradeId!)) : null;

    return _AllocationFormCard(
      children: [
        const Text('Target Grade', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        gradesAsync.when(
          data: (grades) => DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            hint: const Text('Select a specific grade'),
            value: _selectedGradeId,
            items: grades.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))).toList(),
            onChanged: (val) => setState(() {
              _selectedGradeId = val;
              _selectedSectionId = null;
            }),
          ),
          loading: () => const CircularProgressIndicator(),
          error: (err, _) => Text(err.toString(), style: const TextStyle(color: Colors.red)),
        ),
        const SizedBox(height: 16),
        const Text('Target Section (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (sectionsAsync != null)
          sectionsAsync.when(
            data: (sections) => DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              hint: const Text('All Sections'),
              value: _selectedSectionId,
              items: [
                const DropdownMenuItem(value: null, child: Text('All Sections')),
                ...sections.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
              ],
              onChanged: (val) => setState(() => _selectedSectionId = val),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (err, _) => Text(err.toString(), style: const TextStyle(color: Colors.red)),
          )
        else
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            hint: const Text('Select a grade first'),
            items: const [],
            onChanged: null,
          ),
        const SizedBox(height: 24),
        const Text('Amount (₹)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixText: '₹ ',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 24),
        const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descCtrl,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'e.g. Exam Fee',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _isValid ? _submit : null,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Assign Other Fee'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}

// ── Log Sheet ─────────────────────────────────────────────────────────────────
class _AllocationLogSheet extends ConsumerWidget {
  const _AllocationLogSheet();

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    try {
      final bytes = await ref.read(allocationRepositoryProvider).downloadExport();
      final dir = await ExportService.getTemporaryDir();
      final path = '$dir/Allocation_Log_Export.csv';
      await ExportService.saveFile(path, bytes);
      await ExportService.shareFile(path);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logAsync = ref.watch(allocationLogProvider);
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Allocation Log', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                OutlinedButton.icon(
                  onPressed: () => _export(context, ref),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Export CSV'),
                )
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: logAsync.when(
              data: (data) {
                if (data.logs.isEmpty) {
                  return const Center(child: Text('No allocations recorded yet.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: data.logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final log = data.logs[i];
                    IconData icon;
                    Color color;
                    switch (log.feeCategory) {
                      case 'tuition':
                        icon = Icons.school;
                        color = Colors.blue;
                        break;
                      case 'transport':
                        icon = Icons.directions_bus;
                        color = Colors.orange;
                        break;
                      default:
                        icon = Icons.category;
                        color = Colors.green;
                    }

                    return Card(
                      elevation: 0,
                      color: const Color(0xFFF8FAFC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(icon, color: color, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      log.feeCategory.toUpperCase(),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: color,
                                          letterSpacing: 1),
                                    ),
                                  ],
                                ),
                                Text(
                                  dateFmt.format(log.timestamp.toLocal()),
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              log.description,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Amount: ${fmt.format(log.amount)}'),
                                Text(
                                  log.logId,
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text(err.toString(), style: const TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }
}
