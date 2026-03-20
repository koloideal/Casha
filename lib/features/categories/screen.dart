import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../settings/provider.dart';
import 'provider.dart';

enum ChartType { pie, bar }

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  int _touchedIndex = -1;
  ChartType _chartType = ChartType.pie;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(categoryExpenseProvider);
    final monthlyData = ref.watch(monthlyBreakdownProvider);
    final total = data.values.fold(0.0, (a, b) => a + b);
    final currencyInfo = ref.watch(currencyProvider);

    // Sort categories by amount descending
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Categories',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            Text(
              'Expense breakdown',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
          ],
        ),
        actions: [
          _ChartToggle(
            selected: _chartType,
            onChanged: (t) => setState(() => _chartType = t),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data.isEmpty)
                const Expanded(child: _EmptyState())
              else
                Expanded(
                  child: ListView(
                    children: [
                      if (_chartType == ChartType.pie)
                        _PieChartCard(
                          data: data,
                          total: total,
                          touchedIndex: _touchedIndex,
                          onTouch: (i) => setState(() => _touchedIndex = i),
                          currency: currencyInfo.symbol,
                        )
                      else
                        _BarChartCard(monthlyData: monthlyData, currency: currencyInfo.symbol),
                      const SizedBox(height: 20),
                      Text(
                        'Ranked by Amount',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ...sortedEntries.asMap().entries.map((entry) {
                        final rank = entry.key + 1;
                        final cat = entry.value.key;
                        final amount = entry.value.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _CategoryRow(
                            rank: rank,
                            category: cat,
                            amount: amount,
                            total: total,
                            currency: currencyInfo.symbol,
                          ),
                        );
                      }),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartToggle extends StatelessWidget {
  final ChartType selected;
  final ValueChanged<ChartType> onChanged;
  const _ChartToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleButton(
            icon: Icons.pie_chart_rounded,
            isSelected: selected == ChartType.pie,
            onTap: () => onChanged(ChartType.pie),
          ),
          _ToggleButton(
            icon: Icons.bar_chart_rounded,
            isSelected: selected == ChartType.bar,
            onTap: () => onChanged(ChartType.bar),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _ToggleButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected ? AppColors.accent : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          size: 20,
        ),
      ),
    );
  }
}

class _PieChartCard extends StatelessWidget {
  final Map<String, double> data;
  final double total;
  final int touchedIndex;
  final ValueChanged<int> onTouch;
  final String currency;

  const _PieChartCard({
    required this.data,
    required this.total,
    required this.touchedIndex,
    required this.onTouch,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.touchedSection == null) {
                          onTouch(-1);
                          return;
                        }
                        onTouch(response.touchedSection!.touchedSectionIndex);
                      },
                    ),
                    sectionsSpace: 3,
                    centerSpaceRadius: 60,
                    sections: List.generate(entries.length, (i) {
                      final isTouched = i == touchedIndex;
                      final cat = entries[i].key;
                      final val = entries[i].value;
                      final color = AppCategories.colors[cat] ?? AppColors.accent;
                      return PieChartSectionData(
                        color: color,
                        value: val,
                        title: isTouched
                            ? '${(val / total * 100).toStringAsFixed(1)}%'
                            : '',
                        radius: isTouched ? 60 : 50,
                        titleStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      );
                    }),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                    Text(
                      '$currency${total.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChartCard extends StatelessWidget {
  final List<MonthlyData> monthlyData;
  final String currency;
  const _BarChartCard({required this.monthlyData, required this.currency});

  @override
  Widget build(BuildContext context) {
    final maxY = monthlyData.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    final adjustedMaxY = maxY * 1.2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last 6 Months',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: adjustedMaxY > 0 ? adjustedMaxY : 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '$currency${rod.toY.toStringAsFixed(2)}',
                        TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
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
                        if (value.toInt() >= 0 && value.toInt() < monthlyData.length) {
                          final month = monthlyData[value.toInt()].month;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MMM').format(month),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 11,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: adjustedMaxY > 0 ? adjustedMaxY / 4 : 25,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Theme.of(context).dividerColor,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  monthlyData.length,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: monthlyData[i].amount,
                        color: AppColors.accent,
                        width: 24,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final int rank;
  final String category;
  final double amount;
  final double total;
  final String currency;
  const _CategoryRow({
    required this.rank,
    required this.category,
    required this.amount,
    required this.total,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppCategories.colors[category] ?? AppColors.accent;
    final icon = AppCategories.icons[category] ?? Icons.category_rounded;
    final pct = total > 0 ? amount / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rank <= 3 ? color.withOpacity(0.2) : Theme.of(context).dividerColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$rank',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: rank <= 3 ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$currency${amount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.expense,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    '${(pct * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Theme.of(context).dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pie_chart_outline_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No expense data',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add some expenses to see the breakdown',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
        ],
      ),
    );
  }
}
