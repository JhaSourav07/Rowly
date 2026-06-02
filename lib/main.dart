import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/theme/colors.dart';
import 'app/theme/typography.dart';
import 'features/csv_workspace/presentation/controllers/csv_loader_provider.dart';
import 'features/csv_workspace/presentation/widgets/spreadsheet_grid.dart';
import 'features/csv_workspace/presentation/widgets/top_minimal_toolbar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: RowlyApp()));
}

class RowlyApp extends StatelessWidget {
  const RowlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rowly',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
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
        child: Column(
          children: [
            const TopMinimalToolbar(),
            Expanded(
              child: csvState.when(
                data: (metadata) {
                  if (metadata == null) {
                    return Center(
                      child: Text(
                        'DRAG CSV HERE OR CLICK "OPEN FILE" TO BEGIN',
                        style: AppTypography.uiHeader.copyWith(color: AppColors.textMuted),
                      ),
                    );
                  }
                  return SpreadsheetGrid(metadata: metadata);
                },
                loading: () => const Center(
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
    );
  }
}