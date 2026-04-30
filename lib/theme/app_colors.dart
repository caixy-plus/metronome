import 'package:flutter/material.dart';

/// App-wide color tokens supporting light and dark themes.
///
/// Use via `Theme.of(context).extension<AppColors>()!`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color border;
  final Color primary;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;

  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.border,
    required this.primary,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
  });

  static const AppColors dark = AppColors(
    background: Color(0xFF0D0D0D),
    surface: Color(0xFF1A1A1A),
    surfaceVariant: Color(0xFF2A2A2A),
    border: Color(0xFF333333),
    primary: Color(0xFF00F0FF),
    accent: Color(0xFFFF3366),
    textPrimary: Color(0xFFCCCCCC),
    textSecondary: Color(0xFF888888),
    textDisabled: Color(0xFF444444),
  );

  static const AppColors light = AppColors(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF5F5F5),
    surfaceVariant: Color(0xFFE8E8E8),
    border: Color(0xFFE0E0E0),
    primary: Color(0xFF00838F),
    accent: Color(0xFFC2185B),
    textPrimary: Color(0xFF212121),
    textSecondary: Color(0xFF757575),
    textDisabled: Color(0xFFBDBDBD),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? border,
    Color? primary,
    Color? accent,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      border: border ?? this.border,
      primary: primary ?? this.primary,
      accent: accent ?? this.accent,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      border: Color.lerp(border, other.border, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
    );
  }
}
