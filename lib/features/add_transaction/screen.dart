import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/services/haptic_service.dart';
import '../../shared/models/transaction.dart';
import '../dashboard/provider.dart';
import '../settings/provider.dart';
import 'provider.dart';
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
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _accountIndicatorKey = GlobalKey();
  late AnimationController _shakeController;
  late Animation<Color?> _borderColorAnimation;
  bool _showError = false;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _showAccountDropdown = false;

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
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final activeAccount = ref.read(activeAccountProvider);
        final curr = ref.read(currencyProvider);

        // Use active account's currency if available, otherwise use global currency
        final currencyCode = activeAccount?.currency ?? curr.code;
        final currencySymbol = currencyMap[currencyCode]?.symbol ?? curr.symbol;

        ref
            .read(addTransactionProvider(null).notifier)
            .setCurrency(currencySymbol, currencyCode);
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

    return normalized; // valid, return normalized string
  }

  void _triggerError() {
    setState(() => _showError = true);
    _shakeController.forward(from: 0);
  }

  Future<void> _submit() async {
    final raw = _amountController.text;
    final parsed = _validateAndParseAmount(raw);

    if (parsed == null) {
      _triggerError();
      return;
    }

    final amount = double.parse(parsed);
    final state = ref.read(addTransactionProvider(widget.initial));

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
      print('--- SUBMIT CLICKED ---');
      print(
        'Amount: $amount, Category: ${state.category}, Type: ${state.type.name}',
      );

      final activeAccount = ref.read(activeAccountProvider);
      final selectedId = ref
          .read(addTransactionProvider(widget.initial))
          .selectedAccountId;
      int accountId;

      if (selectedId != null && selectedId != 0) {
        print('Using selected account ID: $selectedId');
        accountId = selectedId;
      } else if (activeAccount != null) {
        print(
          'Using active account ID: ${activeAccount.id}, Name: ${activeAccount.name}',
        );
        accountId = activeAccount.id;
      } else {
        print('No active account. Fetching main account...');
        final mainAccount = await ref.read(accountRepositoryProvider).getMain();
        print(
          'Main account fetched: ID=${mainAccount.id}, Name: ${mainAccount.name}',
        );
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

      print('Transaction object created: ID=${tx.id}, AccId=${tx.accountId}');
      print('Calling provider to save...');

      if (state.isEditing) {
        await ref.read(transactionsProvider.notifier).update(tx);
        print('Update completed');
      } else {
        final res = await ref.read(transactionsProvider.notifier).add(tx);
        print(
          'Add completed. Result: ${res.isSuccess ? "SUCCESS" : "FAILURE"}',
        );

        if (res.isFailure) {
          print('!!! Provider returned failure: ${res.errorOrNull}');
          throw Exception(res.errorOrNull);
        }
      }

      print('Provider save completed successfully');
      HapticService.medium();

      if (mounted) {
        print('Popping screen...');
        context.pop();
      }
    } catch (e, stack) {
      print('!!! SAVE CRASHED !!!');
      print('Error: $e');
      print('Stack trace:');
      print(stack);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save error: $e'),
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
                        onPressed: () {
                          ref
                              .read(transactionsProvider.notifier)
                              .delete(widget.initial!.id);
                          Navigator.pop(ctx);
                          context.pop();
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
            children: [
              ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AccountSelector(
                              initial: widget.initial,
                              showDropdown: _showAccountDropdown,
                              onToggleDropdown: () => setState(
                                () => _showAccountDropdown =
                                    !_showAccountDropdown,
                              ),
                              indicatorKey: _accountIndicatorKey,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TypeToggle(
                          selected: state.type,
                          onChanged: (type) => ref
                              .read(
                                addTransactionProvider(widget.initial).notifier,
                              )
                              .setType(type),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  SectionLabel(s.amount),
                  const SizedBox(height: 8),
                  AmountInput(
                    controller: _amountController,
                    currencySymbol: overrideCurrency,
                    showError: _showError,
                    borderColorAnimation: _borderColorAnimation,
                    isDark: isDark,
                    onChanged: (v) {
                      final parsed = double.tryParse(v);
                      ref
                          .read(addTransactionProvider(widget.initial).notifier)
                          .setAmount(parsed);
                    },
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
              if (_showAccountDropdown)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() => _showAccountDropdown = false),
                    behavior: HitTestBehavior.translucent,
                    child: const SizedBox.expand(),
                  ),
                ),
              if (_showAccountDropdown)
                AccountDropdownOverlay(
                  initial: widget.initial,
                  onClose: () => setState(() => _showAccountDropdown = false),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
