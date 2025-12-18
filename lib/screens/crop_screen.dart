import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../widgets/crop_widget.dart';
import '../services/ad_service.dart';

class CropScreen extends StatefulWidget {
  final File imageFile;
  const CropScreen({super.key, required this.imageFile});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  final GlobalKey<CropWidgetState> _cropKey = GlobalKey();
  Rect _cropRect = const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9);
  int _selectedAspectIndex = 0;
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _aspectRatios = [
    {'label': 'Livre', 'ratio': null},
    {'label': '1:1', 'ratio': 1.0},
    {'label': '4:3', 'ratio': 4 / 3},
    {'label': '16:9', 'ratio': 16 / 9},
    {'label': '3:2', 'ratio': 3 / 2},
  ];

  void _onAspectRatioSelected(int index) {
    setState(() => _selectedAspectIndex = index);
    _cropKey.currentState?.setAspectRatio(_aspectRatios[index]['ratio']);
  }

  Future<void> _cropImage() async {
    setState(() => _isProcessing = true);
    try {
      final bytes = await widget.imageFile.readAsBytes();
      final originalImage = img.decodeImage(bytes);
      if (originalImage == null) throw Exception('Erro');

      final cropX = (_cropRect.left * originalImage.width).round();
      final cropY = (_cropRect.top * originalImage.height).round();
      final cropWidth = ((_cropRect.right - _cropRect.left) * originalImage.width).round();
      final cropHeight = ((_cropRect.bottom - _cropRect.top) * originalImage.height).round();

      final croppedImage = img.copyCrop(originalImage, x: cropX, y: cropY, width: cropWidth, height: cropHeight);
      final tempDir = await getTemporaryDirectory();
      final croppedFile = File('${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await croppedFile.writeAsBytes(img.encodeJpg(croppedImage, quality: 95));

      await AdService().showInterstitialAfterCrop();
      if (mounted) Navigator.pop(context, croppedFile);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Cortar Foto'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        actions: [
          if (_isProcessing)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
          else
            IconButton(icon: const Icon(Icons.check, color: Colors.blue), onPressed: _cropImage),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CropWidget(key: _cropKey, imageFile: widget.imageFile, onCropChanged: (rect) => _cropRect = rect),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(_aspectRatios.length, (i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _onAspectRatioSelected(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedAspectIndex == i ? Colors.blue : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _selectedAspectIndex == i ? Colors.blue : Colors.white54),
                      ),
                      child: Text(_aspectRatios[i]['label'], style: TextStyle(color: Colors.white, fontWeight: _selectedAspectIndex == i ? FontWeight.bold : FontWeight.normal)),
                    ),
                  ),
                )),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _cropImage,
                  icon: _isProcessing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check),
                  label: Text(_isProcessing ? 'Processando...' : 'Cortar'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
