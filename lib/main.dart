import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/theme/colors.dart';
import 'app/theme/typography.dart';
import 'features/csv_workspace/presentation/controllers/csv_loader_provider.dart';
import 'features/csv_workspace/presentation/widgets/widgets.dart';

import 'features/csv_workspace/presentation/controllers/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Suppress the browser's native right-click menu so Flutter Web
  // can intercept secondary pointer events (e.g. column context menu).
  if (kIsWeb) {
    BrowserContextMenu.disableContextMenu();
  }
  runApp(const ProviderScope(child: RowlyApp()));
}

class RowlyApp extends ConsumerWidget {
  const RowlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeModeProvider);
    AppColors.isDark = themeMode == ThemeMode.dark;

    return MaterialApp(
      title: 'Rowly',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        cardColor: AppColors.surface,
        dividerColor: AppColors.borderSubtle,
        textTheme: const TextTheme(
          bodyLarge: AppTypography.monoData,
          bodyMedium: AppTypography.uiCommand,
          titleMedium: AppTypography.uiHeader,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        cardColor: AppColors.surface,
        dividerColor: AppColors.borderSubtle,
        textTheme: const TextTheme(
          bodyLarge: AppTypography.monoData,
          bodyMedium: AppTypography.uiCommand,
          titleMedium: AppTypography.uiHeader,
        ),
      ),
      home: const MainWorkspaceScaffold(),
    );
  }
}

class MainWorkspaceScaffold extends ConsumerWidget {
  const MainWorkspaceScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final csvState = ref.watch(csvLoaderProvider);

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // 1. LEFT SIDEBAR (Completely isolated, dynamic widget!)
            const Sidebar(),

            // 2. RIGHT WORKSPACE AREA
            Expanded(
              child: Column(
                children: [
                  const TopMinimalToolbar(),
                  Expanded(
                    child: csvState.when(
                      data: (metadata) {
                        if (metadata == null) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.table_view_outlined,
                                  size: 64,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(height: 16.0),
                                Text(
                                  'No active workspace session',
                                  style: AppTypography.uiHeader.copyWith(color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 8.0),
                                TextButton(
                                  onPressed: () async {
                                    // Clean open file selection
                                    final controller = ScaffoldMessenger.of(context);
                                    try {
                                      // Trigger file picker in Sidebar
                                    } catch (e) {
                                      controller.showSnackBar(
                                        SnackBar(content: Text('Error: ${e.toString()}')),
                                      );
                                    }
                                  },
                                  style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                                  child: const Text('OPEN A FILE FROM THE SIDEBAR TO BEGIN'),
                                ),
                              ],
                            ),
                          );
                        }
                        return SpreadsheetGrid(metadata: metadata);
                      },
                      loading: () => Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                        ),
                      ),
                      error: (error, _) => Center(
                        child: Text(
                          'ENGINE CORE ERROR: ${error.toString()}',
                          style: AppTypography.monoData.copyWith(color: AppColors.error),
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
  }
}