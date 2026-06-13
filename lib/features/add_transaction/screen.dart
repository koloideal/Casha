import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/services/haptic_service.dart';
import '../../shared/models/account.dart';
import '../../shared/models/transaction.dart';
import '../dashboard/provider.dart';
import '../settings/provider.dart';
import 'provider.dart';
import 'widgets/account_row.dart';
import 'widgets/account_selector.dart';
import 'widgets/amount_input.dart';
import 'widgets/category_picker.dart';
import 'widgets/currency_picker.dart';
import 'widgets/date_time_pickers.dart';
import 'widgets/note_field.dart';
import 'widgets/section_label.dart';
import 'widgets/submit_button.dart';
import 'widgets/type_toggle.dart';

const _uuid = Uuid();

class AddTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? initial;

  const AddTransactionScreen({super.key, this.initial});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _stackKey = GlobalKey();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _fromAccountIndicatorKey = GlobalKey();
  final _toAccountIndicatorKey = GlobalKey();
  late AnimationController _shakeController;
  late Animation<Color?> _borderColorAnimation;
  bool _showError = false;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _showFromAccountDropdown = false;
  bool _showToAccountDropdown = false;
  String? _toAccountError;
  String? _fromAccountError;
  String? _transferExpenseRecordId;
  String? _transferIncomeRecordId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = widget.initial?.date ?? now;
    _selectedTime = widget.initial != null
        ? TimeOfDay.fromDateTime(widget.initial!.date)
        : TimeOfDay(hour: now.hour, minute: now.minute);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
    _borderColorAnimation = ColorTween(
      begin: const Color(0xFFE05C6B),
      end: Colors.transparent,
    ).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeOut));
    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) setState(() => _showError = false);
      }
    });
    if (widget.initial != null) {
      _amountController.text = widget.initial!.amount.toString();
      _noteController.text = widget.initial!.note ?? '';

      if (widget.initial!.category == 'Transfer') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final allTxs = ref.read(transactionsProvider).value ?? [];

          if (widget.initial!.type == TransactionType.expense) {
            final counterpart = allTxs.firstWhereOrNull(
              (t) =>
                  t.id != widget.initial!.id &&
                  t.category == 'Transfer' &&
                  t.type == TransactionType.income &&
                  t.amount == widget.initial!.amount &&
                  t.date.year == widget.initial!.date.year &&
                  t.date.month == widget.initial!.date.month &&
                  t.date.day == widget.initial!.date.day &&
                  t.date.hour == widget.initial!.date.hour &&
                  t.date.minute == widget.initial!.date.minute &&
                  t.note == widget.initial!.note,
            );
            if (counterpart != null) {
              ref
                  .read(addTransactionProvider(widget.initial).notifier)
                  .setToAccountId(counterpart.accountId);
            }
            setState(() {
              _transferExpenseRecordId = widget.initial!.id;
              _transferIncomeRecordId = counterpart?.id;
            });
          } else {
            final expenseRecord = allTxs.firstWhereOrNull(
              (t) =>
                  t.id != widget.initial!.id &&
                  t.category == 'Transfer' &&
                  t.type == TransactionType.expense &&
                  t.amount == widget.initial!.amount &&
                  t.date.year == widget.initial!.date.year &&
                  t.date.month == widget.initial!.date.month &&
                  t.date.day == widget.initial!.date.day &&
                  t.date.hour == widget.initial!.date.hour &&
                  t.date.minute == widget.initial!.date.minute &&
                  t.note == widget.initial!.note,
            );
            if (expenseRecord != null) {
              ref
                  .read(addTransactionProvider(widget.initial).notifier)
                  .setAccountId(expenseRecord.accountId);
              ref
                  .read(addTransactionProvider(widget.initial).notifier)
                  .setToAccountId(widget.initial!.accountId);
            }
            setState(() {
              _transferExpenseRecordId = expenseRecord?.id;
              _transferIncomeRecordId = widget.initial!.id;
            });
          }
        });
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final activeAccount = ref.read(activeAccountProvider);
        final curr = ref.read(currencyProvider);

        final currencyCode = activeAccount?.currency ?? curr.code;
        final currencySymbol = currencyMap[currencyCode]?.symbol ?? curr.symbol;

        ref
            .read(addTransactionProvider(null).notifier)
            .setCurrency(currencySymbol, currencyCode);

        if (activeAccount != null) {
          ref
              .read(addTransactionProvider(null).notifier)
              .setAccountId(activeAccount.id);
        }
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  String? _validateAndParseAmount(String raw) {
    final trimmed = raw.trim();

    if (trimmed.isEmpty) return null;

    final normalized = trimmed.replaceAll(',', '.');

    final validPattern = RegExp(r'^\d+\.?\d*$');
    if (!validPattern.hasMatch(normalized)) return null;

    final value = double.tryParse(normalized);
    if (value == null) return null;

    if (value <= 0) return null;

    if (value > 999_999_999) return null;

    final parts = normalized.split('.');
    if (parts.length == 2 && parts[1].length > 2) return null;

    return normalized;
  }

  void _triggerError() {
    setState(() => _showError = true);
    _shakeController.forward(from: 0);
  }

  Future<void> _submit() async {
    final s = ref.read(stringsProvider);
    final raw = _amountController.text;
    final parsed = _validateAndParseAmount(raw);

    if (parsed == null) {
      _triggerError();
      return;
    }

    final amount = double.parse(parsed);
    final state = ref.read(addTransactionProvider(widget.initial));

    if (state.type == TransactionType.transfer) {
      bool hasError = false;

      if (state.selectedAccountId == null) {
        setState(() => _fromAccountError = s.selectSourceAccount);
        hasError = true;
      } else {
        setState(() => _fromAccountError = null);
      }

      if (state.toAccountId == null) {
        setState(() => _toAccountError = s.selectDestAccount);
        hasError = true;
      } else if (state.toAccountId == state.selectedAccountId) {
        setState(() => _toAccountError = s.accountsMustDiffer);
        hasError = true;
      } else {
        setState(() => _toAccountError = null);
      }

      if (hasError) return;
    }

    final finalDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    ref.read(addTransactionProvider(widget.initial).notifier).setAmount(amount);
    ref
        .read(addTransactionProvider(widget.initial).notifier)
        .setDate(finalDateTime);
    ref
        .read(addTransactionProvider(widget.initial).notifier)
        .setSubmitting(true);

    final note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();

    try {
      if (state.type == TransactionType.transfer) {
        final curr = ref.read(currencyProvider);
        final currency = state.overrideCurrency.isNotEmpty
            ? state.overrideCurrency
            : curr.symbol;
        final currencyCode = state.overrideCurrencyCode.isNotEmpty
            ? state.overrideCurrencyCode
            : curr.code;

        if (state.isEditing) {
          final updatedExpense = Transaction(
            id: _transferExpenseRecordId ?? widget.initial!.id,
            amount: amount,
            category: 'Transfer',
            type: TransactionType.expense,
            date: finalDateTime,
            note: note,
            currency: currency,
            currencyCode: currencyCode,
            accountId: state.selectedAccountId!,
          );
          await ref.read(transactionsProvider.notifier).updateTransaction(updatedExpense);

          if (_transferIncomeRecordId != null) {
            final updatedIncome = Transaction(
              id: _transferIncomeRecordId!,
              amount: amount,
              category: 'Transfer',
              type: TransactionType.income,
              date: finalDateTime,
              note: note,
              currency: currency,
              currencyCode: currencyCode,
              accountId: state.toAccountId!,
            );
            await ref.read(transactionsProvider.notifier).updateTransaction(updatedIncome);
          }

          if (mounted) context.pop();
          return;
        }

        final expense = Transaction(
          id: _uuid.v4(),
          amount: amount,
          category: 'Transfer',
          type: TransactionType.expense,
          date: finalDateTime,
          note: note,
          currency: currency,
          currencyCode: currencyCode,
          accountId: state.selectedAccountId!,
        );

        final income = Transaction(
          id: _uuid.v4(),
          amount: amount,
          category: 'Transfer',
          type: TransactionType.income,
          date: finalDateTime,
          note: note,
          currency: currency,
          currencyCode: currencyCode,
          accountId: state.toAccountId!,
        );

        await ref.read(transactionsProvider.notifier).add(expense);
        await ref.read(transactionsProvider.notifier).add(income);
      } else {
        final activeAccount = ref.read(activeAccountProvider);
        final selectedId = ref
            .read(addTransactionProvider(widget.initial))
            .selectedAccountId;
        int accountId;

        if (selectedId != null && selectedId != 0) {
          accountId = selectedId;
        } else if (activeAccount != null) {
          accountId = activeAccount.id;
        } else {
          final mainAccount = await ref
              .read(accountRepositoryProvider)
              .getMain();
          accountId = mainAccount.id;
        }

        final tx = Transaction(
          id: state.editingId ?? _uuid.v4(),
          amount: amount,
          category: state.category,
          type: state.type,
          date: finalDateTime,
          note: note,
          currency: state.overrideCurrency,
          currencyCode: state.overrideCurrencyCode,
          accountId: accountId,
        );

        if (state.isEditing) {
          await ref.read(transactionsProvider.notifier).updateTransaction(tx);
        } else {
          final res = await ref.read(transactionsProvider.notifier).add(tx);

          if (res.isFailure) {
            throw Exception(res.errorOrNull);
          }
        }
      }

      HapticService.medium();

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${s.saveError}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      ref
          .read(addTransactionProvider(widget.initial).notifier)
          .setSubmitting(false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: AppColors.accent),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          timePickerTheme: TimePickerThemeData(
            backgroundColor: Theme.of(context).colorScheme.surface,
            hourMinuteShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            dayPeriodShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: const Color(0xFF7C6DED)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final state = ref.watch(addTransactionProvider(widget.initial));
    final categories = ref.watch(availableCategoriesProvider(widget.initial));
    final overrideCurrency = state.overrideCurrency;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = state.isEditing;
    final activeAccount = ref.watch(activeAccountProvider);
    final isTransfer = state.type == TransactionType.transfer;
    final isEditingTransfer = isEditing && isTransfer;
    final isFromAccountLocked = activeAccount != null || isEditingTransfer;
    final isToAccountLocked = isEditingTransfer;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(state.isEditing ? s.editTransaction : s.addTransaction),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (state.isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              color: const Color(0xFFE05C6B),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(s.confirmDelete),
                    content: Text(s.confirmDeleteBody),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(s.cancel),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(ctx);

                          await ref
                              .read(transactionsProvider.notifier)
                              .delete(widget.initial!.id);

                          if (widget.initial!.category == 'Transfer') {
                            final counterpartId =
                                widget.initial!.type == TransactionType.expense
                                ? _transferIncomeRecordId
                                : _transferExpenseRecordId;

                            if (counterpartId != null) {
                              await ref
                                  .read(transactionsProvider.notifier)
                                  .delete(counterpartId);
                            } else {
                              final allTxs =
                                  ref.read(transactionsProvider).value ??
                                  [];
                              final oppositeType =
                                  widget.initial!.type ==
                                      TransactionType.expense
                                  ? TransactionType.income
                                  : TransactionType.expense;
                              final counterpart = allTxs.firstWhereOrNull(
                                (t) =>
                                    t.id != widget.initial!.id &&
                                    t.category == 'Transfer' &&
                                    t.type == oppositeType &&
                                    t.amount == widget.initial!.amount &&
                                    t.date.year == widget.initial!.date.year &&
                                    t.date.month ==
                                        widget.initial!.date.month &&
                                    t.date.day == widget.initial!.date.day &&
                                    t.date.hour == widget.initial!.date.hour &&
                                    t.date.minute ==
                                        widget.initial!.date.minute &&
                                    t.note == widget.initial!.note,
                              );
                              if (counterpart != null) {
                                await ref
                                    .read(transactionsProvider.notifier)
                                    .delete(counterpart.id);
                              }
                            }
                          }

                          if (mounted) context.pop();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFE05C6B),
                        ),
                        child: Text(s.delete),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Stack(
            key: _stackKey,
            children: [
              ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  IgnorePointer(
                    ignoring: isEditing,
                    child: TypeToggle(
                      selected: state.type,
                      onChanged: (type) => ref
                          .read(addTransactionProvider(widget.initial).notifier)
                          .setType(type),
                      isDark: isDark,
                      isEditing: isEditing,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (isTransfer)
                    AccountRow(
                      initial: widget.initial,
                      showFromDropdown: _showFromAccountDropdown,
                      showToDropdown: _showToAccountDropdown,
                      onToggleFromDropdown: () => setState(() {
                        _showFromAccountDropdown = !_showFromAccountDropdown;
                        _fromAccountError = null;
                      }),
                      onToggleToDropdown: () => setState(() {
                        _showToAccountDropdown = !_showToAccountDropdown;
                        _toAccountError = null;
                      }),
                      fromIndicatorKey: _fromAccountIndicatorKey,
                      toIndicatorKey: _toAccountIndicatorKey,
                      fromAccountError: _fromAccountError,
                      toAccountError: _toAccountError,
                      isDark: isDark,
                      isFromAccountLocked: isFromAccountLocked,
                      isToAccountLocked: isToAccountLocked,
                    ),
                  if (isTransfer) const SizedBox(height: 24),

                  SectionLabel(s.amount),
                  const SizedBox(height: 8),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: AmountInput(
                            controller: _amountController,
                            currencySymbol: overrideCurrency,
                            currencyCode: state.overrideCurrencyCode,
                            showError: _showError,
                            borderColorAnimation: _borderColorAnimation,
                            isDark: isDark,
                            onChanged: (v) {
                              final parsed = double.tryParse(v);
                              ref
                                  .read(
                                    addTransactionProvider(
                                      widget.initial,
                                    ).notifier,
                                  )
                                  .setAmount(parsed);
                            },
                          ),
                        ),
                        if (!isTransfer) ...[
                          const SizedBox(width: 12),
                          _InlineAccountSelector(
                            initial: widget.initial,
                            showDropdown: _showFromAccountDropdown,
                            onToggleDropdown: () => setState(() {
                              _showFromAccountDropdown =
                                  !_showFromAccountDropdown;
                              _fromAccountError = null;
                            }),
                            indicatorKey: _fromAccountIndicatorKey,
                            isDark: isDark,
                            isLocked: isFromAccountLocked,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    s.currency,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CurrencyPicker(
                    selected: state.overrideCurrencyCode,
                    onChanged: (symbol, code) => ref
                        .read(addTransactionProvider(widget.initial).notifier)
                        .setCurrency(symbol, code),
                  ),
                  const SizedBox(height: 20),

                  if (state.type != TransactionType.transfer) ...[
                    SectionLabel(s.category),
                    const SizedBox(height: 8),
                    CategoryPicker(
                      categories: categories,
                      selected: state.category,
                      onChanged: (c) => ref
                          .read(addTransactionProvider(widget.initial).notifier)
                          .setCategory(c),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DatePickerField(
                          selectedDate: _selectedDate,
                          onTap: _pickDate,
                          label: s.date,
                          dateLocale: s.dateLocale,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TimePickerField(
                          selectedTime: _selectedTime,
                          onTap: _pickTime,
                          label: s.time,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  SectionLabel(s.noteOptional),
                  const SizedBox(height: 8),
                  NoteField(
                    controller: _noteController,
                    hintText: s.addNote,
                    isDark: isDark,
                    onChanged: (v) => ref
                        .read(addTransactionProvider(widget.initial).notifier)
                        .setNote(v.trim()),
                  ),
                  const SizedBox(height: 32),

                  SubmitButton(
                    isSubmitting: state.isSubmitting,
                    isEditing: state.isEditing,
                    type: state.type,
                    onPressed: _submit,
                    saveChangesText: s.saveChanges,
                    addTransactionText: s.addTransaction,
                  ),
                ],
              ),
              if (_showFromAccountDropdown)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _showFromAccountDropdown = false),
                    behavior: HitTestBehavior.translucent,
                    child: const SizedBox.expand(),
                  ),
                ),
              if (_showFromAccountDropdown)
                AccountDropdownOverlay(
                  initial: widget.initial,
                  onClose: () =>
                      setState(() => _showFromAccountDropdown = false),
                  triggerKey: _fromAccountIndicatorKey,
                  stackKey: _stackKey,
                ),
              if (_showToAccountDropdown)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() => _showToAccountDropdown = false),
                    behavior: HitTestBehavior.translucent,
                    child: const SizedBox.expand(),
                  ),
                ),
              if (_showToAccountDropdown)
                _ToAccountDropdownOverlay(
                  initial: widget.initial,
                  onClose: () => setState(() => _showToAccountDropdown = false),
                  triggerKey: _toAccountIndicatorKey,
                  stackKey: _stackKey,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineAccountSelector extends ConsumerWidget {
  final Transaction? initial;
  final bool showDropdown;
  final VoidCallback onToggleDropdown;
  final GlobalKey indicatorKey;
  final bool isDark;
  final bool isLocked;

  const _InlineAccountSelector({
    required this.initial,
    required this.showDropdown,
    required this.onToggleDropdown,
    required this.indicatorKey,
    required this.isDark,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final state = ref.watch(addTransactionProvider(initial));
    final activeAccount = ref.watch(activeAccountProvider);

    return accountsAsync.when(
      data: (accounts) {
        final selectedAccountId = state.selectedAccountId;
        final Account? displayAccount;

        if (selectedAccountId != null) {
          displayAccount = accounts.firstWhere(
            (a) => a.id == selectedAccountId,
            orElse: () => accounts.isNotEmpty
                ? accounts.first
                : Account(
                    id: 0,
                    name: '',
                    currency: 'USD',
                    isMain: false,
                    sortOrder: 0,
                    createdAt: DateTime.now(),
                  ),
          );
        } else {
          displayAccount =
              activeAccount ?? (accounts.isNotEmpty ? accounts.first : null);
        }

        return Opacity(
          opacity: isLocked ? 0.7 : 1.0,
          child: IgnorePointer(
            ignoring: isLocked,
            child: GestureDetector(
              onTap: onToggleDropdown,
              child: Container(
                key: indicatorKey,
                constraints: const BoxConstraints(minWidth: 130),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : const Color(0xFFDDDDEE),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 16,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      displayAccount?.name ?? 'Account',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    if (!isLocked) ...[
                      const SizedBox(width: 4),
                      Icon(
                        showDropdown
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        size: 20,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => Container(
        height: 56,
        width: 140,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      error: (_, __) => Container(
        height: 56,
        width: 140,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _ToAccountDropdownOverlay extends ConsumerWidget {
  final Transaction? initial;
  final VoidCallback onClose;
  final GlobalKey? triggerKey;
  final GlobalKey? stackKey;

  const _ToAccountDropdownOverlay({
    required this.initial,
    required this.onClose,
    this.triggerKey,
    this.stackKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final selectedAccountId = ref
        .read(addTransactionProvider(initial))
        .selectedAccountId;
    final toAccountId = ref.read(addTransactionProvider(initial)).toAccountId;

    double top = 340;
    double left = 20;
    double triggerWidth = 200; 

    if (triggerKey?.currentContext != null) {
      final triggerBox =
          triggerKey!.currentContext!.findRenderObject() as RenderBox;
      final triggerOffset = triggerBox.localToGlobal(Offset.zero);
      final triggerSize = triggerBox.size;
      triggerWidth = triggerSize.width;

      double stackDy = 0;
      double stackDx = 0;
      if (stackKey?.currentContext != null) {
        final stackBox =
            stackKey!.currentContext!.findRenderObject() as RenderBox;
        final stackOffset = stackBox.localToGlobal(Offset.zero);
        stackDy = stackOffset.dy;
        stackDx = stackOffset.dx;
      }

      top = triggerOffset.dy - stackDy + triggerSize.height + 4;
      left = triggerOffset.dx - stackDx;
    }

    return Positioned(
      top: top,
      left: left,
      width: triggerWidth,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF7C6DED).withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: accountsAsync.when(
            data: (accounts) {
              final filteredAccounts = accounts
                  .where((a) => a.id != selectedAccountId)
                  .toList();

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: filteredAccounts.map((account) {
                  final isSelected =
                      toAccountId != null && account.id == toAccountId;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      ref
                          .read(addTransactionProvider(initial).notifier)
                          .setToAccountId(account.id);
                      onClose();
                      HapticService.light();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 16,
                            color: isSelected
                                ? const Color(0xFF7C6DED)
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              account.name,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? const Color(0xFF7C6DED)
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Color(0xFF7C6DED),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
