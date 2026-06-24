import 'package:flutter/material.dart';

/// AppTheme — Diseñado con accesibilidad como prioridad.
///
/// Criterios:
/// - Fuente mínima 16sp en cuerpo (WCAG 1.4.4)
/// - Contraste mínimo 4.5:1 (WCAG AA)
/// - Touch targets 48dp mínimo
/// - Sin animaciones innecesarias que confundan a usuarios mayores
class AppTheme {
  AppTheme._();

  // Paleta de colores principal
  static const _primaryColor = Color(0xFF1A56DB);    // Azul confiable, institucional
  static const _secondaryColor = Color(0xFF0E9F6E);  // Verde para éxito/positivo
  static const _errorColor = Color(0xFFE02424);
  static const _warningColor = Color(0xFFFF8A00);

  // Colores de fondo
  static const _surfaceLight = Color(0xFFF9FAFB);
  static const _backgroundLight = Color(0xFFFFFFFF);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      primary: _primaryColor,
      secondary: _secondaryColor,
      error: _errorColor,
      surface: _surfaceLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Inter',

      // Typography — tamaños grandes para accesibilidad
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.2),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, height: 1.3),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.3),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, height: 1.4),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.5),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.5),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.6),
        bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.6),
        bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.6),
        labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.4),
        labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
        labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.4),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: _backgroundLight,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF111827),
        ),
      ),

      // Botones — touch targets grandes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52), // ancho full, alto 52dp
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryColor,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: _primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryColor,
          minimumSize: const Size(48, 48), // touch target mínimo
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Inputs — claros y grandes
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _errorColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        hintStyle: TextStyle(fontSize: 16, color: Colors.grey[500]),
        errorStyle: const TextStyle(fontSize: 14),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),

      // Bottom nav — grande para touch fácil
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black12,
        indicatorColor: _primaryColor.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),

      // Chips (para tags de habilidades, etc.)
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEBF5FF),
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _primaryColor,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Colores de estado custom (disponibles via extension)
      extensions: [
        const AppColors(
          success: _secondaryColor,
          warning: _warningColor,
          scoreHigh: Color(0xFF0E9F6E),
          scoreMid: Color(0xFFFF8A00),
          scoreLow: Color(0xFFE02424),
        ),
      ],
    );
  }

  static ThemeData dark() {
    // TODO: implementar tema oscuro en V1.5
    // Por ahora, el sistema usa light() como fallback
    return light();
  }
}

/// Extensión de colores custom para estados y scores
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.warning,
    required this.scoreHigh,
    required this.scoreMid,
    required this.scoreLow,
  });

  final Color success;
  final Color warning;
  final Color scoreHigh;
  final Color scoreMid;
  final Color scoreLow;

  Color scoreColor(double score) {
    if (score >= 4.0) return scoreHigh;
    if (score >= 2.5) return scoreMid;
    return scoreLow;
  }

  @override
  AppColors copyWith({
    Color? success,
    Color? warning,
    Color? scoreHigh,
    Color? scoreMid,
    Color? scoreLow,
  }) {
    return AppColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      scoreHigh: scoreHigh ?? this.scoreHigh,
      scoreMid: scoreMid ?? this.scoreMid,
      scoreLow: scoreLow ?? this.scoreLow,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      scoreHigh: Color.lerp(scoreHigh, other.scoreHigh, t)!,
      scoreMid: Color.lerp(scoreMid, other.scoreMid, t)!,
      scoreLow: Color.lerp(scoreLow, other.scoreLow, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>()!;
}
