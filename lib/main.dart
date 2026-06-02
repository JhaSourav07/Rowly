import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/theme/colors.dart';
import 'app/theme/typography.dart';
import 'features/csv_workspace/presentation/controllers/csv_loader_provider.dart';
import 'features/csv_workspace/presentation/widgets/spreadsheet_grid.dart';
import 'features/csv_workspace/presentation/widgets/top_minimal_toolbar.dart';
import 'shared/extensions/context_extensions.dart';

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

  Future<void> _handleFileSelection(BuildContext context, WidgetRef ref) async {
    final FilePickerResult? selectionResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
      allowMultiple: false,
    );

    if (selectionResult != null && selectionResult.files.single.path != null) {
      final String securePath = selectionResult.files.single.path!;
      await ref.read(csvLoaderProvider.notifier).loadFile(securePath);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final csvState = ref.watch(csvLoaderProvider);
    final recentFiles = ref.watch(recentFilesProvider);

    final activeFilePath = csvState.value?.filePath;
    final activeFile = activeFilePath?.split(Platform.pathSeparator).last;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // 1. LEFT SIDEBAR
            Container(
              width: 240.0,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  right: BorderSide(color: AppColors.borderSubtle, width: 1.0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Window Controls & Branding
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            CircleAvatar(radius: 5, backgroundColor: Color(0xFFFF5F56)),
                            SizedBox(width: 8),
                            CircleAvatar(radius: 5, backgroundColor: Color(0xFFFFBD2E)),
                            SizedBox(width: 8),
                            CircleAvatar(radius: 5, backgroundColor: Color(0xFF27C93F)),
                          ],
                        ),
                        const SizedBox(height: 24.0),
                        Text(
                          'Rowly',
                          style: context.textTheme.titleMedium?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        const Text(
                          'Fast. Lightweight. Powerful.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11.0,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // "Open File" dropdown action trigger
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Material(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(6.0),
                      child: InkWell(
                        onTap: () => _handleFileSelection(context, ref),
                        borderRadius: BorderRadius.circular(6.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.borderSubtle),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.folder_open_outlined, size: 16, color: AppColors.textPrimary),
                                  SizedBox(width: 8),
                                  Text(
                                    'Open File',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textMuted),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24.0),

                  // Navigation Scroll Area
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // FILES Section (Current Open File)
                          _buildSectionHeader('FILES'),
                          if (activeFilePath != null)
                            _buildSidebarFileItem(
                              context: context,
                              title: activeFile!,
                              isActive: true,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Active file path: $activeFilePath')),
                                );
                              },
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Text(
                                'No active file open',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12.0,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),

                          const SizedBox(height: 20.0),

                          // RECENT Section (Historically opened files)
                          _buildSectionHeader('RECENT'),
                          if (recentFiles.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Text(
                                'No recent files loaded',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12.0,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          else
                            ...recentFiles.map((filePath) {
                              final fileName = filePath.split(Platform.pathSeparator).last;
                              final isCurrentActive = activeFilePath == filePath || 
                                  (!filePath.contains(Platform.pathSeparator) && activeFile == fileName);
                              
                              return _buildSidebarFileItem(
                                context: context,
                                title: fileName,
                                isActive: isCurrentActive,
                                onTap: () async {
                                  await ref.read(csvLoaderProvider.notifier).loadFile(filePath);
                                },
                                onClose: () {
                                  ref.read(recentFilesProvider.notifier).removeFile(filePath);
                                },
                              );
                            }),


                          const SizedBox(height: 20.0),

                          // TOOLS Section
                          _buildSectionHeader('TOOLS'),
                          _buildSidebarToolItem(
                            context: context,
                            title: 'Find & Replace',
                            icon: Icons.find_in_page_outlined,
                            trailing: 'Ctrl + H',
                            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Press Ctrl + F to search inside grid cells')),
                            ),
                          ),
                          _buildSidebarToolItem(
                            context: context,
                            title: 'Data Summary',
                            icon: Icons.analytics_outlined,
                          ),
                          _buildSidebarToolItem(
                            context: context,
                            title: 'Duplicate Rows',
                            icon: Icons.copy_all_outlined,
                          ),
                          _buildSidebarToolItem(
                            context: context,
                            title: 'Data Validation',
                            icon: Icons.verified_user_outlined,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(color: AppColors.borderSubtle, height: 1),

                  // Bottom Settings and Version Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                    child: Column(
                      children: [
                        _buildSidebarToolItem(
                          context: context,
                          title: 'Settings',
                          icon: Icons.settings_outlined,
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 12.0),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.successGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Rowly v1.0.0',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

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
                                const Icon(
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
                                  onPressed: () => _handleFileSelection(context, ref),
                                  style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                                  child: const Text('CLICK HERE OR DRAG CSV TO BEGIN'),
                                ),
                              ],
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
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 10.0,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSidebarFileItem({
    required BuildContext context,
    required String title,
    required bool isActive,
    VoidCallback? onTap,
    VoidCallback? onClose,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: isActive ? AppColors.successGreen.withAlpha(20) : Colors.transparent,
        borderRadius: BorderRadius.circular(6.0),
        border: isActive ? Border.all(color: AppColors.successGreen.withAlpha(80), width: 0.5) : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(
                Icons.insert_drive_file_outlined,
                size: 14,
                color: isActive ? AppColors.successGreen : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                    fontSize: 13.0,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onClose != null)
                GestureDetector(
                  onTap: () {
                    onClose();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2.0),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarToolItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    String? trailing,
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 1.0),
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(6.0),
        child: Padding(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(color: AppColors.borderSubtle, width: 0.5),
                  ),
                  child: Text(
                    trailing,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9.0,
                      fontFamily: 'monospace',
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