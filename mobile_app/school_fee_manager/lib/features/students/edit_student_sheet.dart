import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_fee_manager/core/models/master_config.dart';
import 'package:school_fee_manager/core/models/student.dart';
import 'package:school_fee_manager/core/theme/app_theme.dart';
import 'package:school_fee_manager/features/master_config/master_config_provider.dart';
import 'package:school_fee_manager/features/students/student_provider.dart';

class EditStudentSheet extends ConsumerStatefulWidget {
  const EditStudentSheet({super.key, required this.student, required this.onSuccess});
  final Student student;
  final VoidCallback onSuccess;

  @override
  ConsumerState<EditStudentSheet> createState() => _EditStudentSheetState();
}

class _EditStudentSheetState extends ConsumerState<EditStudentSheet> {
  final _formKey    = GlobalKey<FormState>();
  late  TextEditingController _nameCtrl;
  late  TextEditingController _phoneCtrl;
  late  TextEditingController _avatarCtrl;
  late  TextEditingController _tuitionDueCtrl;
  late  TextEditingController _transportDueCtrl;
  late  TextEditingController _otherDueCtrl;

  String?  _selectedGradeId;
  String?  _selectedSectionId;
  String?  _selectedRouteId;
  bool     _loading = false;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _nameCtrl          = TextEditingController(text: s.fullName);
    _phoneCtrl         = TextEditingController(text: s.phoneNumber);
    _avatarCtrl        = TextEditingController(text: s.avatarUrl ?? '');
    _tuitionDueCtrl    = TextEditingController(text: s.balances.tuition.due.toString());
    _transportDueCtrl  = TextEditingController(text: s.balances.transport.due.toString());
    _otherDueCtrl      = TextEditingController(text: s.balances.other.due.toString());
    _selectedGradeId   = s.gradeId.isNotEmpty   ? s.gradeId   : null;
    _selectedSectionId = s.sectionId.isNotEmpty ? s.sectionId : null;
    _selectedRouteId   = s.transportRouteId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _avatarCtrl.dispose();
    _tuitionDueCtrl.dispose();
    _transportDueCtrl.dispose();
    _otherDueCtrl.dispose();
    super.dispose();
  }

  double _safeDouble(String text) {
    if (text.isEmpty) return 0;
    final n = double.tryParse(text);
    return (n == null || n < 0) ? 0 : n;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final repo = ref.read(studentRepositoryProvider);
    try {
      final data = {
        'full_name':           _nameCtrl.text.trim(),
        'phone_number':        _phoneCtrl.text.trim(),
        'grade_id':            _selectedGradeId,
        'section_id':          _selectedSectionId,
        'transport_route_id':  _selectedRouteId,
        'avatar_url':          _avatarCtrl.text.trim().isEmpty ? null : _avatarCtrl.text.trim(),
        'balances': {
          'tuition':   {
            'paid': widget.student.balances.tuition.paid,
            'due':  _safeDouble(_tuitionDueCtrl.text),
          },
          'transport': {
            'paid': widget.student.balances.transport.paid,
            'due':  _safeDouble(_transportDueCtrl.text),
          },
          'other': {
            'paid': widget.student.balances.other.paid,
            'due':  _safeDouble(_otherDueCtrl.text),
          },
        },
      };

      await repo.updateStudent(widget.student.id, data);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student updated successfully')),
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
    final gradesAsync  = ref.watch(gradesProvider);
    final routesAsync  = ref.watch(routesProvider);
    final sections     = _selectedGradeId != null
        ? ref.watch(sectionsProvider(_selectedGradeId!))
        : const AsyncValue<List<MasterConfig>>.data([]);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: controller,
              padding: EdgeInsets.fromLTRB(
                  24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 32),
              children: [
                // Handle
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
                Text('Edit Student', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(widget.student.studentId,
                    style: Theme.of(context).textTheme.bodySmall),
                const Divider(height: 24),

                // Full name
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Full name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Phone is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Grade dropdown
                gradesAsync.when(
                  data: (grades) => DropdownButtonFormField<String>(
                    initialValue: _selectedGradeId,
                    decoration: const InputDecoration(labelText: 'Grade'),
                    items: grades.map((g) =>
                        DropdownMenuItem(value: g.id, child: Text(g.name))).toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedGradeId   = v;
                        _selectedSectionId = null;
                      });
                    },
                    validator: (v) => v == null ? 'Grade is required' : null,
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, _) => const Text('Error loading grades'),
                ),
                const SizedBox(height: 16),

                // Section dropdown (depends on grade)
                sections.when(
                  data: (secs) => DropdownButtonFormField<String>(
                    initialValue: secs.any((s) => s.id == _selectedSectionId)
                        ? _selectedSectionId
                        : null,
                    decoration: const InputDecoration(labelText: 'Section'),
                    items: secs.map((s) =>
                        DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                    onChanged: _selectedGradeId == null
                        ? null
                        : (v) => setState(() => _selectedSectionId = v),
                    validator: (v) => v == null ? 'Section is required' : null,
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, _) => const Text('Error loading sections'),
                ),
                const SizedBox(height: 16),

                // Transport Route dropdown
                routesAsync.when(
                  data: (routes) => DropdownButtonFormField<String?>(
                    initialValue: _selectedRouteId,
                    decoration: const InputDecoration(labelText: 'Transport Route'),
                    items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text('None')),
                      ...routes.map((r) =>
                          DropdownMenuItem(value: r.id, child: Text(r.name))),
                    ],
                    onChanged: (v) => setState(() => _selectedRouteId = v),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, _) => const Text('Error loading routes'),
                ),
                const SizedBox(height: 16),

                // Avatar URL
                TextFormField(
                  controller: _avatarCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Avatar URL (optional)',
                    hintText: 'https://...',
                  ),
                ),
                const SizedBox(height: 20),

                // Balance overrides section
                const Divider(),
                const SizedBox(height: 8),
                Text('Outstanding Balance Override',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                const Text(
                  'Admin manual correction. Blank fields default to 0.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),

                _BalanceField(controller: _tuitionDueCtrl,   label: 'Tuition Due (₹)'),
                const SizedBox(height: 12),
                _BalanceField(controller: _transportDueCtrl, label: 'Transport Due (₹)'),
                const SizedBox(height: 12),
                _BalanceField(controller: _otherDueCtrl,     label: 'Other Due (₹)'),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BalanceField extends StatelessWidget {
  const _BalanceField({required this.controller, required this.label});
  final TextEditingController controller;
  final String                label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixText: '₹ ',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        if (v == null || v.isEmpty) return null; // blank → 0, handled in _safeDouble
        final n = double.tryParse(v);
        if (n == null) return 'Enter a valid number';
        if (n < 0)     return 'Cannot be negative';
        return null;
      },
    );
  }
}
