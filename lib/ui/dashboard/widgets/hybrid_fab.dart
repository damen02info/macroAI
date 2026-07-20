import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../providers/dashboard_provider.dart';

class HybridFab extends StatelessWidget {
  const HybridFab({super.key});

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (image != null && context.mounted) {
      context.read<DashboardProvider>().processImageInput(File(image.path));
    }
  }

  void _showTextInputDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Qué has comido?'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ej: Una manzana y un café',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text;
              Navigator.pop(dialogContext);
              if (text.isNotEmpty && context.mounted) {
                context.read<DashboardProvider>().processTextInput(text);
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          heroTag: 'btn_text',
          onPressed: () => _showTextInputDialog(context),
          child: const Icon(Icons.text_fields),
        ),
        const SizedBox(width: 16),

        FloatingActionButton.small(
          heroTag: 'btn_camera',
          onPressed: () => _pickImage(context, ImageSource.camera),
          child: const Icon(Icons.camera_alt_outlined),
        ),
        const SizedBox(width: 16),

        FloatingActionButton(
          heroTag: 'btn_gallery',
          onPressed: () => _pickImage(context, ImageSource.gallery),
          child: const Icon(Icons.add, size: 28),
        ),
      ],
    );
  }
}