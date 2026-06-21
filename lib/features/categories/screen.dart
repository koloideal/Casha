import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/services/haptic_service.dart';
import '../../shared/providers/amount_format_provider.dart';
import '../../shared/utils/currency_utils.dart';
import '../../shared/widgets/byn_sign.dart';
import '../dashboard/provider.dart';
import '../dashboard/widgets/summary_row.dart';
import '../settings/provider.dart';
import 'provider.dart';
import 'widgets/account_scope_chips.dart';
import 'widgets/stats_hero_card.dart';

enum ChartType { pie, bar }

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  int _touchedIndex = -1;
  ChartType _chartType = ChartType.pie;
  bool _showIncome = false;

  String _scopeLabel(AppStrings s) {
    final activeAccount = ref.watch(activeAccountProvider);
    if (activeAccount == null) return s.allAccounts;
    return activeAccount.name;
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final data = _showIncome
        ? ref.watch(categoryIncomeProvider)
        : ref.watch(categoryExpenseProvider);
    final monthlyData = _showIncome
        ? ref.watch(monthlyIncomeBreakdownProvider)
        : ref.watch(monthlyBreakdownProvider);
    final total = data.values.fold(0.0, (a, b) => a + b);
    final currencyInfo = ref.watch(statsCurrencyProvider);
    final income = ref.watch(statsIncomeTotalProvider);
    final expense = ref.watch(statsExpenseTotalProvider);
    final timeFilter = ref.watch(timeFilterProvider);
    final scopeLabel = _scopeLabel(s);

    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          s.statistics,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
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
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AccountScopeChips(),
              const SizedBox(height: 12),
              StatsHeroCard(
                amount: total,
                label: _showIncome ? s.income : s.expenses,
                accentColor: _showIncome ? AppColors.income : AppColors.expense,
                scopeLabel: scopeLabel,
              ),
              const SizedBox(height: 12),
              SummaryRow(
                income: income,
                expense: expense,
                currencyInfo: currencyInfo,
                strings: s,
              ),
              const SizedBox(height: 12),
              _StatsTimeFilter(
                strings: s,
                timeFilter: timeFilter,
                onAllTime: () =>
                    ref.read(timeFilterProvider.notifier).set(TimeFilter.allTime),
                onMonth: () => ref
                    .read(timeFilterProvider.notifier)
                    .set(TimeFilter.lastMonth),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TypeToggle(
                      label: s.expenses,
                      isSelected: !_showIncome,
                      color: AppColors.expense,
                      onTap: () => setState(() {
                        _showIncome = false;
                        _touchedIndex = -1;
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TypeToggle(
                      label: s.income,
                      isSelected: _showIncome,
                      color: AppColors.income,
                      onTap: () => setState(() {
                        _showIncome = true;
                        _touchedIndex = -1;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (data.isEmpty)
                Expanded(child: _EmptyState(isIncome: _showIncome))
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
                          currencyInfo: currencyInfo,
                          isIncome: _showIncome,
                        )
                      else
                        _BarChartCard(
                          monthlyData: monthlyData,
                          currencyInfo: currencyInfo,
                          isIncome: _showIncome,
                        ),
                      const SizedBox(height: 20),
                      Text(
                        s.rankedByAmount,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
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
                            currencyInfo: currencyInfo,
                            isIncome: _showIncome,
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

class _StatsTimeFilter extends StatelessWidget {
  final AppStrings strings;
  final TimeFilter timeFilter;
  final VoidCallback onAllTime;
  final VoidCallback onMonth;

  const _StatsTimeFilter({
    required this.strings,
    required this.timeFilter,
    required this.onAllTime,
    required this.onMonth,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        _TimeChip(
          label: strings.filterAllTime,
          isSelected: timeFilter == TimeFilter.allTime,
          isDark: isDark,
          onTap: () {
            HapticService.selection();
            onAllTime();
          },
        ),
        const SizedBox(width: 6),
        _TimeChip(
          label: strings.filterMonth,
          isSelected: timeFilter == TimeFilter.lastMonth,
          isDark: isDark,
          onTap: () {
            HapticService.selection();
            onMonth();
          },
        ),
      ],
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _TimeChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withOpacity(0.2)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: AppColors.accent, width: 1.5)
              : isDark
              ? null
              : Border.all(color: const Color(0xFFDDDDEE), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? AppColors.accent
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeToggle({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? color
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: isDark
            ? null
            : Border.all(color: const Color(0xFFDDDDEE), width: 1),
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
          color: isSelected
              ? AppColors.accent.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected
              ? AppColors.accent
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          size: 20,
        ),
      ),
    );
  }
}

class _PieChartCard extends ConsumerWidget {
  final Map<String, double> data;
  final double total;
  final int touchedIndex;
  final ValueChanged<int> onTouch;
  final CurrencyInfo currencyInfo;
  final bool isIncome;

  const _PieChartCard({
    required this.data,
    required this.total,
    required this.touchedIndex,
    required this.onTouch,
    required this.currencyInfo,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final fmt = ref.watch(amountFormatProvider);
    final entries = data.entries.toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isIncome ? AppColors.income : AppColors.expense;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFFDDDDEE),
          width: 1,
        ),
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
                      final color =
                          AppCategories.colors[cat] ?? AppColors.accent;
                      return PieChartSectionData(
                        color: color,
                        value: val,
                        title: isTouched
                            ? '${(val / total * 100).toStringAsFixed(1)}%'
                            : '',
                        radius: isTouched ? 60 : 50,
                        titleStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      );
                    }),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s.total,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      formatAmount(currencyInfo.symbol, total, fmt),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: accent,
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

class _BarChartCard extends ConsumerWidget {
  final List<MonthlyData> monthlyData;
  final CurrencyInfo currencyInfo;
  final bool isIncome;

  const _BarChartCard({
    required this.monthlyData,
    required this.currencyInfo,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final fmt = ref.watch(amountFormatProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor = isIncome ? AppColors.income : AppColors.expense;
    final maxY = monthlyData.isEmpty
        ? 100.0
        : monthlyData.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    final adjustedMaxY = maxY * 1.2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFFDDDDEE),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.lastSixMonths,
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
                        formatAmount(currencyInfo.symbol, rod.toY, fmt),
                        const TextStyle(
                          color: Colors.white,
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
                        if (value.toInt() >= 0 &&
                            value.toInt() < monthlyData.length) {
                          final month = monthlyData[value.toInt()].month;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MMM').format(month),
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
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
                        color: barColor,
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

class _CategoryRow extends ConsumerWidget {
  final int rank;
  final String category;
  final double amount;
  final double total;
  final CurrencyInfo currencyInfo;
  final bool isIncome;

  const _CategoryRow({
    required this.rank,
    required this.category,
    required this.amount,
    required this.total,
    required this.currencyInfo,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final fmt = ref.watch(amountFormatProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = AppCategories.colors[category] ?? AppColors.accent;
    final icon = AppCategories.icons[category] ?? Icons.category_rounded;
    final pct = total > 0 ? amount / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFFDDDDEE),
          width: 1,
        ),
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
                  color: rank <= 3
                      ? color.withOpacity(0.2)
                      : Theme.of(context).dividerColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$rank',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: rank <= 3
                        ? color
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
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
                  s.categoryLabel(category),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  currencyInfo.code == 'BYN'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BynSign(
                              fontSize: 14,
                              color: isIncome
                                  ? AppColors.income
                                  : AppColors.expense,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              formatAmount('', amount, fmt),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: isIncome
                                        ? AppColors.income
                                        : AppColors.expense,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        )
                      : Text(
                          formatAmount(currencyInfo.symbol, amount, fmt),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: isIncome
                                    ? AppColors.income
                                    : AppColors.expense,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                  Text(
                    '${(pct * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
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

class _EmptyState extends ConsumerWidget {
  final bool isIncome;
  const _EmptyState({required this.isIncome});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : const Color(0xFFDDDDEE),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.pie_chart_outline_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isIncome ? s.noIncomeData : s.noExpenseData,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isIncome ? s.addIncomeToSeeBreakdown : s.addExpensesToSeeBreakdown,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
