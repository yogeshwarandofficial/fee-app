import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_fee_manager/core/models/student.dart';
import 'package:school_fee_manager/core/theme/app_theme.dart';
import 'package:school_fee_manager/core/utils/currency_formatter.dart';
import 'package:school_fee_manager/core/utils/date_formatter.dart';
import 'package:school_fee_manager/features/students/student_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// View Profile Bottom Sheet
// Always fetches fresh data from the server so fee balances (e.g. Other) are
// up-to-date even after a bulk allocation that wasn't yet reflected in the list.
// ─────────────────────────────────────────────────────────────────────────────
class StudentProfileSheet extends ConsumerStatefulWidget {
  const StudentProfileSheet({
    super.key,
    required this.studentId,
    required this.studentName, // used for avatar letter while loading
  });

  final String studentId;
  final String studentName;

  @override
  ConsumerState<StudentProfileSheet> createState() => _StudentProfileSheetState();
}

class _StudentProfileSheetState extends ConsumerState<StudentProfileSheet> {
  @override
  void initState() {
    super.initState();
    // Invalidate before the first build so fresh data is always fetched.
    // Calling ref.invalidate() inside build() causes "setState during build".
    ref.invalidate(studentDetailProvider(widget.studentId));
  }

  @override
  Widget build(BuildContext context) {
    final studentAsync = ref.watch(studentDetailProvider(widget.studentId));

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: studentAsync.when(
            loading: () => ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.primaryColor.withAlpha(20),
                      child: Text(
                        widget.studentName.isNotEmpty
                            ? widget.studentName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.studentName,
                              style: Theme.of(context).textTheme.headlineSmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Center(child: CircularProgressIndicator()),
              ],
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load profile:\n${err.toString().replaceAll('Exception: ', '')}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.errorColor),
                ),
              ),
            ),
            data: (student) => ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Avatar + Name
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.primaryColor.withAlpha(20),
                      child: Text(
                        student.fullName.isNotEmpty
                            ? student.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(student.fullName,
                              style: Theme.of(context).textTheme.headlineSmall),
                          Text(student.studentId,
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    _StatusBadge(isCleared: student.isCleared),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                // Info rows
                _InfoRow(label: 'Class',  value: '${student.gradeName} — ${student.sectionName}'),
                _InfoRow(label: 'Phone',  value: student.phoneNumber),
                _InfoRow(
                  label: 'Transport',
                  value: student.transportRouteName ?? 'None',
                  valueColor: student.transportRouteName != null
                      ? AppTheme.accentColor
                      : AppTheme.textSecondary,
                  isBadge: student.transportRouteName != null,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Text('Fee Summary', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _InfoRow(label: 'Total Paid',    value: CurrencyFormatter.formatINR(student.balances.totalPaid)),
                _InfoRow(label: 'Total Pending', value: CurrencyFormatter.formatINR(student.balances.totalDue),
                    valueColor: student.balances.totalDue > 0 ? AppTheme.warningColor : AppTheme.successColor),
                _InfoRow(label: 'Tuition Due',   value: CurrencyFormatter.formatINR(student.balances.tuition.due)),
                _InfoRow(label: 'Transport Due', value: CurrencyFormatter.formatINR(student.balances.transport.due)),
                _InfoRow(label: 'Other Due',     value: CurrencyFormatter.formatINR(student.balances.other.due),
                    valueColor: student.balances.other.due > 0 ? AppTheme.warningColor : AppTheme.successColor),
                _InfoRow(label: 'Other Fee Items', value: '${student.customFees.length}'),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// View Fee History Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class FeeHistorySheet extends ConsumerWidget {
  const FeeHistorySheet({super.key, required this.studentId, required this.studentName});
  final String studentId;
  final String studentName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(studentHistoryProvider(studentId));

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _SheetHandle(title: 'Fee History — $studentName'),
              Expanded(
                child: historyAsync.when(
                  data: (txns) {
                    if (txns.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 48, color: AppTheme.textSecondary),
                            SizedBox(height: 12),
                            Text('No payments yet',
                                style: TextStyle(color: AppTheme.textSecondary)),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: txns.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final t = txns[i];
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: _categoryColor(t.feeCategory).withAlpha(20),
                            child: Icon(_categoryIcon(t.feeCategory),
                                size: 18, color: _categoryColor(t.feeCategory)),
                          ),
                          title: Text(
                            _categoryLabel(t.feeCategory),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          subtitle: Text(
                            DateFormatter.toLongDateTime(t.timestamp),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          trailing: Text(
                            CurrencyFormatter.formatINR(t.amountCollected),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successColor,
                            ),
                          ),
                          dense: true,
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text('Error: ${e.toString().replaceAll('Exception: ', '')}',
                        style: const TextStyle(color: AppTheme.errorColor)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Update Fees Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class UpdateFeesSheet extends ConsumerStatefulWidget {
  const UpdateFeesSheet({super.key, required this.student, required this.onSuccess});
  final Student student;
  final VoidCallback onSuccess;

  @override
  ConsumerState<UpdateFeesSheet> createState() => _UpdateFeesSheetState();
}

class _UpdateFeesSheetState extends ConsumerState<UpdateFeesSheet> {
  final _tuitionCtrl   = TextEditingController();
  final _transportCtrl = TextEditingController();
  final _otherCtrl     = TextEditingController();
  String? _tuitionError;
  String? _transportError;
  String? _otherError;
  bool    _loading = false;

  @override
  void dispose() {
    _tuitionCtrl.dispose();
    _transportCtrl.dispose();
    _otherCtrl.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      final t  = double.tryParse(_tuitionCtrl.text) ?? 0;
      final tr = double.tryParse(_transportCtrl.text) ?? 0;
      final o  = double.tryParse(_otherCtrl.text) ?? 0;
      final tDue  = widget.student.balances.tuition.due.toDouble();
      final trDue = widget.student.balances.transport.due.toDouble();
      final oDue  = widget.student.balances.other.due.toDouble();

      _tuitionError = t < 0
          ? 'Amount cannot be negative'
          : t > tDue
              ? 'Exceeds tuition due (${CurrencyFormatter.formatINR(tDue)})'
              : null;
      _transportError = tr < 0
          ? 'Amount cannot be negative'
          : tr > trDue
              ? 'Exceeds transport due (${CurrencyFormatter.formatINR(trDue)})'
              : null;
      _otherError = o < 0
          ? 'Amount cannot be negative'
          : o > oDue
              ? 'Exceeds other due (${CurrencyFormatter.formatINR(oDue)})'
              : null;
    });
  }

  bool get _canSubmit =>
      _tuitionError == null &&
      _transportError == null &&
      _otherError == null &&
      (_tuitionCtrl.text.isNotEmpty || _transportCtrl.text.isNotEmpty || _otherCtrl.text.isNotEmpty) &&
      !_loading;

  Future<void> _submit() async {
    _validate();
    if (!_canSubmit) return;
    setState(() => _loading = true);

    final repo = ref.read(studentRepositoryProvider);
    try {
      final tuitionAmt   = double.tryParse(_tuitionCtrl.text)   ?? 0;
      final transportAmt = double.tryParse(_transportCtrl.text) ?? 0;
      final otherAmt     = double.tryParse(_otherCtrl.text)     ?? 0;

      if (tuitionAmt > 0) {
        await repo.recordPayment(widget.student.id, 'tuition', tuitionAmt);
      }
      if (transportAmt > 0) {
        await repo.recordPayment(widget.student.id, 'transport', transportAmt);
      }
      if (otherAmt > 0) {
        await repo.recordPayment(widget.student.id, 'other', otherAmt);
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHandle(title: 'Update Fees — ${s.fullName}'),
            const SizedBox(height: 8),
            _FeeAmountField(
              controller:    _tuitionCtrl,
              label:         'Tuition Payment',
              currentDue:    s.balances.tuition.due,
              errorText:     _tuitionError,
              onChanged:     (_) => _validate(),
            ),
            const SizedBox(height: 16),
            _FeeAmountField(
              controller:    _transportCtrl,
              label:         'Transport Payment',
              currentDue:    s.balances.transport.due,
              errorText:     _transportError,
              onChanged:     (_) => _validate(),
            ),
            const SizedBox(height: 16),
            _FeeAmountField(
              controller:    _otherCtrl,
              label:         'Other Fee Payment',
              currentDue:    s.balances.other.due,
              errorText:     _otherError,
              onChanged:     (_) => _validate(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit ? _submit : null,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Record Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Other Fee Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class AddOtherFeeSheet extends ConsumerStatefulWidget {
  const AddOtherFeeSheet({super.key, required this.student, required this.onSuccess});
  final Student student;
  final VoidCallback onSuccess;

  @override
  ConsumerState<AddOtherFeeSheet> createState() => _AddOtherFeeSheetState();
}

class _AddOtherFeeSheetState extends ConsumerState<AddOtherFeeSheet> {
  final _descCtrl   = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _formKey    = GlobalKey<FormState>();
  bool  _loading    = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final repo = ref.read(studentRepositoryProvider);
    try {
      await repo.addOtherFee(
        widget.student.id,
        _descCtrl.text.trim(),
        double.parse(_amountCtrl.text),
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Other fee added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHandle(title: 'Add Other Fee — ${widget.student.fullName}'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Fee Description'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Description is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixText: '₹ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Amount is required';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return 'Amount must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Add Fee'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Delete Student Dialog
// ─────────────────────────────────────────────────────────────────────────────
class DeleteStudentDialog extends ConsumerStatefulWidget {
  const DeleteStudentDialog({super.key, required this.student, required this.onSuccess});
  final Student student;
  final VoidCallback onSuccess;

  @override
  ConsumerState<DeleteStudentDialog> createState() => _DeleteStudentDialogState();
}

class _DeleteStudentDialogState extends ConsumerState<DeleteStudentDialog> {
  final _ctrl    = TextEditingController();
  bool  _loading = false;
  bool  _enabled = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      setState(() => _enabled = _ctrl.text == 'DELETE');
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (!_enabled) return;
    setState(() => _loading = true);
    final repo = ref.read(studentRepositoryProvider);
    try {
      await repo.deleteStudent(widget.student.id);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.student.fullName} deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor),
          SizedBox(width: 8),
          Text('Delete Student', style: TextStyle(color: AppTheme.errorColor)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                const TextSpan(text: 'You are about to permanently delete '),
                TextSpan(
                  text: widget.student.fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: ' ('),
                TextSpan(
                  text: widget.student.studentId,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: '). This action cannot be undone.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Type DELETE to confirm:',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'DELETE',
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.errorColor),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
          onPressed: _enabled && !_loading ? _delete : null,
          child: _loading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Delete', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────
class _SheetHandle extends StatelessWidget {
  const _SheetHandle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBadge = false,
  });

  final String  label;
  final String  value;
  final Color?  valueColor;
  final bool    isBadge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: isBadge
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: (valueColor ?? AppTheme.accentColor).withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(value,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: valueColor ?? AppTheme.accentColor,
                        )),
                  )
                : Text(value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: valueColor ?? AppTheme.textPrimary,
                    )),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isCleared});
  final bool isCleared;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isCleared ? AppTheme.successColor : AppTheme.warningColor).withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCleared ? AppTheme.successColor : AppTheme.warningColor,
          width: 1,
        ),
      ),
      child: Text(
        isCleared ? 'Cleared' : 'Pending',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isCleared ? AppTheme.successColor : AppTheme.warningColor,
        ),
      ),
    );
  }
}

class _FeeAmountField extends StatelessWidget {
  const _FeeAmountField({
    required this.controller,
    required this.label,
    required this.currentDue,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String                label;
  final num                   currentDue;
  final String?               errorText;
  final void Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label  (Due: ${CurrencyFormatter.formatINR(currentDue)})',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: '0',
            prefixText: '₹ ',
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

Color _categoryColor(String cat) {
  switch (cat) {
    case 'tuition':   return AppTheme.primaryColor;
    case 'transport': return AppTheme.accentColor;
    default:          return AppTheme.warningColor;
  }
}

IconData _categoryIcon(String cat) {
  switch (cat) {
    case 'tuition':   return Icons.school_outlined;
    case 'transport': return Icons.directions_bus_outlined;
    default:          return Icons.receipt_outlined;
  }
}

String _categoryLabel(String cat) {
  switch (cat) {
    case 'tuition':   return 'Tuition';
    case 'transport': return 'Transport';
    default:          return 'Other';
  }
}
