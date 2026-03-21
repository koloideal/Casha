import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/card_color_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../settings/provider.dart';
import '../provider.dart';
import 'balance_card.dart';

class FullScreenBlurOverlay extends StatefulWidget {
  final dynamic dashboardState;
  final BuildContext context;

  const FullScreenBlurOverlay({
    super.key,
    required this.dashboardState,
    required this.context,
  });

  @override
  State<FullScreenBlurOverlay> createState() => _FullScreenBlurOverlayState();
}

class _FullScreenBlurOverlayState extends State<FullScreenBlurOverlay> {
  dynamic get dash => widget.dashboardState;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(widget.context);
    final cardTop = mq.padding.top + kToolbarHeight + 16;
    final cardHeight = 180.0;
    final panelTop = cardTop + cardHeight + 50;
    final panelBottom = mq.padding.bottom + 16;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: Colors.black.withOpacity(0.6),
              ),
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                dash.closeOverlay(apply: false);
              },
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: cardTop,
            left: 20,
            right: 20,
            child: Consumer(
              builder: (ctx, ref, _) => BalanceCard(
                balance: ref.read(totalBalanceProvider),
                currencyInfo: ref.read(currencyProvider),
                onLongPress: null,
                previewPrimary: dash.tempPrimary,
                previewSecondary: dash.tempSecondary,
                previewGradientType: dash.tempGradientType,
              ),
            ),
          ),
          Positioned(
            top: panelTop,
            left: 20,
            right: 20,
            bottom: panelBottom,
            child: GestureDetector(
              onTap: () {},
              behavior: HitTestBehavior.opaque,
              child: _buildPanel(context, mq),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel(BuildContext context, MediaQueryData mq) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: Theme.of(widget.context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
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
            final isDark = Theme.of(widget.context).brightness == Brightness.dark;

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

            final currentHSV = dash.editingPrimary
                ? dash.tempPrimaryHSV
                : dash.tempSecondaryHSV;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PanelTab(
                      label: 'Primary',
                      isSelected: dash.editingPrimary,
                      color: dash.tempPrimary,
                      onTap: () {
                        dash.setState(() => dash.editingPrimary = true);
                        setPanelState(() {});
                        dash.overlayEntry?.markNeedsBuild();
                      },
                    ),
                    const SizedBox(width: 10),
                    PanelTab(
                      label: 'Secondary',
                      isSelected: !dash.editingPrimary,
                      color: dash.tempSecondary,
                      onTap: () {
                        dash.setState(() => dash.editingPrimary = false);
                        setPanelState(() {});
                        dash.overlayEntry?.markNeedsBuild();
                      },
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => dash.closeOverlay(apply: false),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE05C6B).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFFE05C6B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: ColorPickerArea(
                      currentHSV,
                      onHSVChanged,
                      PaletteType.hsvWithHue,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 22,
                    child: ColorPickerSlider(
                      TrackType.hue,
                      currentHSV,
                      onHSVChanged,
                      displayThumbColor: true,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        dash.setState(() => dash.editingPrimary = true);
                        setPanelState(() {});
                        dash.overlayEntry?.markNeedsBuild();
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: dash.tempPrimary,
                              borderRadius: BorderRadius.circular(8),
                              border: dash.editingPrimary
                                  ? Border.all(color: Colors.white, width: 2)
                                  : Border.all(
                                      color: Colors.transparent, width: 2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '#${dash.tempPrimary.value.toRadixString(16).substring(2).toUpperCase()}',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              fontWeight: dash.editingPrimary
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: Theme.of(widget.context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(
                                    dash.editingPrimary ? 0.8 : 0.4,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        dash.setState(() => dash.editingPrimary = false);
                        setPanelState(() {});
                        dash.overlayEntry?.markNeedsBuild();
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '#${dash.tempSecondary.value.toRadixString(16).substring(2).toUpperCase()}',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              fontWeight: !dash.editingPrimary
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: Theme.of(widget.context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(
                                    !dash.editingPrimary ? 0.8 : 0.4,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: dash.tempSecondary,
                              borderRadius: BorderRadius.circular(8),
                              border: !dash.editingPrimary
                                  ? Border.all(color: Colors.white, width: 2)
                                  : Border.all(
                                      color: Colors.transparent, width: 2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Gradient Style',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(widget.context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: GradientType.values.map((type) {
                    final isSelected = dash.tempGradientType == type;
                    final label = switch (type) {
                      GradientType.linear => 'Linear',
                      GradientType.linearReverse => 'Reverse',
                      GradientType.radial => 'Radial',
                      GradientType.sweep => 'Sweep',
                    };
                    final icon = switch (type) {
                      GradientType.linear => Icons.trending_flat_rounded,
                      GradientType.linearReverse => Icons.swap_horiz_rounded,
                      GradientType.radial => Icons.blur_circular_rounded,
                      GradientType.sweep => Icons.rotate_right_rounded,
                    };
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            dash.setState(() => dash.tempGradientType = type);
                            setPanelState(() {});
                            dash.overlayEntry?.markNeedsBuild();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF7C6DED).withOpacity(0.15)
                                  : Theme.of(widget.context).colorScheme.onSurface.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
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
                                Icon(
                                  icon,
                                  size: 18,
                                  color: isSelected
                                      ? const Color(0xFF7C6DED)
                                      : Theme.of(widget.context).colorScheme.onSurface.withOpacity(0.5),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    color: isSelected
                                        ? const Color(0xFF7C6DED)
                                        : Theme.of(widget.context).colorScheme.onSurface.withOpacity(0.5),
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final isDark = Theme.of(widget.context).brightness == Brightness.dark;
                          final defPrimary = isDark
                              ? CardColorService.defaultPrimary
                              : CardColorService.defaultPrimaryLight;
                          final defSecondary = isDark
                              ? CardColorService.defaultSecondary
                              : CardColorService.defaultSecondaryLight;
                          dash.setState(() {
                            dash.tempPrimary = defPrimary;
                            dash.tempSecondary = defSecondary;
                            dash.tempPrimaryHSV = HSVColor.fromColor(defPrimary);
                            dash.tempSecondaryHSV = HSVColor.fromColor(defSecondary);
                            dash.tempGradientType = GradientType.linear;
                          });
                          setPanelState(() {});
                          dash.overlayEntry?.markNeedsBuild();
                        },
                        icon: const Icon(Icons.restart_alt_rounded, size: 16),
                        label: const Text('Reset'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(widget.context).colorScheme.onSurface.withOpacity(0.7),
                          side: BorderSide(
                            color: Theme.of(widget.context).colorScheme.onSurface.withOpacity(0.2),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => dash.closeOverlay(apply: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C6DED),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Apply',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class PanelTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const PanelTab({
    super.key,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedBorder = isDark ? Colors.white24 : const Color(0xFFCCCCDD);
    final unselectedText = isDark
        ? Colors.white60
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.5);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : unselectedBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.white30 : Colors.black12,
                  width: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : unselectedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
