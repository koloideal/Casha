import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/services/card_color_service.dart';
import '../../core/services/haptic_service.dart';
import '../../shared/models/account.dart';
import '../settings/provider.dart';
import 'provider.dart';
import 'widgets/account_editor_overlay/account_editor_overlay.dart';
import 'widgets/balance_card_carousel.dart';
import 'widgets/budget_progress.dart';
import 'widgets/color_editor_overlay.dart';
import 'widgets/filter_chips.dart';
import 'widgets/search_bar.dart' as custom;
import 'widgets/summary_row.dart';
import 'widgets/transaction_tile.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _searchFocusNode = FocusNode();
  bool editingCard = false;
  bool editingPrimary = true;
  Color tempPrimary = CardColorService.defaultPrimary;
  Color tempSecondary = CardColorService.defaultSecondary;
  HSVColor tempPrimaryHSV = HSVColor.fromColor(CardColorService.defaultPrimary);
  HSVColor tempSecondaryHSV = HSVColor.fromColor(
    CardColorService.defaultSecondary,
  );
  Color savedPrimary = CardColorService.defaultPrimary;
  Color savedSecondary = CardColorService.defaultSecondary;
  HSVColor savedPrimaryHSV = HSVColor.fromColor(
    CardColorService.defaultPrimary,
  );
  HSVColor savedSecondaryHSV = HSVColor.fromColor(
    CardColorService.defaultSecondary,
  );
  GradientType tempGradientType = CardColorService.defaultGradient;
  GradientType savedGradientType = CardColorService.defaultGradient;
  OverlayEntry? overlayEntry;

  // Account editing state
  Account? editingAccount;
  String tempAccountName = '';
  String tempAccountCurrency = 'USD';
  bool isAddingAccount = false;

  void _onCardLongPress() {
    final colors = ref.read(cardColorsProvider);
    savedPrimary = colors.primary;
    savedSecondary = colors.secondary;
    savedPrimaryHSV = HSVColor.fromColor(colors.primary);
    savedSecondaryHSV = HSVColor.fromColor(colors.secondary);
    savedGradientType = colors.gradientType;
    tempPrimary = colors.primary;
    tempSecondary = colors.secondary;
    tempPrimaryHSV = HSVColor.fromColor(colors.primary);
    tempSecondaryHSV = HSVColor.fromColor(colors.secondary);
    tempGradientType = colors.gradientType;

    setState(() {
      editingCard = true;
      editingPrimary = true;
    });
    _showOverlay();
  }

  void _showOverlay() {
    overlayEntry = OverlayEntry(
      builder: (overlayContext) =>
          FullScreenBlurOverlay(dashboardState: this, context: context),
    );
    Overlay.of(context, rootOverlay: true).insert(overlayEntry!);
  }

  void closeOverlay({required bool apply}) {
    if (apply) {
      HapticService.medium();
      ref
          .read(cardColorsProvider.notifier)
          .save(tempPrimary, tempSecondary, tempGradientType);
    } else {
      setState(() {
        tempPrimary = savedPrimary;
        tempSecondary = savedSecondary;
        tempGradientType = savedGradientType;
      });
    }
    overlayEntry?.remove();
    overlayEntry = null;
    setState(() => editingCard = false);
  }

  void _onAccountCardLongPress(Account account) {
    final colors = ref.read(accountCardColorsProvider(account.id));
    savedPrimary = colors.primary;
    savedSecondary = colors.secondary;
    savedPrimaryHSV = HSVColor.fromColor(colors.primary);
    savedSecondaryHSV = HSVColor.fromColor(colors.secondary);
    savedGradientType = colors.gradientType;
    tempPrimary = colors.primary;
    tempSecondary = colors.secondary;
    tempPrimaryHSV = HSVColor.fromColor(colors.primary);
    tempSecondaryHSV = HSVColor.fromColor(colors.secondary);
    tempGradientType = colors.gradientType;

    setState(() {
      editingAccount = account;
      tempAccountName = account.name;
      tempAccountCurrency = account.currency;
      editingCard = true;
      editingPrimary = true;
    });
    _showAccountOverlay();
  }

  void _showAccountOverlay() {
    overlayEntry = OverlayEntry(
      builder: (overlayContext) =>
          AccountEditorOverlay(dashboardState: this, context: context),
    );
    Overlay.of(context, rootOverlay: true).insert(overlayEntry!);
  }

  void _onAddAccountTapped() {
    final colors = ref.read(cardColorsProvider);
    savedPrimary = colors.primary;
    savedSecondary = colors.secondary;
    savedPrimaryHSV = HSVColor.fromColor(colors.primary);
    savedSecondaryHSV = HSVColor.fromColor(colors.secondary);
    savedGradientType = colors.gradientType;
    tempPrimary = colors.primary;
    tempSecondary = colors.secondary;
    tempPrimaryHSV = HSVColor.fromColor(colors.primary);
    tempSecondaryHSV = HSVColor.fromColor(colors.secondary);
    tempGradientType = colors.gradientType;

    setState(() {
      isAddingAccount = true;
      editingAccount = null;
      tempAccountName = '';
      tempAccountCurrency = ref.read(currencyProvider).code;
      editingCard = true;
      editingPrimary = true;
    });
    _showAccountOverlay();
  }

  void closeAccountOverlay({required bool apply}) async {
    if (apply && tempAccountName.trim().isNotEmpty) {
      HapticService.medium();

      if (isAddingAccount) {
        final newAccount = Account(
          id: 0,
          name: tempAccountName.trim(),
          isMain: false,
          sortOrder: 99,
          currency: tempAccountCurrency,
          createdAt: DateTime.now(),
        );

        final newId = await ref.read(accountRepositoryProvider).add(newAccount);

        await CardColorService.save(
          tempPrimary,
          tempSecondary,
          tempGradientType,
          accountId: newId,
        );
      } else if (editingAccount != null) {
        // Existing edit logic
        // Save colors
        await ref
            .read(accountCardColorsProvider(editingAccount!.id).notifier)
            .save(tempPrimary, tempSecondary, tempGradientType);

        // Update account name and currency
        final updatedAccount = Account(
          id: editingAccount!.id,
          name: tempAccountName.trim(),
          isMain: editingAccount!.isMain,
          sortOrder: editingAccount!.sortOrder,
          currency: tempAccountCurrency,
          createdAt: editingAccount!.createdAt,
        );

        await ref.read(accountRepositoryProvider).update(updatedAccount);
      }
    } else {
      // Restore original values on cancel
      setState(() {
        tempPrimary = savedPrimary;
        tempSecondary = savedSecondary;
        tempGradientType = savedGradientType;
        if (editingAccount != null) {
          tempAccountName = editingAccount!.name;
          tempAccountCurrency = editingAccount!.currency;
        }
      });
    }

    overlayEntry?.remove();
    overlayEntry = null;
    setState(() {
      editingCard = false;
      editingAccount = null;
      isAddingAccount = false;
    });
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final colors = ref.read(cardColorsProvider);
      tempPrimary = colors.primary;
      tempSecondary = colors.secondary;
    });
  }

  @override
  void dispose() {
    overlayEntry?.remove();
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
    final s = ref.watch(stringsProvider);
    final balance = ref.watch(totalBalanceProvider);
    final income = ref.watch(totalIncomeProvider);
    final expense = ref.watch(totalExpenseProvider);
    final monthExpense = ref.watch(currentMonthExpenseProvider);
    final budget = ref.watch(budgetProvider);
    final recent = ref.watch(recentTransactionsProvider);
    final activeAccount = ref.watch(activeAccountProvider);
    final globalCurrencyInfo = ref.watch(currencyProvider);
    final currencyInfo = activeAccount != null
        ? CurrencyInfo(
            currencyMap[activeAccount.currency]?.symbol ?? '\$',
            activeAccount.currency,
          )
        : globalCurrencyInfo;

    final activeIndex = ref.watch(activeAccountIndexProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final accountCount = accountsAsync.valueOrNull?.length ?? 0;
    final isOnAddAccountPage =
        accountCount < 5 && activeIndex == accountCount + 1;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Text(
          'Casha',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Builder(
                builder: (context) {
                  final raw = DateFormat(
                    'LLLL, yyyy',
                    s.dateLocale,
                  ).format(DateTime.now());
                  final capitalized = raw.isNotEmpty
                      ? '${raw[0].toUpperCase()}${raw.substring(1)}'
                      : raw;
                  return Text(
                    capitalized,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isOnAddAccountPage
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                HapticService.medium();
                context.push('/add');
              },
              backgroundColor: const Color(0xFF7C6DED),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text(
                s.addTransactionDashboard,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
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
                    BalanceCardCarousel(
                      balance: balance,
                      currencyInfo: currencyInfo,
                      onLongPress: _onCardLongPress,
                      onAccountLongPress: _onAccountCardLongPress,
                      onAddAccountTap: _onAddAccountTapped,
                      previewPrimary: editingCard ? tempPrimary : null,
                      previewSecondary: editingCard ? tempSecondary : null,
                      previewGradientType: editingCard
                          ? tempGradientType
                          : null,
                    ),
                    const SizedBox(height: 16),
                    if (!isOnAddAccountPage) ...[
                      SummaryRow(
                        income: income,
                        expense: expense,
                        currencyInfo: currencyInfo,
                        strings: s,
                      ),
                      if (budget != null) ...[
                        const SizedBox(height: 16),
                        BudgetProgress(
                          spent: monthExpense,
                          budget: budget,
                          currencyInfo: currencyInfo,
                          strings: s,
                        ),
                      ],
                      const SizedBox(height: 24),
                      custom.SearchBar(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onTap: _scrollToSearch,
                        ref: ref,
                        strings: s,
                      ),
                      const SizedBox(height: 12),
                      FilterChips(strings: s),
                      const SizedBox(height: 20),
                      Text(
                        s.transactions,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
            if (isOnAddAccountPage) ...[
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: _AccountsInfoBlock()),
              ),
            ] else ...[
              if (recent.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(strings: s),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList.builder(
                    itemCount: recent.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: RepaintBoundary(
                        child: TransactionTile(transaction: recent[i]),
                      ),
                    ),
                  ),
                ),
            ],
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
    );
  }
}

class _AccountsInfoBlock extends ConsumerWidget {
  const _AccountsInfoBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 60), 
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260), 
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 18,
                  color: Color(0xFF7C6DED),
                ),
                const SizedBox(width: 8),
                Text(
                  s.accountsInfoTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(icon: Icons.swap_horiz_rounded, text: s.accountsInfoBalance),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.touch_app_rounded, text: s.accountsInfoCustomize),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.lock_outline_rounded, text: s.accountsInfoLimit),
          ],
        ),
      ),
    );
  }
  }

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: onSurface.withOpacity(0.4)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: onSurface.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }
}
