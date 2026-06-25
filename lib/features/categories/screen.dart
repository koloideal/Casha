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
import '../settings/provider.dart';
import 'provider.dart';
import 'widgets/account_scope_chips.dart';
import 'widgets/stats_hero_card.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  int _touchedIndex = -1;
  bool _showIncome = false;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final summary = ref.watch(statsSummaryProvider);
    final data = _showIncome
        ? ref.watch(categoryIncomeProvider)
        : ref.watch(categoryExpenseProvider);
    final total = data.values.fold(0.0, (a, b) => a + b);
    final currencyInfo = ref.watch(statsCurrencyProvider);
    final timeFilter = ref.watch(timeFilterProvider);
    final monthlyData = _showIncome
        ? ref.watch(monthlyIncomeBreakdownProvider)
        : ref.watch(monthlyBreakdownProvider);
    final scopeLabel = _scopeLabel(s);

    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topEntry = sortedEntries.isEmpty ? null : sortedEntries.first;

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
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            const AccountScopeChips(),
            const SizedBox(height: 16),
            _FilterCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _TimeFilterChip(
                          label: s.filterAllTime,
                          isSelected: timeFilter == TimeFilter.allTime,
                          onTap: () {
                            HapticService.selection();
                            ref.read(timeFilterProvider.notifier).set(TimeFilter.allTime);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TimeFilterChip(
                          label: s.filterMonth,
                          isSelected: timeFilter == TimeFilter.lastMonth,
                          onTap: () {
                            HapticService.selection();
                            ref.read(timeFilterProvider.notifier).set(TimeFilter.lastMonth);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _TypeSegment(
                          label: s.expenses,
                          isSelected: !_showIncome,
                          color: AppColors.expense,
                          onTap: () {
                            HapticService.selection();
                            setState(() {
                              _showIncome = false;
                              _touchedIndex = -1;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TypeSegment(
                          label: s.income,
                          isSelected: _showIncome,
                          color: AppColors.income,
                          onTap: () {
                            HapticService.selection();
                            setState(() {
                              _showIncome = true;
                              _touchedIndex = -1;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            StatsHeroCard(
              amount: _showIncome ? summary.income : summary.expense,
              label: _showIncome ? s.income.toUpperCase() : s.expenses.toUpperCase(),
              accentColor: _showIncome ? AppColors.income : AppColors.expense,
              scopeLabel: scopeLabel,
            ),
            const SizedBox(height: 16),
            _InsightCard(
              title: s.overview,
              subtitle: s.analyticsInsight,
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.55,
                children: [
                  _MetricTile(
                    label: s.income,
                    value: summary.income,
                    currencyInfo: currencyInfo,
                    color: AppColors.income,
                    icon: Icons.south_west_rounded,
                  ),
                  _MetricTile(
                    label: s.expenses,
                    value: summary.expense,
                    currencyInfo: currencyInfo,
                    color: AppColors.expense,
                    icon: Icons.north_east_rounded,
                  ),
                  _MetricTile(
                    label: s.netBalance,
                    value: summary.balance,
                    currencyInfo: currencyInfo,
                    color: summary.balance >= 0 ? AppColors.accent : AppColors.warning,
                    icon: Icons.account_balance_wallet_rounded,
                  ),
                  _CountTile(
                    label: s.transactionsCount,
                    value: summary.transactionCount,
                    color: AppColors.accent,
                    icon: Icons.receipt_long_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _InsightCard(
              title: s.monthlyTrend,
              subtitle: s.lastSixMonths,
              child: _MonthlyTrendSection(
                data: monthlyData,
                color: _showIncome ? AppColors.income : AppColors.expense,
              ),
            ),
            const SizedBox(height: 16),
            if (data.isEmpty)
              _EmptyState(isIncome: _showIncome)
            else ...[
              _InsightCard(
                title: s.expenseStructure,
                subtitle: s.thisPeriod,
                child: _PieChartSection(
                  data: data,
                  total: total,
                  touchedIndex: _touchedIndex,
                  onTouch: (i) => setState(() => _touchedIndex = i),
                  currencyInfo: currencyInfo,
                  isIncome: _showIncome,
                ),
              ),
              const SizedBox(height: 16),
              _InsightCard(
                title: s.topCategories,
                subtitle: topEntry == null
                    ? s.rankedByAmount
                    : '${s.topCategory}: ${s.categoryLabel(topEntry.key)}',
                child: Column(
                  children: [
                    _SummaryBadgeRow(
                      isIncome: _showIncome,
                      currencyInfo: currencyInfo,
                      topEntry: topEntry,
                      total: total,
                    ),
                    const SizedBox(height: 14),
                    ...sortedEntries.map((entry) {
                      final cat = entry.key;
                      final amount = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CategoryItem(
                          category: cat,
                          amount: amount,
                          total: total,
                          currencyInfo: currencyInfo,
                          isIncome: _showIncome,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _scopeLabel(AppStrings s) {
    final activeAccount = ref.watch(activeAccountProvider);
    return activeAccount?.name ?? s.allAccounts;
  }
}

class _FilterCard extends StatelessWidget {
  final Widget child;

  const _FilterCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
        ),
      ),
      child: child,
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _InsightCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _TimeFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.accent
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
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

class _TypeSegment extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeSegment({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
          ),
        ),
      ),
    );
  }
}

class _PieChartSection extends ConsumerWidget {
  final Map<String, double> data;
  final double total;
  final int touchedIndex;
  final ValueChanged<int> onTouch;
  final CurrencyInfo currencyInfo;
  final bool isIncome;

  const _PieChartSection({
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
    final accent = isIncome ? AppColors.income : AppColors.expense;
    final selectedIndex = touchedIndex >= 0 ? touchedIndex : 0;
    final selectedEntry = entries[selectedIndex.clamp(0, entries.length - 1)];
    final selectedAmount = selectedEntry.value;

    return Column(
      children: [
        SizedBox(
          height: 260,
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
                  sectionsSpace: 4,
                  centerSpaceRadius: 78,
                  sections: List.generate(entries.length, (i) {
                    final isTouched = i == touchedIndex;
                    final cat = entries[i].key;
                    final val = entries[i].value;
                    final color = AppCategories.colors[cat] ?? AppColors.accent;
                    return PieChartSectionData(
                      color: color,
                      value: val,
                      title: isTouched
                          ? '${(val / total * 100).toStringAsFixed(0)}%'
                          : '',
                      radius: isTouched ? 60 : 52,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    );
                  }),
                ),
              ),
              Container(
                width: 136,
                height: 136,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      s.total,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _FormattedAmount(
                      amount: total,
                      currencyInfo: currencyInfo,
                      color: accent,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      format: fmt,
                      center: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: (AppCategories.colors[selectedEntry.key] ?? accent).withOpacity(0.10),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppCategories.colors[selectedEntry.key] ?? accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.categoryLabel(selectedEntry.key),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${(selectedAmount / total * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthlyTrendSection extends StatelessWidget {
  final List<MonthlyData> data;
  final Color color;

  const _MonthlyTrendSection({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode == 'ru'
        ? 'ru_RU'
        : 'en_US';
    final maxY = data.isEmpty
        ? 1.0
        : data.map((item) => item.amount).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY == 0 ? 1 : maxY * 1.25,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY == 0 ? 1 : (maxY * 1.25) / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('MMM', locale).format(data[index].month),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(data.length, (index) {
            final amount = data[index].amount;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: amount,
                  width: 18,
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [color.withOpacity(0.65), color],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _CategoryItem extends ConsumerWidget {
  final String category;
  final double amount;
  final double total;
  final CurrencyInfo currencyInfo;
  final bool isIncome;

  const _CategoryItem({
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
    final color = AppCategories.colors[category] ?? AppColors.accent;
    final icon = AppCategories.icons[category] ?? Icons.category_rounded;
    final pct = total > 0 ? amount / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.categoryLabel(category),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(pct * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _FormattedAmount(
                amount: amount,
                currencyInfo: currencyInfo,
                color: isIncome ? AppColors.income : AppColors.expense,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                format: fmt,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: pct,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryBadgeRow extends ConsumerWidget {
  final bool isIncome;
  final CurrencyInfo currencyInfo;
  final MapEntry<String, double>? topEntry;
  final double total;

  const _SummaryBadgeRow({
    required this.isIncome,
    required this.currencyInfo,
    required this.topEntry,
    required this.total,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final summary = ref.watch(statsSummaryProvider);
    final fmt = ref.watch(amountFormatProvider);
    final average = isIncome ? summary.averageIncome : summary.averageExpense;
    final share = topEntry == null || total == 0 ? 0.0 : topEntry!.value / total;

    return Row(
      children: [
        Expanded(
          child: _MiniBadge(
            title: isIncome ? s.averageIncome : s.averageExpense,
            child: _FormattedAmount(
              amount: average,
              currencyInfo: currencyInfo,
              color: isIncome ? AppColors.income : AppColors.expense,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              format: fmt,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniBadge(
            title: s.shareOfTotal,
            child: Text(
              '${(share * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String title;
  final Widget child;

  const _MiniBadge({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.55),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _FormattedAmount extends StatelessWidget {
  final double amount;
  final CurrencyInfo currencyInfo;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;
  final AmountFormat format;
  final bool center;

  const _FormattedAmount({
    required this.amount,
    required this.currencyInfo,
    required this.color,
    required this.fontSize,
    required this.fontWeight,
    required this.format,
    this.center = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      formatAmount(currencyInfo.code == 'BYN' ? '' : currencyInfo.symbol, amount, format),
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (currencyInfo.code != 'BYN') {
      return text;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: center ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        BynSign(fontSize: fontSize, color: color),
        const SizedBox(width: 2),
        Flexible(child: text),
      ],
    );
  }
}

class _MetricTile extends ConsumerWidget {
  final String label;
  final double value;
  final CurrencyInfo currencyInfo;
  final Color color;
  final IconData icon;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.currencyInfo,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = ref.watch(amountFormatProvider);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.55),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          _FormattedAmount(
            amount: value,
            currencyInfo: currencyInfo,
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            format: fmt,
          ),
        ],
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _CountTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.55),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            value.toString(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 15,
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (_isIncomeColor(isIncome) ? AppColors.income : AppColors.expense)
                  .withOpacity(0.12),
            ),
            child: Icon(
              Icons.analytics_rounded,
              size: 34,
              color: _isIncomeColor(isIncome) ? AppColors.income : AppColors.expense,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            s.noStatisticsYet,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.statisticsWillAppear,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  bool _isIncomeColor(bool isIncome) {
    return isIncome;
  }
}
