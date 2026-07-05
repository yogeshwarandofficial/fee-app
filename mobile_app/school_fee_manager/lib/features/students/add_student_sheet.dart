import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_fee_manager/core/models/master_config.dart';
import 'package:school_fee_manager/core/theme/app_theme.dart';
import 'package:school_fee_manager/features/master_config/master_config_provider.dart';
import 'package:school_fee_manager/features/students/student_provider.dart';

class AddStudentSheet extends ConsumerStatefulWidget {
  const AddStudentSheet({super.key, required this.onSuccess});
  final VoidCallback onSuccess;

  @override
  ConsumerState<AddStudentSheet> createState() => _AddStudentSheetState();
}

class _AddStudentSheetState extends ConsumerState<AddStudentSheet> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  final _avatarCtrl = TextEditingController();
  final _tuitionDueCtrl   = TextEditingController(text: '0');
  final _transportDueCtrl = TextEditingController(text: '0');
  final _otherDueCtrl     = TextEditingController(text: '0');

  String?  _selectedGradeId;
  String?  _selectedSectionId;
  String?  _selectedRouteId;
  bool     _loading = false;

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
        'initial_balances': {
          'tuition':   _safeDouble(_tuitionDueCtrl.text),
          'transport': _safeDouble(_transportDueCtrl.text),
          'other':     _safeDouble(_otherDueCtrl.text),
        },
      };

      await repo.createStudent(data);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student added successfully')),
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
    final gradesAsync = ref.watch(gradesProvider);
    final sections = _selectedGradeId == null
        ? const AsyncValue<List<MasterConfig>>.data([])
        : ref.watch(sectionsProvider(_selectedGradeId!));
    final routesAsync = ref.watch(routesProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Add Student',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 24),

                // Name
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name *'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone Number *'),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Phone is required';
                    if (v.trim().length != 10) return 'Must be 10 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Grade dropdown
                gradesAsync.when(
                  data: (grades) => DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Grade *'),
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
                    decoration: const InputDecoration(labelText: 'Section *'),
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
                    labelText: 'Avatar URL (Optional)',
                    hintText: 'https://...',
                  ),
                ),
                const SizedBox(height: 32),
                Text('Initial Due Balances (₹)',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 16),

                // Initial Balances
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _tuitionDueCtrl,
                        decoration: const InputDecoration(labelText: 'Tuition'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _transportDueCtrl,
                        decoration: const InputDecoration(labelText: 'Transport'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _otherDueCtrl,
                        decoration: const InputDecoration(labelText: 'Other'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Submit
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
                        : const Text('Add Student'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
