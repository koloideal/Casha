import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../core/constants.dart';
import '../../shared/models/transaction.dart';
import '../../shared/utils/currency_utils.dart';
import '../../shared/providers/amount_format_provider.dart';
import '../settings/provider.dart';
import 'provider.dart';

// Helper for balance card only - hides .00 decimals
String _smartBalance(double amount, AmountFormat fmt, String symbol) {
  const spaceAfter = {'Br'};
  final sep = spaceAfter.contains(symbol) ? ' ' : '';
  final isWhole = amount == amount.floorToDouble();

  String formatted;
  if (isWhole) {
    // format the integer, then manually remove .00
    formatted = fmt.format(amount);
    if (formatted.endsWith('.00')) {
      formatted = formatted.substring(0, formatted.length - 3);
    }
  } else {
    formatted = fmt.format(amount);
  }
  return '$symbol$sep$formatted';
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _searchFocusNode = FocusNode();

  Border? _themeBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? null : Border.all(color: const Color(0xFFDDDDEE), width: 1);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _scrollToSearch() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      400.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(totalBalanceProvider);
    final income = ref.watch(totalIncomeProvider);
    final expense = ref.watch(totalExpenseProvider);
    final monthExpense = ref.watch(currentMonthExpenseProvider);
    final budget = ref.watch(budgetProvider);
    final recent = ref.watch(recentTransactionsProvider);
    final filter = ref.watch(transactionFilterProvider);
    final currencyInfo = ref.watch(currencyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Finances',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(DateTime.now()),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add'),
        backgroundColor: const Color(0xFF7C6DED),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          cacheExtent: 300,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BalanceCard(balance: balance, currencyInfo: currencyInfo),
                    const SizedBox(height: 16),
                    _SummaryRow(
                      income: income,
                      expense: expense,
                      currencyInfo: currencyInfo,
                    ),
                    if (budget != null) ...[
                      const SizedBox(height: 16),
                      _BudgetProgress(
                        spent: monthExpense,
                        budget: budget,
                        currencyInfo: currencyInfo,
                      ),
                    ],
                    const SizedBox(height: 24),
                    _SearchBar(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onTap: _scrollToSearch,
                      ref: ref,
                    ),
                    const SizedBox(height: 12),
                    _FilterChips(selected: filter, ref: ref),
                    const SizedBox(height: 20),
                    Text(
                      'Transactions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (recent.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList.builder(
                  itemCount: recent.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: RepaintBoundary(
                      child: _TransactionTile(transaction: recent[i]),
                    ),
                  ),
                ),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onTap;
  final WidgetRef ref;
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onTap,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: 'Search transactions...',
        prefixIcon: Icon(
          Icons.search_rounded,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 20),
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                onPressed: () {
                  controller.clear();
                  ref.read(searchQueryProvider.notifier).state = '';
                },
              )
            : null,
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.transparent : const Color(0xFFCCCCDD),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7C6DED), width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
    );
  }
}

