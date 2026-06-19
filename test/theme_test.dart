import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rowly/app/theme/colors.dart';
import 'package:rowly/features/csv_workspace/presentation/controllers/theme_provider.dart';

void main() {
  test('AppThemeMode toggles correctly', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Initial state should be ThemeMode.dark
    expect(container.read(appThemeModeProvider), ThemeMode.dark);

    // Toggle to Light Mode
    container.read(appThemeModeProvider.notifier).toggle();
    expect(container.read(appThemeModeProvider), ThemeMode.light);

    // Toggle back to Dark Mode
    container.read(appThemeModeProvider.notifier).toggle();
    expect(container.read(appThemeModeProvider), ThemeMode.dark);
  });

  test('AppColors.isDark updates reactively', () {
    // Verify initial default is true
    AppColors.isDark = true;
    expect(AppColors.isDark, isTrue);

    // Check light colors
    AppColors.isDark = false;
    expect(AppColors.isDark, isFalse);
    expect(AppColors.background, const Color(0xFFF5F6F8));
    expect(AppColors.surface, const Color(0xFFFFFFFF));
    expect(AppColors.textPrimary, const Color(0xFF2E3440));

    // Check dark colors
    AppColors.isDark = true;
    expect(AppColors.isDark, isTrue);
    expect(AppColors.background, const Color(0xFF0F1115));
    expect(AppColors.surface, const Color(0xFF161920));
    expect(AppColors.textPrimary, const Color(0xFFECEFF4));
  });
}
