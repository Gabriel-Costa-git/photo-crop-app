import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'crop_screen.dart';
import '../services/ad_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _croppedImage;
  final ImagePicker _picker = ImagePicker();
  final AdService _adService = AdService();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        _openCropScreen(File(pickedFile.path));
      }
    } catch (e) {
      _showSnackBar('Erro ao selecionar imagem');
    }
  }

  Future<void> _openCropScreen(File imageFile) async {
    final result = await Navigator.push<File>(
      context,
      MaterialPageRoute(builder: (context) => CropScreen(imageFile: imageFile)),
    );
    if (result != null) {
      setState(() => _croppedImage = result);
      _showSnackBar('Foto cortada com sucesso!');
    }
  }

  Future<void> _saveToGallery() async {
    if (_croppedImage == null) return;
    try {
      final result = await ImageGallerySaver.saveFile(_croppedImage!.path);
      _showSnackBar(result['isSuccess'] == true ? 'Salvo na galeria!' : 'Erro ao salvar');
    } catch (e) {
      _showSnackBar('Erro ao salvar');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Selecionar Foto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.photo_library, color: Colors.white)),
                title: const Text('Galeria'),
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.camera_alt, color: Colors.white)),
                title: const Text('Câmera'),
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cortar Foto'),
        centerTitle: true,
        actions: [
          if (_croppedImage != null)
            IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() => _croppedImage = null)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Expanded(
                    child: _croppedImage != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(_croppedImage!, fit: BoxFit.contain))
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.crop_original, size: 80, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text('Nenhuma foto selecionada', style: TextStyle(color: Colors.grey[600])),
                                ],
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _showImageSourceDialog,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: Text(_croppedImage != null ? 'Escolher Outra' : 'Selecionar Foto'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    ),
                  ),
                  if (_croppedImage != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: _saveToGallery,
                        icon: const Icon(Icons.save_alt),
                        label: const Text('Salvar na Galeria'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_adService.isBannerLoaded && _adService.bannerAd != null)
            SizedBox(
              width: _adService.bannerAd!.size.width.toDouble(),
              height: _adService.bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _adService.bannerAd!),
            ),
        ],
      ),
    );
  }
}
