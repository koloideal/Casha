import 'package:flutter/material.dart';

const kBalanceCardHeight = 200.0;
const kBalanceCardCarouselHeight = 210.0;
const kAddAccountCardHeight = 200.0;

class CardOverlayLayout {
  final bool compact;
  final double cardHeight;
  final double cardTop;
  final double cardPreviewGap;
  final double editorPanelHeight;
  final double sectionGap;
  final double panelPaddingTop;
  final double panelPaddingBottom;
  final double reservedBelowControls;
  final double hueSliderHeight;
  final double hexRowHeight;
  final double tabSpacing;
  final double controlSpacing;
  final double buttonVerticalPadding;

  const CardOverlayLayout._({
    required this.compact,
    required this.cardHeight,
    required this.cardTop,
    required this.cardPreviewGap,
    required this.editorPanelHeight,
    required this.sectionGap,
    required this.panelPaddingTop,
    required this.panelPaddingBottom,
    required this.reservedBelowControls,
    required this.hueSliderHeight,
    required this.hexRowHeight,
    required this.tabSpacing,
    required this.controlSpacing,
    required this.buttonVerticalPadding,
  });

  factory CardOverlayLayout.fromMediaQuery(MediaQueryData mq) {
    final compact = mq.size.height < 780;
    return CardOverlayLayout._(
      compact: compact,
      cardHeight: kBalanceCardHeight,
      cardTop: mq.padding.top + kToolbarHeight + (compact ? 8 : 16),
      cardPreviewGap: compact ? 12 : 32,
      editorPanelHeight: compact ? 88 : 96,
      sectionGap: compact ? 8 : 12,
      panelPaddingTop: compact ? 10 : 14,
      panelPaddingBottom: compact ? 14 : 22,
      reservedBelowControls: compact ? 62 : 78,
      hueSliderHeight: compact ? 28 : 36,
      hexRowHeight: compact ? 22 : 26,
      tabSpacing: compact ? 6 : 10,
      controlSpacing: compact ? 5 : 8,
      buttonVerticalPadding: compact ? 8 : 10,
    );
  }

  double colorPanelHeight(MediaQueryData mq, double panelTop) {
    final available = mq.size.height - panelTop - mq.padding.bottom - 8;
    return available.clamp(compact ? 250 : 320, 410);
  }
}
