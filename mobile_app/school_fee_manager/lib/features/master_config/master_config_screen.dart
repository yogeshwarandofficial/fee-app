import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_fee_manager/core/models/master_config.dart';
import 'package:school_fee_manager/core/theme/app_theme.dart';
import 'package:school_fee_manager/features/master_config/master_config_provider.dart';

class MasterConfigScreen extends ConsumerWidget {
  const MasterConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 2,
          shadowColor: Colors.black.withAlpha(20),
          iconTheme: const IconThemeData(color: AppTheme.textPrimary),
          title: const Text(
            'Master Configuration',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9), // Light grey background for tabs
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [
                  Tab(text: 'Grades'),
                  Tab(text: 'Sections'),
                  Tab(text: 'Routes'),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _GradesTab(),
            _SectionsTab(),
            _RoutesTab(),
          ],
        ),
      ),
    );
  }
}

// ── Shared Empty State ────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: AppTheme.primaryColor.withAlpha(150)),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grades Tab ──────────────────────────────────────────────────────────────
class _GradesTab extends ConsumerWidget {
  const _GradesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradesAsync = ref.watch(gradesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(gradesProvider.future),
        child: gradesAsync.when(
          data: (grades) {
            if (grades.isEmpty) {
              return const _EmptyState(icon: Icons.school_rounded, message: 'No grades configured yet.');
            }
            return ListView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
              itemCount: grades.length,
              itemBuilder: (context, index) {
                final grade = grades[index];
                return _ConfigListTile(
                  config: grade,
                  icon: Icons.school_rounded,
                  iconColor: Colors.blue,
                  onEdit: () => _showEditDialog(context, ref, grade),
                  onDelete: () => _showDeleteDialog(context, ref, grade),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: ${err.toString().replaceAll('Exception: ', '')}')),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref, 'grade', null),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Grade', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ── Sections Tab ────────────────────────────────────────────────────────────
class _SectionsTab extends ConsumerWidget {
  const _SectionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradesAsync = ref.watch(gradesProvider);
    final selectedGradeId = ref.watch(selectedGradeForSectionsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Premium Dropdown for selecting parent Grade
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: gradesAsync.when(
              data: (grades) {
                if (grades.isEmpty) {
                  return const Text('Please create a Grade first.', style: TextStyle(color: AppTheme.textSecondary));
                }
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withAlpha(40)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: selectedGradeId,
                      hint: const Text('Select Parent Grade'),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryColor),
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(16),
                      items: grades.map((g) {
                        return DropdownMenuItem(
                          value: g.id, 
                          child: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        ref.read(selectedGradeForSectionsProvider.notifier).updateState(val);
                      },
                    ),
                  ),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => const Text('Error loading grades'),
            ),
          ),
          
          // List of sections for the selected grade
          Expanded(
            child: selectedGradeId == null
                ? const _EmptyState(icon: Icons.keyboard_double_arrow_up_rounded, message: 'Select a grade to view sections.')
                : Consumer(
                    builder: (context, ref, child) {
                      final sectionsAsync = ref.watch(sectionsProvider(selectedGradeId));
                      return RefreshIndicator(
                        onRefresh: () => ref.refresh(sectionsProvider(selectedGradeId).future),
                        child: sectionsAsync.when(
                          data: (sections) {
                            if (sections.isEmpty) {
                              return const _EmptyState(icon: Icons.class_rounded, message: 'No sections configured for this grade.');
                            }
                            return ListView.builder(
                              padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 100),
                              itemCount: sections.length,
                              itemBuilder: (context, index) {
                                final section = sections[index];
                                return _ConfigListTile(
                                  config: section,
                                  icon: Icons.class_rounded,
                                  iconColor: Colors.purple,
                                  onEdit: () => _showEditDialog(context, ref, section),
                                  onDelete: () => _showDeleteDialog(context, ref, section),
                                );
                              },
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, stack) => Center(child: Text('Error: ${err.toString().replaceAll('Exception: ', '')}')),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: selectedGradeId == null
            ? null 
            : () => _showAddDialog(context, ref, 'section', selectedGradeId),
        backgroundColor: selectedGradeId == null ? Colors.grey : AppTheme.primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Section', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ── Routes Tab ──────────────────────────────────────────────────────────────
class _RoutesTab extends ConsumerWidget {
  const _RoutesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(routesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(routesProvider.future),
        child: routesAsync.when(
          data: (routes) {
            if (routes.isEmpty) {
              return const _EmptyState(icon: Icons.directions_bus_rounded, message: 'No routes configured yet.');
            }
            return ListView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
              itemCount: routes.length,
              itemBuilder: (context, index) {
                final route = routes[index];
                return _ConfigListTile(
                  config: route,
                  icon: Icons.directions_bus_rounded,
                  iconColor: Colors.orange,
                  onEdit: () => _showEditDialog(context, ref, route),
                  onDelete: () => _showDeleteDialog(context, ref, route),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: ${err.toString().replaceAll('Exception: ', '')}')),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref, 'route', null),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Route', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ── Shared UI Components ────────────────────────────────────────────────────

class _ConfigListTile extends StatelessWidget {
  const _ConfigListTile({
    required this.config,
    required this.icon,
    required this.iconColor,
    required this.onEdit,
    required this.onDelete,
  });

  final MasterConfig config;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              config.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          _ActionButton(
            icon: Icons.edit_rounded,
            color: Colors.blue,
            onTap: onEdit,
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.delete_outline_rounded,
            color: Colors.red,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(15),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

// ── Dialogs ─────────────────────────────────────────────────────────────────

InputDecoration _dialogInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.grey.withAlpha(15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
    ),
  );
}

void _showAddDialog(BuildContext context, WidgetRef ref, String type, String? parentId) {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String? errorMsg;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              'Add ${type[0].toUpperCase()}${type.substring(1)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errorMsg != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  TextFormField(
                    controller: controller,
                    decoration: _dialogInputDecoration('Name'),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Name cannot be empty';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  
                  setState(() => errorMsg = null);
                  final repo = ref.read(masterConfigRepositoryProvider);
                  
                  try {
                    await repo.createConfig(type, controller.text, parentId: parentId);
                    
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      if (type == 'grade') ref.invalidate(gradesProvider);
                      if (type == 'route') ref.invalidate(routesProvider);
                      if (type == 'section' && parentId != null) {
                        ref.invalidate(sectionsProvider(parentId));
                      }
                    }
                  } catch (e) {
                    setState(() {
                      errorMsg = e.toString().replaceAll('Exception: ', '');
                    });
                  }
                },
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    },
  );
}

void _showEditDialog(BuildContext context, WidgetRef ref, MasterConfig config) {
  final controller = TextEditingController(text: config.name);
  final formKey = GlobalKey<FormState>();
  String? errorMsg;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              'Edit ${config.type[0].toUpperCase()}${config.type.substring(1)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errorMsg != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  TextFormField(
                    controller: controller,
                    decoration: _dialogInputDecoration('Name'),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Name cannot be empty';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  
                  setState(() => errorMsg = null);
                  final repo = ref.read(masterConfigRepositoryProvider);
                  
                  try {
                    await repo.updateConfig(config.id, controller.text);
                    
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      if (config.type == 'grade') ref.invalidate(gradesProvider);
                      if (config.type == 'route') ref.invalidate(routesProvider);
                      if (config.type == 'section' && config.parentId != null) {
                        ref.invalidate(sectionsProvider(config.parentId!));
                      }
                    }
                  } catch (e) {
                    setState(() {
                      errorMsg = e.toString().replaceAll('Exception: ', '');
                    });
                  }
                },
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    },
  );
}

void _showDeleteDialog(BuildContext context, WidgetRef ref, MasterConfig config) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${config.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final repo = ref.read(masterConfigRepositoryProvider);
              try {
                await repo.deleteConfig(config.id);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  if (config.type == 'grade') ref.invalidate(gradesProvider);
                  if (config.type == 'route') ref.invalidate(routesProvider);
                  if (config.type == 'section' && config.parentId != null) {
                    ref.invalidate(sectionsProvider(config.parentId!));
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Deleted successfully'), backgroundColor: Color(0xFF10B981)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop();
                  _showErrorDialog(context, e.toString().replaceAll('Exception: ', ''));
                }
              }
            },
            child: const Text('Yes, Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      );
    },
  );
}

void _showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.withAlpha(20), shape: BoxShape.circle),
              child: const Icon(Icons.error_outline_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Cannot Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: AppTheme.textSecondary, height: 1.5)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              foregroundColor: AppTheme.textPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      );
    },
  );
}
