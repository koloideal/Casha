import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/services/card_color_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../shared/models/transaction.dart';
import '../../settings/provider.dart';
import '../provider.dart';
import 'balance_card.dart';

String _colorToHex(Color color) {
  final hex = color.value.toRadixString(16).padLeft(8, '0').toUpperCase();
  return hex.substring(2);
}

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: dash.tempAccountName);
    _selectedCurrency = dash.tempAccountCurrency;
    _nameController.addListener(() {
      final text = _nameController.text;
      
      // Check if empty or exceeds limit
      if (text.trim().isEmpty || text.length > 20) {
        setState(() => _showLimitError = true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _showLimitError = false);
        });
      }
      
      // Truncate if exceeds 20 characters
      if (text.length > 20) {
        _nameController.text = text.substring(0, 20);
        _nameController.selection = TextSelection.fromPosition(
          const TextPosition(offset: 20),
        );
        return; // Skip updating dash to avoid out-of-bounds
      }
      
      // Real-time update on card
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

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(widget.context);
    final cardTop = mq.padding.top + kToolbarHeight + 16;
    const cardHeight = 220.0;
    const editorPanelHeight = 102.0; // Increased from 90 to prevent overflow
    final editorPanelTop = cardTop + cardHeight + 20;
    final colorPanelTop = editorPanelTop + editorPanelHeight + 12;
    const colorPanelHeight = 410.0;

    return Consumer(
      builder: (context, ref, _) {
        final exchangeService = ref.watch(exchangeRateServiceProvider);
        
        // Fix: If adding a new account, the balance is strictly 0.0
        double previewBalance = 0.0;
        if (!dash.isAddingAccount) {
          if (dash.editingAccount != null) {
            final txs = ref.watch(accountFilteredTransactionsProvider);
            final accountTxs = txs.where((t) => t.accountId == dash.editingAccount!.id);
            previewBalance = accountTxs.fold(0.0, (sum, t) {
              final converted = exchangeService.convert(
                t.amount,
                t.currencyCode,
                dash.tempAccountCurrency, // convert directly from tx currency to selected dropdown currency
              );
              return t.type == TransactionType.income ? sum + converted : sum - converted;
            });
          } else {
            // Fallback for edge cases
            previewBalance = ref.read(totalBalanceProvider);
          }
        }

        return Material(
          color: Colors.transparent,
          child: Stack(
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
              // Preview Card
              Positioned(
                top: cardTop,
                left: 20,
                right: 20,
                child: BalanceCard(
                  balance: previewBalance,
                  currencyInfo: CurrencyInfo(
                    currencyMap[dash.tempAccountCurrency]?.symbol ?? '\$',
                    dash.tempAccountCurrency,
                  ),
                  onLongPress: null,
                  accountName: dash.tempAccountName,
                  previewPrimary: dash.tempPrimary,
                  previewSecondary: dash.tempSecondary,
                  previewGradientType: dash.tempGradientType,
                ),
              ),
              // Account Editor Panel
              Positioned(
                top: editorPanelTop,
                left: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () {},
                  behavior: HitTestBehavior.opaque,
                  child: _buildEditorPanel(editorPanelHeight),
                ),
              ),
              // Color Picker Panel
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
                  child: _buildColorPanel(colorPanelHeight),
                ),
              ),
              // Currency Dropdown - Above everything
              if (_showCurrencyDropdown)
                Positioned(
                  top: editorPanelTop + 62,
                  right: 34, // 20 (panel padding) + 14 (inner padding)
                  width: (MediaQuery.of(context).size.width - 68) * 0.25, // 25% of the inner row width
                  child: Material(
                    elevation: 12,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(widget.context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(widget.context).colorScheme.onSurface.withOpacity(0.15),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ('USD', '\$'),
                          ('EUR', '€'),
                          ('BYN', 'Br'),
                          ('RUB', '₽'),
                        ].map((entry) {
                          final isSelected = entry.$1 == _selectedCurrency;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedCurrency = entry.$1;
                                // Update temp currency for preview
                                dash.setState(() {
                                  dash.tempAccountCurrency = entry.$1;
                                });
                                dash.overlayEntry?.markNeedsBuild();
                                _showCurrencyDropdown = false;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    entry.$2,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? const Color(0xFF7C6DED) : null,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    entry.$1,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isSelected 
                                        ? const Color(0xFF7C6DED) 
                                        : Theme.of(widget.context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: Color(0xFF7C6DED),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              // Top Right Buttons (Delete & Close)
              Positioned(
                top: mq.padding.top + 8,
                right: 20,
                child: SafeArea(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!dash.isAddingAccount && (ref.watch(accountsProvider).valueOrNull?.length ?? 0) > 1) ...[
                        GestureDetector(
                          onTap: () => setState(() => _showDeleteDialog = true),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Theme.of(widget.context).colorScheme.surface,
                              shape: BoxShape.circle,
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
              ),
              // Custom Dialog Overlay
              if (_showDeleteDialog)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: AlertDialog(
                          backgroundColor: Theme.of(widget.context).colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: const Text('Delete Account?'),
                          content: const Text(
                            'Are you sure you want to delete this account? All associated transactions will also be permanently deleted.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => setState(() => _showDeleteDialog = false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                if (dash.editingAccount == null) return;

                                final accountId = dash.editingAccount!.id;

                                dash.closeAccountOverlay(apply: false);

                                final txs = ref.read(transactionsProvider).valueOrNull ?? [];
                                final accountTxs = txs.where((t) => t.accountId == accountId).toList();
                                for (final t in accountTxs) {
                                  await ref.read(transactionsProvider.notifier).delete(t.id);
                                }

                                await ref.read(accountRepositoryProvider).delete(accountId);

                                if (ref.read(hapticEnabledProvider)) {
                                  HapticService.medium();
                                }
                              },
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEditorPanel(double panelHeight) {
    return Consumer(
      builder: (context, ref, _) {
        return Container(
          height: panelHeight,
          decoration: BoxDecoration(
            color: Theme.of(widget.context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(widget.context).colorScheme.onSurface.withOpacity(0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Account Settings',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(widget.context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                      controller: _nameController,
                      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Account name',
                        hintStyle: TextStyle(fontSize: 13, color: Theme.of(widget.context).colorScheme.onSurface.withOpacity(0.4)),
                        filled: true,
                        fillColor: Theme.of(widget.context).colorScheme.onSurface.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: (_showLimitError || _nameController.text.trim().isEmpty) 
                                ? Colors.red 
                                : Theme.of(widget.context).colorScheme.onSurface.withOpacity(0.15),
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: (_showLimitError || _nameController.text.trim().isEmpty) 
                                ? Colors.red 
                                : Theme.of(widget.context).colorScheme.onSurface.withOpacity(0.15),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: (_showLimitError || _nameController.text.trim().isEmpty) 
                                ? Colors.red 
                                : const Color(0xFF7C6DED),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showCurrencyDropdown = !_showCurrencyDropdown;
                        });
                      },
                      child: Container(
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(widget.context).colorScheme.onSurface.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _showCurrencyDropdown
                                ? const Color(0xFF7C6DED)
                                : Theme.of(widget.context).colorScheme.onSurface.withOpacity(0.15),
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              [('USD', '\$'), ('EUR', '€'), ('BYN', 'Br'), ('RUB', '₽')]
                                  .firstWhere((c) => c.$1 == _selectedCurrency).$2,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _showCurrencyDropdown ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                              size: 20,
                              color: Theme.of(widget.context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildColorPanel(double panelHeight) {
    return Container(
      height: panelHeight,
      decoration: BoxDecoration(
        color: Theme.of(widget.context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(widget.context).colorScheme.onSurface.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: StatefulBuilder(
        builder: (ctx, setPanelState) {
          final s = AppStrings(
            ProviderScope.containerOf(widget.context).read(localeProvider),
          );
          
          void onHSVChanged(HSVColor hsv) {
            setPanelState(() {});
            dash.setState(() {
              if (dash.editingPrimary) {
                dash.tempPrimaryHSV = hsv;
                dash.tempPrimary = hsv.toColor();
              } else {
                dash.tempSecondaryHSV = hsv;
                dash.tempSecondary = hsv.toColor();
              }
            });
            dash.overlayEntry?.markNeedsBuild();
          }

          final isSolid = dash.tempGradientType == GradientType.solid;
          final currentHSV = (isSolid || dash.editingPrimary)
              ? dash.tempPrimaryHSV
              : dash.tempSecondaryHSV;

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: PanelTab(
                          label: s.colorPrimary,
                          isSelected: dash.editingPrimary,
                          color: dash.tempPrimary,
                          isDimmed: isSolid,
                          onTap: () {
                            dash.setState(() {
                              if (isSolid) dash.tempGradientType = CardColorService.defaultGradient;
                              dash.editingPrimary = true;
                            });
                            setPanelState(() {});
                            dash.overlayEntry?.markNeedsBuild();
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: PanelTab(
                          label: s.colorSecondary,
                          isSelected: !dash.editingPrimary,
                          color: dash.tempSecondary,
                          isDimmed: isSolid,
                          onTap: () {
                            dash.setState(() {
                              if (isSolid) dash.tempGradientType = CardColorService.defaultGradient;
                              dash.editingPrimary = false;
                            });
                            setPanelState(() {});
                            dash.overlayEntry?.markNeedsBuild();
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Container(
                          width: 1,
                          color: Theme.of(widget.context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.15),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: isSolid ? null : () {
                            dash.setState(() {
                              dash.tempGradientType = GradientType.solid;
                              dash.editingPrimary = true;
                            });
                            setPanelState(() {});
                            dash.overlayEntry?.markNeedsBuild();
                          },
                          child: Container(
                            height: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSolid
                                  ? const Color(0xFF7C6DED).withOpacity(0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSolid
                                    ? const Color(0xFF7C6DED)
                                    : Theme.of(widget.context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                s.colorSolid,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSolid
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSolid
                                      ? const Color(0xFF7C6DED)
                                      : Theme.of(widget.context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: LayoutBuilder(
                    builder: (lbCtx, constraints) {
                      const reservedBelow = 78.0;
                      final spectrumH =
                          (constraints.maxHeight - reservedBelow).clamp(
                              40.0, double.infinity);

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              height: spectrumH,
                              child: ColorPickerArea(
                                currentHSV,
                                onHSVChanged,
                                PaletteType.hsvWithHue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 36,
                            child: ColorPickerSlider(
                              TrackType.hue,
                              currentHSV,
                              onHSVChanged,
                              displayThumbColor: true,
                            ),
                          ),
                          const SizedBox(height: 8),
                          IgnorePointer(
                            ignoring: isSolid,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: isSolid ? 0.4 : 1.0,
                              child: SizedBox(
                                height: 26,
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        dash.setState(
                                            () => dash.editingPrimary = true);
                                        setPanelState(() {});
                                        dash.overlayEntry?.markNeedsBuild();
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              color: dash.tempPrimary,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: dash.editingPrimary
                                                  ? Border.all(
                                                      color: Colors.white,
                                                      width: 2)
                                                  : Border.all(
                                                      color: Colors.transparent,
                                                      width: 2),
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            '#${_colorToHex(dash.tempPrimary)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontFamily: 'monospace',
                                              fontWeight: dash.editingPrimary
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                              color: Theme.of(widget.context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(
                                                      dash.editingPrimary
                                                          ? 0.8
                                                          : 0.4),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    if (!isSolid)
                                      GestureDetector(
                                        onTap: () {
                                          dash.setState(() =>
                                              dash.editingPrimary = false);
                                          setPanelState(() {});
                                          dash.overlayEntry?.markNeedsBuild();
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '#${_colorToHex(dash.tempSecondary)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontFamily: 'monospace',
                                                fontWeight: !dash.editingPrimary
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                                color: Theme.of(widget.context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(
                                                        !dash.editingPrimary
                                                            ? 0.8
                                                            : 0.4),
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Container(
                                              width: 22,
                                              height: 22,
                                              decoration: BoxDecoration(
                                                color: dash.tempSecondary,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: !dash.editingPrimary
                                                    ? Border.all(
                                                        color: Colors.white,
                                                        width: 2)
                                                    : Border.all(
                                                        color:
                                                            Colors.transparent,
                                                        width: 2),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                IgnorePointer(
                  ignoring: isSolid,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isSolid ? 0.3 : 1.0,
                    child: Row(
                      children: GradientType.values
                          .where((t) => t != GradientType.solid)
                          .map((type) {
                        final isSelected = dash.tempGradientType == type;
                        final label = switch (type) {
                          GradientType.linear => s.gradientLinear,
                          GradientType.linearReverse => s.gradientReverse,
                          GradientType.radial => s.gradientRadial,
                          GradientType.sweep => s.gradientSweep,
                          GradientType.solid => '',
                        };
                        final icon = switch (type) {
                          GradientType.linear => Icons.trending_flat_rounded,
                          GradientType.linearReverse =>
                            Icons.swap_horiz_rounded,
                          GradientType.radial => Icons.blur_circular_rounded,
                          GradientType.sweep => Icons.rotate_right_rounded,
                          GradientType.solid => Icons.square_rounded,
                        };
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () {
                                dash.setState(
                                    () => dash.tempGradientType = type);
                                setPanelState(() {});
                                dash.overlayEntry?.markNeedsBuild();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF7C6DED)
                                          .withOpacity(0.15)
                                      : Theme.of(widget.context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF7C6DED)
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(icon,
                                        size: 15,
                                        color: isSelected
                                            ? const Color(0xFF7C6DED)
                                            : Theme.of(widget.context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.45)),
                                    const SizedBox(height: 2),
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? const Color(0xFF7C6DED)
                                            : Theme.of(widget.context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.45),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final isDarkTheme =
                              Theme.of(widget.context).brightness ==
                                  Brightness.dark;
                          final defP = isDarkTheme
                              ? CardColorService.defaultPrimary
                              : CardColorService.defaultPrimaryLight;
                          final defS = isDarkTheme
                              ? CardColorService.defaultSecondary
                              : CardColorService.defaultSecondaryLight;
                          dash.setState(() {
                            dash.tempPrimary = defP;
                            dash.tempSecondary = defS;
                            dash.tempPrimaryHSV = HSVColor.fromColor(defP);
                            dash.tempSecondaryHSV = HSVColor.fromColor(defS);
                            dash.tempGradientType = CardColorService.defaultGradient;
                          });
                          setPanelState(() {});
                          dash.overlayEntry?.markNeedsBuild();
                        },
                        icon: const Icon(Icons.restart_alt_rounded, size: 15),
                        label: Text(s.reset,
                            style: const TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(widget.context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                          side: BorderSide(
                            color: Theme.of(widget.context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.2),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _nameController.text.trim().isEmpty 
                            ? null 
                            : () {
                                // Add haptic feedback here
                                HapticService.light();
                                dash.closeAccountOverlay(apply: true);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C6DED),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Theme.of(widget.context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.12),
                          disabledForegroundColor: Theme.of(widget.context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.38),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                            dash.isAddingAccount ? s.add : s.apply,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class PanelTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final bool isDimmed;
  final VoidCallback onTap;

  const PanelTab({
    super.key,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.isDimmed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isSelected 
        ? const Color(0xFF7C6DED)
        : (isDark ? Colors.white24 : const Color(0xFFCCCCDD));
    final textColor = isSelected
        ? const Color(0xFF7C6DED)
        : (isDark ? Colors.white60 : Theme.of(context).colorScheme.onSurface.withOpacity(0.5));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isDimmed ? 0.5 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF7C6DED).withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.white30 : Colors.black12,
                    width: 1,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
