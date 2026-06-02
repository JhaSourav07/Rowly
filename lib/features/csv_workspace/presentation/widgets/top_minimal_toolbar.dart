import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/colors.dart';
import '../../../../shared/constants/layout_constants.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../controllers/csv_loader_provider.dart';

class TopMinimalToolbar extends ConsumerWidget {
  const TopMinimalToolbar({super.key});

  Future<void> _handleFileSelection(WidgetRef ref) async {
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

    return Container(
      height: 48.0,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: LayoutConstants.kPaddingMD),
      child: Row(
        children: [
          // Elegant Action Trigger Button
          OutlinedButton.icon(
            onPressed: () => _handleFileSelection(ref),
            icon: const Icon(Icons.file_open_outlined, size: 14, color: AppColors.textPrimary),
            label: Text('Open File', style: context.textTheme.bodyMedium),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.surfaceElevated,
              side: const BorderSide(color: AppColors.borderSubtle),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
          const SizedBox(width: LayoutConstants.kPaddingMD),
          
          // Operational Metadata Status Readout
          Expanded(
            child: csvState.when(
              data: (metadata) {
                if (metadata == null) {
                  return Text('No active workspace session', style: context.textTheme.titleMedium);
                }
                final double megaBytes = metadata.fileSizeInBytes / (1024 * 1024);
                return Text(
                  '${metadata.filePath.split(Platform.pathSeparator).last}  •  ${megaBytes.toStringAsFixed(2)} MB  •  ${metadata.totalRows.toString()} rows mapped',
                  style: context.textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                );
              },
              loading: () => Text('Indexing data matrix stream...', style: context.textTheme.titleMedium?.copyWith(color: AppColors.accent)),
              error: (err, _) => Text('Error: ${err.toString()}', style: context.textTheme.titleMedium?.copyWith(color: AppColors.error)),
            ),
          ),
        ],
      ),
    );
  }
}