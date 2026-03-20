import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
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

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late FocusNode _amountFocusNode;
  bool _amountFocused = false;

  @override
  void initState() {
    super.initState();
    _amountFocusNode = FocusNode();
    _amountFocusNode.addListener(() {
      setState(() => _amountFocused = _amountFocusNode.hasFocus);
    });
    if (widget.initial != null) {
      _amountController.text = widget.initial!.amount.toString();
      _noteController.text = widget.initial!.note ?? '';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final state = ref.read(addTransactionProvider(widget.initial));
    final currencyInfo = ref.read(currencyProvider);
    ref.read(addTransactionProvider(widget.initial).notifier).setSubmitting(true);

    final tx = Transaction(
      id: state.editingId ?? _uuid.v4(),
      amount: state.amount!,
      category: state.category,
      type: state.type,
      date: state.date,
      note: state.note.isEmpty ? null : state.note,
      currency: currencyInfo.symbol,
      currencyCode: currencyInfo.code,
    );

    if (state.isEditing) {
      await ref.read(transactionsProvider.notifier).update(tx);
    } else {
      await ref.read(transactionsProvider.notifier).add(tx);
    }
    
    ref.read(addTransactionProvider(widget.initial).notifier).setSubmitting(false);

    if (mounted) context.pop();
  }

  Future<void> _pickDate() async {
    final state = ref.read(addTransactionProvider(widget.initial));
    final picked = await showDatePicker(
      context: context,
      initialDate: state.date,
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
      ref.read(addTransactionProvider(widget.initial).notifier).setDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addTransactionProvider(widget.initial));
    final categories = ref.watch(availableCategoriesProvider(widget.initial));
    final currencyInfo = ref.watch(currencyProvider);

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
              // Type toggle
              _TypeToggle(
                selected: state.type,
                onChanged: (t) =>
                    ref.read(addTransactionProvider(widget.initial).notifier).setType(t),
              ),
              const SizedBox(height: 24),

              // Amount
              _SectionLabel('Amount'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _amountFocused ? Theme.of(context).colorScheme.primary : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        currencyInfo.symbol,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _amountController,
                        focusNode: _amountFocusNode,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                        decoration: const InputDecoration(
                          hintText: '0.00',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 16),
                        ),
                        onChanged: (v) {
                          final parsed = double.tryParse(v);
                          ref.read(addTransactionProvider(widget.initial).notifier).setAmount(parsed);
                        },
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter an amount';
                          if (double.tryParse(v) == null) return 'Invalid amount';
                          if (double.parse(v) <= 0) return 'Amount must be > 0';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Category
              _SectionLabel('Category'),
              const SizedBox(height: 8),
              _CategoryPicker(
                categories: categories,
                selected: state.category,
                onChanged: (c) =>
                    ref.read(addTransactionProvider(widget.initial).notifier).setCategory(c),
              ),
              const SizedBox(height: 20),

              // Date
              _SectionLabel('Date'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), size: 18),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('MMMM d, yyyy').format(state.date),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Note
              _SectionLabel('Note (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Add a note...',
                ),
                onChanged: (v) =>
                    ref.read(addTransactionProvider(widget.initial).notifier).setNote(v),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: state.isSubmitting ? null : _submit,
                child: state.isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(state.isEditing ? 'Update Transaction' : 'Save Transaction'),
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          _TypeOption(
            label: 'Expense',
            icon: Icons.arrow_upward_rounded,
            color: AppColors.expense,
            isSelected: selected == TransactionType.expense,
            onTap: () => onChanged(TransactionType.expense),
          ),
          _TypeOption(
            label: 'Income',
            icon: Icons.arrow_downward_rounded,
            color: AppColors.income,
            isSelected: selected == TransactionType.income,
            onTap: () => onChanged(TransactionType.income),
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
              border: Border.all(
                color: isSelected ? color : Theme.of(context).dividerColor,
                width: isSelected ? 1.5 : 1,
              ),
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
