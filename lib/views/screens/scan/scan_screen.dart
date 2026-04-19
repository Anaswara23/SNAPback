import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/ui_scale.dart';
import '../../../viewmodels/scan_view_model.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/snapback_scaffold.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ScanViewModel>(
      create: (_) => ScanViewModel(),
      child: const _ScanView(),
    );
  }
}

class _ScanView extends StatelessWidget {
  const _ScanView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ScanViewModel>();
    return SnapbackScaffold(
      title: 'Scan Receipt',
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          GlassCard(
            child: Column(
              children: [
                const Text('Capture your receipt'),
                SizedBox(height: context.rGap(12)),
                if (vm.selectedImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(context.rGap(16)),
                    child: Image.file(
                      vm.selectedImage!,
                      height: context.rGap(220),
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Icon(Icons.receipt_long, size: context.rGap(92)),
                SizedBox(height: context.rGap(12)),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => vm.pickImage(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera),
                        label: const Text('Camera'),
                      ),
                    ),
                    SizedBox(width: context.rGap(10)),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => vm.pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (vm.isProcessing) ...[
            SizedBox(height: context.rGap(12)),
            GlassCard(
              child: Column(
                children: [
                  SizedBox(
                    height: context.rGap(120),
                    child: Lottie.network(
                      'https://assets2.lottiefiles.com/packages/lf20_xwmj0hsk.json',
                      repeat: true,
                    ),
                  ),
                  const Text('Processing receipt...'),
                ],
              ),
            ),
          ],
          if (vm.errorMessage != null) ...[
            SizedBox(height: context.rGap(12)),
            Text(
              vm.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          SizedBox(height: context.rGap(12)),
          SizedBox(
            height: context.rGap(52),
            child: FilledButton.icon(
              onPressed: vm.canSubmit
                  ? () async {
                      final id = await vm.uploadAndAnalyze();
                      if (!context.mounted) return;
                      if (id != null) context.push('/trip/$id');
                    }
                  : null,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Upload & Analyze'),
            ),
          ),
        ],
      ),
    );
  }
}
