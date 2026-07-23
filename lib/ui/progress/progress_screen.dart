import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../providers/progress_provider.dart';
import '../settings/settings_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final TextEditingController _weightCtrl = TextEditingController();

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  void _showAddWeightDialog() {
    showDialog(
      context: context,
      builder: (context) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Añadir Peso'),
              content: TextField(
                controller: _weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Peso (kg)',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _weightCtrl.clear();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final weight = double.tryParse(
                            _weightCtrl.text.replaceAll(',', '.'),
                          );
                          if (weight != null && weight > 0) {
                            setStateDialog(() => isSubmitting = true);
                            try {
                              await context.read<ProgressProvider>().addWeight(
                                weight,
                              );
                              if (mounted) Navigator.pop(context);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Error al guardar'),
                                ),
                              );
                            } finally {
                              setStateDialog(() => isSubmitting = false);
                              _weightCtrl.clear();
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFullImageDetails(
    BuildContext context,
    String url,
    double weight,
    String date,
    Map<String, String> headers,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.black87),
            ),
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(url, fit: BoxFit.contain, headers: headers),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    '$weight kg  •  $date',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgressProvider>();
    final mediaBaseUrl = provider.apiService.mediaBaseUrl;
    final networkHeaders = provider.apiService.mediaHeaders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progreso Físico'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddWeightDialog,
        child: const Icon(Icons.add),
      ),
      body: provider.isLoading && provider.weightHistory.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.weightHistory.length,
              itemBuilder: (context, index) {
                final record = provider.weightHistory[index];
                final hasPhoto =
                    record.fotoUrl != null && record.fotoUrl!.isNotEmpty;
                final fullImageUrl = hasPhoto
                    ? '$mediaBaseUrl/${record.fotoUrl}'
                    : '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: hasPhoto
                        ? () => _showFullImageDetails(
                            context,
                            fullImageUrl,
                            record.pesoCorporal,
                            record.fecha,
                            networkHeaders,
                          )
                        : null,
                    leading: hasPhoto
                        ? CircleAvatar(
                            backgroundImage: CachedNetworkImageProvider(
                              fullImageUrl,
                              headers: networkHeaders,
                            ),
                          )
                        : const CircleAvatar(child: Icon(Icons.monitor_weight)),
                    title: Text(
                      '${record.pesoCorporal} kg',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(record.fecha),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!hasPhoto)
                          IconButton(
                            icon: const Icon(
                              Icons.add_a_photo,
                              color: Colors.blue,
                            ),
                            onPressed: () async {
                              final picker = ImagePicker();
                              final image = await picker.pickImage(
                                source: ImageSource.camera,
                                imageQuality: 70,
                              );
                              if (image != null && context.mounted) {
                                provider.uploadPhotoToRecord(record.id, image);
                              }
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => provider.deleteWeight(record.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
