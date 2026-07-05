import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_fee_manager/core/theme/app_theme.dart';
import 'package:school_fee_manager/features/auth/auth_provider.dart';
import 'package:school_fee_manager/features/dashboard/dashboard_provider.dart';
import 'package:school_fee_manager/features/master_config/master_config_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // match HTML background
      drawer: _DashboardDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header (Blue) ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB), // bg-blue-600
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu_rounded, color: Colors.white),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.bar_chart_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // ── Filter Bar (White) ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: _GradeFilterDropdown(),
                  ),
                  const SizedBox(width: 12),
                  _ExcelButton(),
                ],
              ),
            ),

            // ── Main Content Area ───────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(dashboardProvider);
                  try {
                    await ref.read(dashboardProvider.future);
                  } catch (_) {}
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: const _DashboardContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Components ──────────────────────────────────────────────────────────────

class _GradeFilterDropdown extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradesAsync = ref.watch(gradesProvider);
    final selectedGradeId = ref.watch(dashboardGradeFilterProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC), // bg-slate-50
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)), // border-slate-200
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selectedGradeId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary),
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('All Grades')),
            ...gradesAsync.maybeWhen(
              data: (grades) => grades.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))),
              orElse: () => [],
            ),
          ],
          onChanged: (val) {
            ref.read(dashboardGradeFilterProvider.notifier).updateState(val);
          },
        ),
      ),
    );
  }
}

class _ExcelButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Downloading EXCEL...')),
          );
          await ref.read(dashboardExportProvider).downloadExcel();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to download EXCEL: $e'), backgroundColor: Colors.red),
            );
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF10B981), // bg-emerald-600
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text('EXCEL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardProvider);

    return metricsAsync.when(
      data: (metrics) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Grid: Students & Collected
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'STUDENTS',
                    value: metrics.studentStrength.toString(),
                    valueColor: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: 'COLLECTED',
                    value: '₹${_formatCurrency(metrics.totalPaid)}',
                    valueColor: const Color(0xFF10B981), // emerald-600
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Full Width: Pending Dues
            _PendingDuesCard(amount: metrics.pendingDue),
            const SizedBox(height: 16),

            // Charts
            _ChartCard(
              title: 'Collection Trend',
              child: SizedBox(
                height: 200,
                child: _TrendChart(trend: metrics.monthlyCollectionTrend),
              ),
            ),
            const SizedBox(height: 16),
            _ChartCard(
              title: 'Paid vs Unpaid',
              child: SizedBox(
                height: 220,
                child: _DoughnutChart(
                  paidPct: metrics.paidVsUnpaidPercentage['paid'] ?? 0,
                  unpaidPct: metrics.paidVsUnpaidPercentage['unpaid'] ?? 0,
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
      error: (err, stack) => Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Error: ${err.toString().replaceAll('Exception: ', '')}'))),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 10000000) return '${(value / 10000000).toStringAsFixed(2)}Cr';
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(2)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toStringAsFixed(0);
  }
}

// ── UI Cards ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color valueColor;

  const _StatCard({required this.title, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x0C000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF94A3B8), // text-slate-400
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: valueColor,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingDuesCard extends StatelessWidget {
  final double amount;

  const _PendingDuesCard({required this.amount});

  String _formatCurrency(double value) {
    if (value >= 10000000) return '${(value / 10000000).toStringAsFixed(2)}Cr';
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(2)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFEF3C7)), // border-amber-100
        boxShadow: const [BoxShadow(color: Color(0x0C000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PENDING DUES',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF94A3B8), // text-slate-400
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${_formatCurrency(amount)}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD97706), // text-amber-600
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x0C000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ── Chart Widgets ───────────────────────────────────────────────────────────

class _TrendChart extends StatelessWidget {
  final List<MonthlyTrend> trend;

  const _TrendChart({required this.trend});

  @override
  Widget build(BuildContext context) {
    final data = trend.isEmpty
        ? List.generate(6, (index) => MonthlyTrend(month: 'M${index + 1}', amount: 0))
        : trend;

    final maxY = data.fold<double>(0, (prev, e) => e.amount > prev ? e.amount : prev);
    final upperLimit = maxY == 0 ? 10000.0 : maxY * 1.2;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: upperLimit,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.blueGrey.shade800,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '₹${rod.toY.toInt()}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const Text('');
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    data[index].month,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text('');
                return Text(
                  '₹${_formatCompactCurrency(value)}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: upperLimit / 4 == 0 ? 1 : upperLimit / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withAlpha(30),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.amount,
                color: const Color(0xFF3B82F6), // blue-500 from HTML prototype
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatCompactCurrency(double value) {
    if (value >= 10000000) return '${(value / 10000000).toStringAsFixed(1)}Cr';
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toStringAsFixed(0);
  }
}

class _DoughnutChart extends StatelessWidget {
  final int paidPct;
  final int unpaidPct;

  const _DoughnutChart({required this.paidPct, required this.unpaidPct});

  @override
  Widget build(BuildContext context) {
    final isEmpty = paidPct == 0 && unpaidPct == 0;

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              startDegreeOffset: -90,
              sections: [
                if (isEmpty)
                  PieChartSectionData(
                    color: Colors.grey.withAlpha(50),
                    value: 100,
                    title: '',
                    radius: 40,
                  )
                else ...[
                  PieChartSectionData(
                    color: const Color(0xFF10B981), // emerald-500
                    value: paidPct.toDouble(),
                    title: '${paidPct}%',
                    radius: 40,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  PieChartSectionData(
                    color: const Color(0xFFFBBF24), // amber-400
                    value: unpaidPct.toDouble(),
                    title: '${unpaidPct}%',
                    radius: 40,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ]
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(color: const Color(0xFF10B981), text: 'Paid'),
            const SizedBox(width: 16),
            _LegendItem(color: const Color(0xFFFBBF24), text: 'Unpaid'),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ── Drawer ──────────────────────────────────────────────────────────────────

class _DashboardDrawer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF2563EB)), // match header blue
            child: Center(
              child: Text(
                'MRT & ABR\nMatriculation School',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_rounded, color: Color(0xFF2563EB)),
            title: const Text('Dashboard', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
            selected: true,
            selectedTileColor: const Color(0xFF2563EB).withAlpha(15),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.people_alt_rounded),
            title: const Text('Student Management'),
            onTap: () {
              Navigator.pop(context);
              context.push('/students');
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_rounded),
            title: const Text('Fee Allocation'),
            onTap: () {
              Navigator.pop(context);
              context.push('/allocations');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_rounded),
            title: const Text('Master Configuration'),
            onTap: () {
              Navigator.pop(context);
              context.push('/master-config');
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
