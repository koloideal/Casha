import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants.dart';
import '../../../../shared/models/account.dart';
import '../../../../shared/models/transaction.dart';
import '../../../../shared/widgets/byn_sign.dart';
import '../../../settings/provider.dart';
import '../../provider.dart';
import '../balance_card.dart';
import './color_panel.dart';
import './delete_dialog.dart';
import './editor_panel.dart';

class AccountEditorOverlay extends StatefulWidget {
  final dynamic dashboardState;
  final BuildContext context;

  const AccountEditorOverlay({
    super.key,
    required this.dashboardState,
    required this.context,
  });

  @override
  State<AccountEditorOverlay> createState() => _AccountEditorOverlayState();
}

class _AccountEditorOverlayState extends State<AccountEditorOverlay> {
  dynamic get dash => widget.dashboardState;
  late TextEditingController _nameController;
  late String _selectedCurrency;
  bool _showCurrencyDropdown = false;
  bool _showLimitError = false;
  bool _showDeleteDialog = false;
  bool _showDuplicateError = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: dash.tempAccountName);
    _selectedCurrency = dash.tempAccountCurrency;
    _nameController.addListener(() {
      final text = _nameController.text;

      if (text.trim().isEmpty || text.length > 20) {
        setState(() => _showLimitError = true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _showLimitError = false);
        });
      }

      if (text.length > 20) {
        _nameController.text = text.substring(0, 20);
        _nameController.selection = TextSelection.fromPosition(
          const TextPosition(offset: 20),
        );
        return;
      }

      dash.setState(() {
        dash.tempAccountName = _nameController.text;
      });
      dash.overlayEntry?.markNeedsBuild();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool _isDuplicateName(List<Account> accounts, String name) {
    final trimmed = name.trim().toLowerCase();
    return accounts.any((a) {
      if (dash.editingAccount != null && a.id == dash.editingAccount!.id) {
        return false;
      }
      return a.name.trim().toLowerCase() == trimmed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(widget.context);
    final cardTop = mq.padding.top + kToolbarHeight + 16;
    const cardHeight = 230.0;
    const editorPanelHeight = 102.0;
    final editorPanelTop = cardTop + cardHeight + 20;
    final colorPanelTop = editorPanelTop + editorPanelHeight + 12;
    const colorPanelHeight = 410.0;
    // Preview card in overlay should match BalanceCardCarousel sizing.

    return Consumer(
      builder: (context, ref, _) {
        final exchangeService = ref.watch(exchangeRateServiceProvider);

        double previewBalance = 0.0;
        if (!dash.isAddingAccount) {
          if (dash.editingAccount != null) {
            final txs = ref.watch(accountFilteredTransactionsProvider);
            final accountTxs = txs.where(
              (t) => t.accountId == dash.editingAccount!.id,
            );
            previewBalance = accountTxs.fold(0.0, (sum, t) {
              final converted = exchangeService.convert(
                t.amount,
                t.currencyCode,
                dash.tempAccountCurrency,
              );
              return t.type == TransactionType.income
                  ? sum + converted
                  : sum - converted;
            });
          } else {
            previewBalance = ref.read(totalBalanceProvider);
          }
        }

        return Material(
          color: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(color: Colors.black.withOpacity(0.6)),
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    if (_showCurrencyDropdown) {
                      setState(() {
                        _showCurrencyDropdown = false;
                      });
                    } else {
                      dash.closeAccountOverlay(apply: false);
                    }
                  },
                  behavior: HitTestBehavior.translucent,
                  child: const SizedBox.expand(),
                ),
              ),
              if (_showDuplicateError)
                Positioned(
                  top: mq.padding.top + 8,
                  left: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.red.shade400,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: Colors.red.shade700,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Account name already exists',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: cardTop,
                left: 0,
                right: 0,
                child: FractionallySizedBox(
                  widthFactor: 0.92,
                  child: SizedBox(
                    height: cardHeight,
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: BalanceCard(
                          balance: previewBalance,
                          currencyInfo: CurrencyInfo(
                            currencyMap[dash.tempAccountCurrency]?.symbol ??
                                '\$',
                            dash.tempAccountCurrency,
                          ),
                          onLongPress: null,
                          accountName: dash.tempAccountName,
                          previewPrimary: dash.tempPrimary,
                          previewSecondary: dash.tempSecondary,
                          previewGradientType:
                              Theme.of(widget.context).brightness ==
                                      Brightness.dark
                                  ? dash.tempDarkGradientType
                                  : dash.tempLightGradientType,
                        ),
                      ),
                  ),
                ),
              ),
              Positioned(
                top: editorPanelTop,
                left: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () {},
                  behavior: HitTestBehavior.opaque,
                  child: AccountEditorPanel(
                    nameController: _nameController,
                    selectedCurrency: _selectedCurrency,
                    showCurrencyDropdown: _showCurrencyDropdown,
                    showLimitError: _showLimitError,
                    showDuplicateError: _showDuplicateError,
                    onCurrencyDropdownToggle: () {
                      setState(() {
                        _showCurrencyDropdown = !_showCurrencyDropdown;
                      });
                    },
                    dashboardContext: widget.context,
                    panelHeight: editorPanelHeight,
                  ),
                ),
              ),
              Positioned(
                top: colorPanelTop,
                left: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () {
                    if (_showCurrencyDropdown) {
                      setState(() {
                        _showCurrencyDropdown = false;
                      });
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AccountColorPanel(
                    dashboardState: dash,
                    dashboardContext: widget.context,
                    panelHeight: colorPanelHeight,
                    isDuplicateName: _isDuplicateName,
                    onDuplicateError: () {
                      setState(() => _showDuplicateError = true);
                      Future.delayed(const Duration(seconds: 3), () {
                        if (mounted) {
                          setState(() => _showDuplicateError = false);
                        }
                      });
                    },
                  ),
                ),
              ),
              if (_showCurrencyDropdown)
                Positioned(
                  top: editorPanelTop + 62,
                  right: 34,
                  width: (MediaQuery.of(context).size.width - 68) * 0.25,
                  child: Material(
                    elevation: 12,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(widget.context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            widget.context,
                          ).colorScheme.onSurface.withOpacity(0.15),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: kDisplayCurrencies.map((entry) {
                              final isSelected = entry.$1 == _selectedCurrency;
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedCurrency = entry.$1;
                                    dash.setState(() {
                                      dash.tempAccountCurrency = entry.$1;
                                    });
                                    dash.overlayEntry?.markNeedsBuild();
                                    _showCurrencyDropdown = false;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      entry.$1 == 'BYN'
                                          ? BynSign(
                                              fontSize: 14,
                                              color: isSelected
                                                  ? const Color(0xFF7C6DED)
                                                  : Theme.of(
                                                      widget.context,
                                                    ).colorScheme.onSurface,
                                            )
                                          : Text(
                                              entry.$2,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: isSelected
                                                    ? const Color(0xFF7C6DED)
                                                    : null,
                                              ),
                                            ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          entry.$1,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isSelected
                                                ? const Color(0xFF7C6DED)
                                                : Theme.of(widget.context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.6),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.check_rounded,
                                          size: 14,
                                          color: Color(0xFF7C6DED),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: cardTop - 20,
                right: 20,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!dash.isAddingAccount &&
                        (ref.watch(accountsProvider).valueOrNull?.length ?? 0) >
                            1) ...[
                      GestureDetector(
                        onTap: () => setState(() => _showDeleteDialog = true),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(widget.context).colorScheme.surface,
                            shape: BoxShape.circle,
                            border:
                                Theme.of(widget.context).brightness ==
                                    Brightness.dark
                                ? Border.all(
                                    color: Theme.of(
                                      widget.context,
                                    ).colorScheme.onSurface.withOpacity(0.3),
                                    width: 1,
                                  )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            size: 22,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    GestureDetector(
                      onTap: () => dash.closeAccountOverlay(apply: false),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(widget.context).colorScheme.surface,
                          shape: BoxShape.circle,
                          border:
                              Theme.of(widget.context).brightness ==
                                  Brightness.dark
                              ? Border.all(
                                  color: Theme.of(
                                    widget.context,
                                  ).colorScheme.onSurface.withOpacity(0.3),
                                  width: 1,
                                )
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 24,
                          color: Theme.of(widget.context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_showDeleteDialog)
                Positioned.fill(
                  child: AccountDeleteDialog(
                    editingAccount: dash.editingAccount,
                    onCancel: () => setState(() => _showDeleteDialog = false),
                    onConfirm: () => dash.closeAccountOverlay(apply: false),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
