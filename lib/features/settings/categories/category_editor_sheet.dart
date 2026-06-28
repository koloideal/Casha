import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/utils/result.dart';
import '../../../shared/models/app_category.dart';
import '../../../shared/models/transaction.dart';
import '../../../shared/providers/category_provider.dart';
import '../../../shared/services/translation_service.dart';
import '../../../shared/widgets/error_snackbar.dart';

Future<void> showCategoryEditor(
  BuildContext context, {
  AppCategory? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CategoryEditorSheet(existing: existing),
  );
}

class CategoryEditorSheet extends ConsumerStatefulWidget {
  final AppCategory? existing;

  const CategoryEditorSheet({super.key, this.existing});

  @override
  ConsumerState<CategoryEditorSheet> createState() =>
      _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends ConsumerState<CategoryEditorSheet> {
  late final TextEditingController _enController;
  late final TextEditingController _ruController;
  late TransactionType _type;
  late String _iconName;
  late int _colorValue;

  String? _enSuggestion;
  String? _ruSuggestion;
  bool _translatingEn = false;
  bool _translatingRu = false;
  bool _saving = false;
  DateTime? _lastTranslateTime;
  bool _enOverflow = false;
  bool _ruOverflow = false;
  Timer? _enOverflowTimer;
  Timer? _ruOverflowTimer;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _enController = TextEditingController(text: existing?.labelEn ?? '');
    _ruController = TextEditingController(text: existing?.labelRu ?? '');
    _type = existing?.type == TransactionType.income
        ? TransactionType.income
        : TransactionType.expense;
    _iconName = existing?.iconName ?? kCategoryIcons.keys.first;
    _colorValue = existing?.color.value ?? kCategoryColors.first.value;
    _enController.addListener(_onEnChanged);
    _ruController.addListener(_onRuChanged);
  }

  @override
  void dispose() {
    _enOverflowTimer?.cancel();
    _ruOverflowTimer?.cancel();
    _enController.dispose();
    _ruController.dispose();
    super.dispose();
  }

  void _onEnChanged() {
    if (_enController.text.trim().isNotEmpty && _enSuggestion != null) {
      setState(() => _enSuggestion = null);
    }
    if (_enController.text.length >= 20) {
      _enOverflowTimer?.cancel();
      setState(() => _enOverflow = true);
      _enOverflowTimer = Timer(const Duration(seconds: 1), () {
        if (mounted) setState(() => _enOverflow = false);
      });
    }
  }

  void _onRuChanged() {
    if (_ruController.text.trim().isNotEmpty && _ruSuggestion != null) {
      setState(() => _ruSuggestion = null);
    }
    if (_ruController.text.length >= 20) {
      _ruOverflowTimer?.cancel();
      setState(() => _ruOverflow = true);
      _ruOverflowTimer = Timer(const Duration(seconds: 1), () {
        if (mounted) setState(() => _ruOverflow = false);
      });
    }
  }

  bool _isThrottled() {
    final now = DateTime.now();
    if (_lastTranslateTime != null &&
        now.difference(_lastTranslateTime!) < const Duration(seconds: 2)) {
      return true;
    }
    _lastTranslateTime = now;
    return false;
  }

  Future<void> _translateToRu() async {
    final source = _enController.text.trim();
    if (source.isEmpty) return;
    setState(() => _translatingRu = true);
    final service = ref.read(translationServiceProvider);
    TranslationResult? result;
    if (_isThrottled()) {
      final dict = service.dictionaryLookup(source, TranslateDirection.enToRu);
      result = dict != null ? TranslationResult(dict, fromCache: true) : null;
    } else {
      result = await service.translate(source, TranslateDirection.enToRu);
    }
    if (!mounted) return;
    setState(() {
      _translatingRu = false;
      _ruSuggestion = result?.text;
    });
    if (result == null) {
      showErrorSnackbar(context, ref.read(stringsProvider).translationFailed);
    }
  }

  Future<void> _translateToEn() async {
    final source = _ruController.text.trim();
    if (source.isEmpty) return;
    setState(() => _translatingEn = true);
    final service = ref.read(translationServiceProvider);
    TranslationResult? result;
    if (_isThrottled()) {
      final dict = service.dictionaryLookup(source, TranslateDirection.ruToEn);
      result = dict != null ? TranslationResult(dict, fromCache: true) : null;
    } else {
      result = await service.translate(source, TranslateDirection.ruToEn);
    }
    if (!mounted) return;
    setState(() {
      _translatingEn = false;
      _enSuggestion = result?.text;
    });
    if (result == null) {
      showErrorSnackbar(context, ref.read(stringsProvider).translationFailed);
    }
  }