class _FilterChips extends StatelessWidget {
  final TransactionFilter selected;
  final WidgetRef ref;
  const _FilterChips({required this.selected, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterChip(
          label: 'All',
          isSelected: selected == TransactionFilter.all,
          onTap: () => ref.read(transactionFilterProvider.notifier).state =
              TransactionFilter.all,
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'Income',
          isSelected: selected == TransactionFilter.income,
          color: AppColors.income,
          onTap: () => ref.read(transactionFilterProvider.notifier).state =
              TransactionFilter.income,
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'Expense',
          isSelected: selected == TransactionFilter.expense,
          color: AppColors.expense,
          onTap: () => ref.read(transactionFilterProvider.notifier).state =
              TransactionFilter.expense,
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.accent;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withOpacity(0.2)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: chipColor, width: 1.5)
              : (isDark
                    ? null
                    : Border.all(color: const Color(0xFFDDDDEE), width: 1)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isSelected
                ? chipColor
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _BudgetProgress extends ConsumerWidget {
  final double spent;
  final double budget;
  final CurrencyInfo currencyInfo;
  const _BudgetProgress({
    required this.spent,
    required this.budget,
    required this.currencyInfo,
  });

  Border? _themeBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? null : Border.all(color: const Color(0xFFDDDDEE), width: 1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = ref.watch(amountFormatProvider);
    final progress = budget > 0 ? spent / budget : 0.0;
    final isOver = progress > 1.0;
    final displayPercent = (progress * 100).toStringAsFixed(0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            left: BorderSide(
              color: isOver ? const Color(0xFFE05C6B) : const Color(0xFF7C6DED),
              width: 3,
            ),
            top: _themeBorder(context)?.top ?? BorderSide.none,
            right: _themeBorder(context)?.right ?? BorderSide.none,
            bottom: _themeBorder(context)?.bottom ?? BorderSide.none,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Monthly Budget',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Text(
                  '$displayPercent%',
                  style: TextStyle(
                    color: isOver
                        ? const Color(0xFFE05C6B)
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: isOver ? FontWeight.w700 : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: isOver ? 1.0 : progress,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOver
                      ? const Color(0xFFE05C6B)
                      : (progress > 0.8
                            ? Colors.orange
                            : const Color(0xFF4CAF8C)),
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spent: ${formatAmount(currencyInfo.symbol, spent, fmt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Text(
                  'Limit: ${formatAmount(currencyInfo.symbol, budget, fmt)}',
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
      ),
    );
  }
}

class _BalanceCard extends ConsumerStatefulWidget {
  final double balance;
  final CurrencyInfo currencyInfo;
  const _BalanceCard({required this.balance, required this.currencyInfo});

  @override
  ConsumerState<_BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends ConsumerState<_BalanceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _tiltX = 0.0, _tiltY = 0.0;
  double _targetTiltX = 0.0, _targetTiltY = 0.0;
  StreamSubscription<AccelerometerEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _sub =
        accelerometerEventStream(
          samplingPeriod: const Duration(milliseconds: 50),
        ).listen((e) {
          _targetTiltY = (e.x / 9.8).clamp(-1.0, 1.0);
          _targetTiltX = ((e.y / 9.8) - 1.0).clamp(-1.0, 1.0);
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rates = ref.read(exchangeRateServiceProvider);
    final fmt = ref.watch(amountFormatProvider);
    final allCurrencies = [
      ('USD', r'$'),
      ('EUR', '€'),
      ('BYN', 'Br'),
      ('RUB', '₽'),
    ];
    final others = allCurrencies
        .where((c) => c.$1 != widget.currencyInfo.code)
        .toList();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        _tiltX += (_targetTiltX - _tiltX) * 0.15;
        _tiltY += (_targetTiltY - _tiltY) * 0.15;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        final tiltBrightness = (_tiltX * 0.15 + _tiltY * 0.1).clamp(
          -0.15,
          0.15,
        );
        final highlightShift = (tiltBrightness * 40).round();

        final topColor = isDark
            ? Color.fromARGB(
                255,
                (0x7C + highlightShift).clamp(0x60, 0xFF),
                (0x6D + highlightShift).clamp(0x55, 0xFF),
                0xED,
              )
            : Color.fromARGB(
                255,
                (0x2A + highlightShift).clamp(0x20, 0x40),
                (0x25 + highlightShift).clamp(0x1A, 0x35),
                (0x45 + highlightShift).clamp(0x35, 0x55),
              );
        final bottomColor = isDark
            ? Color.fromARGB(
                255,
                (0x2A - highlightShift).clamp(0x18, 0x40),
                (0x20 - highlightShift).clamp(0x14, 0x30),
                (0x60 - highlightShift).clamp(0x45, 0x75),
              )
            : Color.fromARGB(
                255,
                (0x14 - highlightShift).clamp(0x0A, 0x20),
                (0x12 - highlightShift).clamp(0x08, 0x1E),
                (0x28 - highlightShift).clamp(0x1E, 0x34),
              );

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(_tiltX * 0.42)
            ..rotateY(_tiltY * 0.42),
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: const Alignment(-1.0, -1.0),
                end: const Alignment(1.0, 1.0),
                colors: [
                  topColor,
                  isDark ? const Color(0xFF4A3FA0) : const Color(0xFF1A1530),
                  bottomColor,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'TOTAL BALANCE',
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 1.5,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.center,
                            child: Text(
                              _smartBalance(
                                widget.balance,
                                fmt,
                                widget.currencyInfo.symbol,
                              ),
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.balance != 0) ...[
                      const SizedBox(width: 16),
                      Container(
                        width: 1,
                        height: 70,
                        color: Colors.white.withOpacity(0.15),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 110,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: others.map((c) {
                            final converted = rates.convert(
                              widget.balance,
                              widget.currencyInfo.code,
                              c.$1,
                            );
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _smartBalance(converted, fmt, c.$2),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.65),
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final double income;
  final double expense;
  final CurrencyInfo currencyInfo;
  const _SummaryRow({
    required this.income,
    required this.expense,
    required this.currencyInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Income',
            amount: income,
            color: AppColors.income,
            icon: Icons.arrow_downward_rounded,
            currencyInfo: currencyInfo,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Expenses',
            amount: expense,
            color: AppColors.expense,
            icon: Icons.arrow_upward_rounded,
            currencyInfo: currencyInfo,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends ConsumerWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final CurrencyInfo currencyInfo;
  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    required this.currencyInfo,
  });

  Border? _themeBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? null : Border.all(color: const Color(0xFFDDDDEE), width: 1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = ref.watch(amountFormatProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: _themeBorder(context),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatAmount(currencyInfo.symbol, amount, fmt),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  final Transaction transaction;
  const _TransactionTile({required this.transaction});

  Border? _themeBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? null : Border.all(color: const Color(0xFFDDDDEE), width: 1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = ref.watch(amountFormatProvider);
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? AppColors.income : AppColors.expense;
    final catColor =
        AppCategories.colors[transaction.category] ?? AppColors.accent;
    final catIcon =
        AppCategories.icons[transaction.category] ?? Icons.category_rounded;

    return GestureDetector(
      onTap: () => context.push('/add', extra: transaction),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: _themeBorder(context),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(catIcon, color: catColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.category,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (transaction.note != null && transaction.note!.isNotEmpty)
                    Text(
                      transaction.note!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      DateFormat('MMM d, yyyy').format(transaction.date),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+ ' : '- '}${formatAmount(transaction.currency, transaction.amount, fmt)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
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
              Icons.receipt_long_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + to add your first transaction',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
