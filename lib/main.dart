import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/theme/colors.dart';
import 'app/theme/typography.dart';
import 'features/csv_workspace/presentation/controllers/csv_loader_provider.dart';
import 'features/csv_workspace/presentation/widgets/widgets.dart';

import 'features/csv_workspace/presentation/controllers/theme_provider.dart';

final initialFilePathProvider = Provider<String?>((ref) => null);

Future<void> _registerFileAssociations() async {
  if (kIsWeb) return;
  try {
    if (Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home == null) return;

      final desktopDir = Directory('$home/.local/share/applications');
      if (!await desktopDir.exists()) {
        await desktopDir.create(recursive: true);
      }

      final executablePath = Platform.resolvedExecutable;
      final desktopFile = File('${desktopDir.path}/rowly.desktop');

      final content = '''
[Desktop Entry]
Name=Rowly
Comment=Production-grade CSV and Excel Editor
Exec=$executablePath %f
Terminal=false
Type=Application
Categories=Office;
MimeType=text/csv;application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;application/vnd.ms-excel;
''';

      await desktopFile.writeAsString(content);

      await Process.run('update-desktop-database', [desktopDir.path]);

      await Process.run('xdg-mime', [
        'default',
        'rowly.desktop',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      ]);
      await Process.run('xdg-mime', [
        'default',
        'rowly.desktop',
        'application/vnd.ms-excel'
      ]);
      await Process.run('xdg-mime', [
        'default',
        'rowly.desktop',
        'text/csv'
      ]);
    } else if (Platform.isWindows) {
      final exe = Platform.resolvedExecutable;
      await Process.run('reg', ['add', 'HKCU\\Software\\Classes\\.xlsx', '/t', 'REG_SZ', '/d', 'Rowly.xlsx', '/f']);
      await Process.run('reg', ['add', 'HKCU\\Software\\Classes\\.xls', '/t', 'REG_SZ', '/d', 'Rowly.xls', '/f']);
      await Process.run('reg', ['add', 'HKCU\\Software\\Classes\\.csv', '/t', 'REG_SZ', '/d', 'Rowly.csv', '/f']);
      
      await Process.run('reg', ['add', 'HKCU\\Software\\Classes\\Rowly.xlsx\\shell\\open\\command', '/t', 'REG_SZ', '/d', '"$exe" "%1"', '/f']);
      await Process.run('reg', ['add', 'HKCU\\Software\\Classes\\Rowly.xls\\shell\\open\\command', '/t', 'REG_SZ', '/d', '"$exe" "%1"', '/f']);
      await Process.run('reg', ['add', 'HKCU\\Software\\Classes\\Rowly.csv\\shell\\open\\command', '/t', 'REG_SZ', '/d', '"$exe" "%1"', '/f']);
    }
  } catch (e) {
    debugPrint('Failed to register file associations: $e');
  }
}

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Register file associations on desktop platforms asynchronously
  _registerFileAssociations();

  // Suppress the browser's native right-click menu so Flutter Web
  // can intercept secondary pointer events (e.g. column context menu).
  if (kIsWeb) {
    BrowserContextMenu.disableContextMenu();
  }
  
  final String? initialPath = args.isNotEmpty ? args.first : null;

  runApp(
    ProviderScope(
      overrides: [
        initialFilePathProvider.overrideWithValue(initialPath),
      ],
      child: const RowlyApp(),
    ),
  );
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

class MainWorkspaceScaffold extends ConsumerStatefulWidget {
  const MainWorkspaceScaffold({super.key});

  @override
  ConsumerState<MainWorkspaceScaffold> createState() => _MainWorkspaceScaffoldState();
}

class _MainWorkspaceScaffoldState extends ConsumerState<MainWorkspaceScaffold> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialPath = ref.read(initialFilePathProvider);
      if (initialPath != null) {
        ref.read(csvLoaderProvider.notifier).loadFile(initialPath);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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