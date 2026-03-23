import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/services/card_color_service.dart';
import '../../settings/provider.dart';
import '../provider.dart';
import 'balance_card.dart';

String _colorToHex(Color color) {
  final hex = color.value.toRadixString(16).padLeft(8, '0').toUpperCase();
  return hex.substring(2);
}

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
    const cardHeight = 220.0;
    final panelTop = cardTop + cardHeight + 65;
    const panelHeight = 410.0;

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
              onTap: () => dash.closeOverlay(apply: false),
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
            child: GestureDetector(
              onTap: () {},
              behavior: HitTestBehavior.opaque,
              child: _buildPanel(panelHeight),
            ),
          ),
          // Close Button - Top Right
          Positioned(
            top: mq.padding.top + 8,
            right: 20,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => dash.closeOverlay(apply: false),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel(double panelHeight) {
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
                      GestureDetector(
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
                              horizontal: 10, vertical: 6),
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
                            height: 36,  //
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
                        onPressed: () => dash.closeOverlay(apply: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C6DED),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(s.apply,
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