  Future<void> _save() async {
    final s = ref.read(stringsProvider);
    if (_enController.text.trim().isEmpty &&
        _ruController.text.trim().isEmpty) {
      showErrorSnackbar(context, s.categoryNameRequired);
      return;
    }
    setState(() => _saving = true);
    HapticService.medium();

    String labelEn = _enController.text.trim();
    String labelRu = _ruController.text.trim();

    if (labelEn.isEmpty && labelRu.isNotEmpty) {
      final result = await ref
          .read(translationServiceProvider)
          .translate(labelRu, TranslateDirection.ruToEn);
      if (result != null && result.text.isNotEmpty) {
        labelEn = result.text;
      } else {
        labelEn = labelRu;
      }
    } else if (labelRu.isEmpty && labelEn.isNotEmpty) {
      final result = await ref
          .read(translationServiceProvider)
          .translate(labelEn, TranslateDirection.enToRu);
      if (result != null && result.text.isNotEmpty) {
        labelRu = result.text;
      } else {
        labelRu = labelEn;
      }
    }

    final actions = ref.read(categoryActionsProvider);
    final existing = widget.existing;
    final result = existing != null && existing.id != null
        ? await actions.edit(
            id: existing.id!,
            type: _type,
            labelEn: labelEn,
            labelRu: labelRu,
            iconName: _iconName,
            colorValue: _colorValue,
          )
        : await actions.create(
            type: _type,
            labelEn: labelEn,
            labelRu: labelRu,
            iconName: _iconName,
            colorValue: _colorValue,
          );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result case Failure(message: final message)) {
      showErrorSnackbar(context, message);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  widget.existing != null ? s.editCategory : s.newCategory,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                _TypeToggle(
                  type: _type,
                  onChanged: (t) => setState(() => _type = t),
                  expenseLabel: s.typeExpense,
                  incomeLabel: s.typeIncome,
                ),
                const SizedBox(height: 20),
                _TranslatableField(
                  controller: _enController,
                  label: s.nameEn,
                  hint: s.nameEnHint,
                  suggestion: _enSuggestion,
                  isTranslating: _translatingEn,
                  isOverflow: _enOverflow,
                  canTranslate: _ruController.text.trim().isNotEmpty,
                  translatingLabel: s.translating,
                  applyLabel: s.applyTranslation,
                  onTranslate: _translateToEn,
                  onApply: () {
                    _enController.text = _enSuggestion ?? '';
                    setState(() => _enSuggestion = null);
                  },
                ),
                const SizedBox(height: 16),
                _TranslatableField(
                  controller: _ruController,
                  label: s.nameRu,
                  hint: s.nameRuHint,
                  suggestion: _ruSuggestion,
                  isTranslating: _translatingRu,
                  isOverflow: _ruOverflow,
                  canTranslate: _enController.text.trim().isNotEmpty,
                  translatingLabel: s.translating,
                  applyLabel: s.applyTranslation,
                  onTranslate: _translateToRu,
                  onApply: () {
                    _ruController.text = _ruSuggestion ?? '';
                    setState(() => _ruSuggestion = null);
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  s.categoryIcon,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 10),
                _IconGrid(
                  selected: _iconName,
                  color: Color(_colorValue),
                  onSelected: (name) {
                    HapticService.light();
                    setState(() => _iconName = name);
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  s.categoryColor,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 10),
                _ColorRow(
                  selected: _colorValue,
                  onSelected: (value) {
                    HapticService.light();
                    setState(() => _colorValue = value);
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            s.save,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final TransactionType type;
  final ValueChanged<TransactionType> onChanged;
  final String expenseLabel;
  final String incomeLabel;

  const _TypeToggle({
    required this.type,
    required this.onChanged,
    required this.expenseLabel,
    required this.incomeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _segment(
            context,
            label: expenseLabel,
            selected: type == TransactionType.expense,
            color: AppColors.expense,
            onTap: () => onChanged(TransactionType.expense),
          ),
          _segment(
            context,
            label: incomeLabel,
            selected: type == TransactionType.income,
            color: AppColors.income,
            onTap: () => onChanged(TransactionType.income),
          ),
        ],
      ),
    );
  }

  Widget _segment(
    BuildContext context, {
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? color
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _TranslatableField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? suggestion;
  final bool isTranslating;
  final bool canTranslate;
  final String translatingLabel;
  final String applyLabel;
  final bool isOverflow;
  final VoidCallback onTranslate;
  final VoidCallback onApply;

  const _TranslatableField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.suggestion,
    required this.isTranslating,
    required this.isOverflow,
    required this.canTranslate,
    required this.translatingLabel,
    required this.applyLabel,
    required this.onTranslate,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final isEmpty = controller.text.trim().isEmpty;
        final showGhost = isEmpty && suggestion != null && !isTranslating;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: isOverflow
                    ? Border.all(color: AppColors.expense, width: 1.5)
                    : isDark
                        ? null
                        : Border.all(color: const Color(0xFFDDDDEE), width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        if (showGhost)
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  suggestion!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.28),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        TextField(
                          controller: controller,
                          style: theme.textTheme.bodyLarge,
                          maxLength: 20,
                          decoration: InputDecoration(
                            hintText: showGhost ? '' : hint,
                            isDense: true,
                            filled: false,
                            counterText: '',
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _trailing(context),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _trailing(BuildContext context) {
    if (isTranslating) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 14),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    final isEmpty = controller.text.trim().isEmpty;
    if (isEmpty && suggestion != null) {
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: TextButton(
          onPressed: onApply,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accent,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            applyLabel,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
    }
    if (isEmpty && canTranslate) {
      return IconButton(
        onPressed: onTranslate,
        icon: const Icon(Icons.translate_rounded, size: 20),
        color: AppColors.accent,
        tooltip: '',
      );
    }
    return const SizedBox(width: 8);
  }
}

class _IconGrid extends StatelessWidget {
  final String selected;
  final Color color;
  final ValueChanged<String> onSelected;

  const _IconGrid({
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: kCategoryIcons.entries.map((entry) {
        final isSelected = entry.key == selected;
        return GestureDetector(
          onTap: () => onSelected(entry.key),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withOpacity(0.2)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Icon(
              entry.value,
              color: isSelected
                  ? color
                  : theme.colorScheme.onSurface.withOpacity(0.6),
              size: 22,
            ),
          ),
        );
      }).toList(),
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  const _ColorRow({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: kCategoryColors.map((color) {
        final isSelected = color.value == selected;
        return GestureDetector(
          onTap: () => onSelected(color.value),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
      ),
    );
  }
}
