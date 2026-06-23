import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final data = _showIncome
        ? ref.watch(categoryIncomeProvider)
        : ref.watch(categoryExpenseProvider);
    final total = data.values.fold(0.0, (a, b) => a + b);
    final currencyInfo = ref.watch(statsCurrencyProvider);
    final timeFilter = ref.watch(timeFilterProvider);

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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AccountScopeChips(),
              const SizedBox(height: 16),
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
                  const SizedBox(width: 8),
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _TypeSegment(
                      label: s.expenses,
                      isSelected: !_showIncome,
                      onTap: () {
                        HapticService.selection();
                        setState(() {
                          _showIncome = false;
                          _touchedIndex = -1;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TypeSegment(
                      label: s.income,
                      isSelected: _showIncome,
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
              const SizedBox(height: 20),
              if (data.isEmpty)
                Expanded(child: _EmptyState(isIncome: _showIncome))
              else
                Expanded(
                  child: ListView(
                    children: [
                      _PieChartSection(
                        data: data,
                        total: total,
                        touchedIndex: _touchedIndex,
                        onTouch: (i) => setState(() => _touchedIndex = i),
                        currencyInfo: currencyInfo,
                        isIncome: _showIncome,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        s.rankedByAmount,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 16),
                      ...sortedEntries.map((entry) {
                        final cat = entry.key;
                        final amount = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _CategoryItem(
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
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
  final VoidCallback onTap;

  const _TypeSegment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (_showIncomeColor(label) ? AppColors.income : AppColors.expense)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
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

  bool _showIncomeColor(String label) {
    final lower = label.toLowerCase();
    return lower.contains('income') || lower.contains('доход');
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

    return SizedBox(
      height: 240,
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
              sectionsSpace: 2,
              centerSpaceRadius: 70,
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
                      ? '${(val / total * 100).toStringAsFixed(0)}%'
                      : '',
                  radius: isTouched ? 55 : 48,
                  titleStyle: const TextStyle(
                    fontSize: 12,
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
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              currencyInfo.code == 'BYN'
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        BynSign(
                          fontSize: 24,
                          color: accent,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          formatAmount('', total, fmt),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      formatAmount(currencyInfo.symbol, total, fmt),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                      ),
                    ),
            ],
          ),
        ],
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

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
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
                  fontWeight: FontWeight.w600,
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
        currencyInfo.code == 'BYN'
            ? Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  BynSign(
                    fontSize: 15,
                    color: isIncome ? AppColors.income : AppColors.expense,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    formatAmount('', amount, fmt),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isIncome ? AppColors.income : AppColors.expense,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : Text(
                formatAmount(currencyInfo.symbol, amount, fmt),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isIncome ? AppColors.income : AppColors.expense,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ],
    );
  }
}

class _EmptyState extends ConsumerWidget {
  final bool isIncome;
  const _EmptyState({required this.isIncome});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline_rounded,
            size: 56,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            isIncome ? s.noIncomeData : s.noExpenseData,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isIncome ? s.addIncomeToSeeBreakdown : s.addExpensesToSeeBreakdown,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}
