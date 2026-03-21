import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../core/services/haptic_service.dart';
import '../../shared/models/transaction.dart';
import '../dashboard/provider.dart';
import '../settings/provider.dart';
import 'provider.dart';

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
  late AnimationController _shakeController;
  late Animation<Color?> _borderColorAnimation;
  bool _showError = false;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

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
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeOut,
    ));
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
        final curr = ref.read(currencyProvider);
        ref.read(addTransactionProvider(null).notifier).setCurrency(curr.symbol, curr.code);
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
    // trim whitespace
    final trimmed = raw.trim();
    
    // empty check
    if (trimmed.isEmpty) return null; // returns null = invalid, show dialog
    
    // replace comma with dot for European locale input
    final normalized = trimmed.replaceAll(',', '.');
    
    // only digits and one dot allowed
    final validPattern = RegExp(r'^\d+\.?\d*$');
    if (!validPattern.hasMatch(normalized)) return null;
    
    // parse
    final value = double.tryParse(normalized);
    if (value == null) return null;
    
    // must be greater than zero
    if (value <= 0) return null;
    
    // must not exceed reasonable max (prevent overflow)
    if (value > 999_999_999) return null;
    
    // must not have more than 2 decimal places
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
    
    // Combine date and time
    final finalDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    
    ref.read(addTransactionProvider(widget.initial).notifier).setAmount(amount);
    ref.read(addTransactionProvider(widget.initial).notifier).setDate(finalDateTime);
    ref.read(addTransactionProvider(widget.initial).notifier).setSubmitting(true);

    final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();

    final tx = Transaction(
      id: state.editingId ?? _uuid.v4(),
      amount: amount,
      category: state.category,
      type: state.type,
      date: finalDateTime,
      note: note,
      currency: state.overrideCurrency,
      currencyCode: state.overrideCurrencyCode,
    );

    if (state.isEditing) {
      await ref.read(transactionsProvider.notifier).update(tx);
    } else {
      await ref.read(transactionsProvider.notifier).add(tx);
    }
    
    ref.read(addTransactionProvider(widget.initial).notifier).setSubmitting(false);
    
    HapticService.medium();

    if (mounted) context.pop();
  }

  Future<void> _pickDate() async {
    // Note: Using showDatePicker (system bottom sheet) which cannot be resized from Flutter.
    // The calendar height is controlled by the system and varies by platform.
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.accent,
          ),
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
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: const Color(0xFF7C6DED),
          ),
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
    final state = ref.watch(addTransactionProvider(widget.initial));
    final categories = ref.watch(availableCategoriesProvider(widget.initial));
    final overrideCurrency = state.overrideCurrency;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(state.isEditing ? 'Edit Transaction' : 'Add Transaction'),
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
                    title: const Text('Delete transaction?'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(transactionsProvider.notifier).delete(widget.initial!.id);
                          Navigator.pop(ctx);
                          context.pop();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFE05C6B),
                        ),
                        child: const Text('Delete'),
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
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _TypeToggle(
                selected: state.type,
                onChanged: (t) =>
                    ref.read(addTransactionProvider(widget.initial).notifier).setType(t),
              ),
              const SizedBox(height: 24),

              _SectionLabel('Amount'),
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: _borderColorAnimation,
                builder: (context, child) {
                  final isError = _showError;
                  final normalBorder = isDark
                      ? Colors.transparent
                      : const Color(0xFFCCCCDD);
                  final borderColor = isError
                      ? (_borderColorAnimation.value ?? const Color(0xFFE05C6B))
                      : normalBorder;

                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: isError ? 1.5 : 1),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            overrideCurrency,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: const InputDecoration(
                              hintText: '0.00',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.symmetric(vertical: 14),
                            ),
                            onChanged: (v) {
                              final parsed = double.tryParse(v);
                              ref.read(addTransactionProvider(widget.initial).notifier).setAmount(parsed);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              Text(
                'Currency',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              _CurrencyPicker(
                selected: state.overrideCurrencyCode,
                onChanged: (symbol, code) =>
                    ref.read(addTransactionProvider(widget.initial).notifier).setCurrency(symbol, code),
              ),
              const SizedBox(height: 20),

              _SectionLabel('Category'),
              const SizedBox(height: 8),
              _CategoryPicker(
                categories: categories,
                selected: state.category,
                onChanged: (c) =>
                    ref.read(addTransactionProvider(widget.initial).notifier).setCategory(c),
              ),
              const SizedBox(height: 20),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // DATE column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: isDark
                                  ? null
                                  : Border.all(color: const Color(0xFFCCCCDD), width: 1),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    DateFormat('MMM d, yyyy').format(_selectedDate),
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // TIME column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Time',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: _pickTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: isDark
                                  ? null
                                  : Border.all(color: const Color(0xFFCCCCDD), width: 1),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedTime.format(context),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _SectionLabel('Note (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                maxLength: 20,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) =>
                    Text(
                      '$currentLength/$maxLength',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                decoration: InputDecoration(
                  hintText: 'Add a note...',
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: isDark
                        ? BorderSide.none
                        : const BorderSide(color: Color(0xFFCCCCDD), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF7C6DED), width: 1.5),
                  ),
                ),
                onChanged: (v) =>
                    ref.read(addTransactionProvider(widget.initial).notifier).setNote(v.trim()),
              ),
              const SizedBox(height: 32),

              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: Builder(
                  builder: (context) {
                    final selectedType = state.type;
                    final typeColor = selectedType == TransactionType.income
                        ? const Color(0xFF4CAF8C)
                        : const Color(0xFFE05C6B);

                    return SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: state.isSubmitting ? null : _submit,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: typeColor.withOpacity(0.1),
                          side: BorderSide(color: typeColor, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          foregroundColor: typeColor,
                        ),
                        child: state.isSubmitting
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: typeColor,
                                ),
                              )
                            : Text(
                                state.isEditing ? 'Save Changes' : 'Add Transaction',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: typeColor,
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;
  const _TypeToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: isDark ? null : Border.all(color: const Color(0xFFDDDDEE), width: 1),
      ),
      child: Row(
        children: [
          _TypeOption(
            label: 'Income',
            icon: Icons.arrow_downward_rounded,
            color: AppColors.income,
            isSelected: selected == TransactionType.income,
            onTap: () => onChanged(TransactionType.income),
          ),
          _TypeOption(
            label: 'Expense',
            icon: Icons.arrow_upward_rounded,
            color: AppColors.expense,
            isSelected: selected == TransactionType.expense,
            onTap: () => onChanged(TransactionType.expense),
          ),
        ],
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  const _TypeOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.6), size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onChanged;
  const _CategoryPicker({
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final isSelected = cat == selected;
        final color = AppCategories.colors[cat] ?? AppColors.accent;
        final icon = AppCategories.icons[cat] ?? Icons.category_rounded;
        return GestureDetector(
          onTap: () => onChanged(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.2) : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: color, width: 1.5)
                  : (isDark ? null : Border.all(color: const Color(0xFFDDDDEE), width: 1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.6), size: 16),
                const SizedBox(width: 6),
                Text(
                  cat,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CurrencyPicker extends StatelessWidget {
  final String selected;
  final void Function(String symbol, String code) onChanged;
  const _CurrencyPicker({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currencies = [
      ('USD', '\$'),
      ('EUR', '€'),
      ('BYN', 'Br'),
      ('RUB', '₽'),
    ];
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: currencies.map((c) {
        final isSelected = c.$1 == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(c.$2, c.$1),
            child: Container(
              margin: EdgeInsets.only(right: c.$1 == currencies.last.$1 ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF7C6DED).withOpacity(0.15) : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? const Color(0xFF7C6DED) : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    c.$2,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xFF7C6DED) : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    c.$1,
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
