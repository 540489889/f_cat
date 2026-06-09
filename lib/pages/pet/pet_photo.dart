import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PeiPhotoPage extends StatefulWidget {
  const PeiPhotoPage({super.key});

  @override
  State<PeiPhotoPage> createState() => _PeiPhotoPageState();
}

class _PeiPhotoPageState extends State<PeiPhotoPage> {
  final List<String> _pickedPaths = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickFromCamera() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1080, maxHeight: 1080, imageQuality: 80);
    if (file != null) setState(() => _pickedPaths.add(file.path));
  }

  Future<void> _pickFromGalleryMulti() async {
    try {
      final List<XFile> files = await _picker.pickMultiImage(imageQuality: 80, maxWidth: 1080, maxHeight: 1080);
      if (files != null && files.isNotEmpty) setState(() => _pickedPaths.addAll(files.map((f) => f.path)));
    } catch (_) {}
  }

  Future<void> _showSourceSheet() async {
    final sel = await showModalBottomSheet<String>(context: context, builder: (_) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.photo_library), title: const Text('从相册选择'), onTap: () => Navigator.pop(context, 'gallery')),
        ListTile(leading: const Icon(Icons.camera_alt), title: const Text('拍照'), onTap: () => Navigator.pop(context, 'camera')),
      ]);
    });
    if (sel == 'camera') await _pickFromCamera();
    if (sel == 'gallery') await _pickFromGalleryMulti();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_left, color: Colors.black, size: 34),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('正脸照', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: const [
                CircleAvatar(radius: 22, backgroundColor: Colors.grey),
                SizedBox(width: 12),
                Expanded(child: Text('旋旋的正脸照', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
              ]),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: const [
                Expanded(child: Text('请上传宠物正面照片，上传越多识别越精准\n(识别宠物功能仅针对可视设备开放)', style: TextStyle(color: Colors.black54))),
                SizedBox(width: 8),
                Text('照片示例', style: TextStyle(color: Colors.blue)),
              ]),
            ),
            const SizedBox(height: 16),
            // 网格样式，多行换行，每行最多 3 张
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LayoutBuilder(builder: (context, constraints) {
                final double spacing = 12;
                final double totalPadding = 0;
                final double itemWidth = (constraints.maxWidth - totalPadding - spacing * 2) / 3;
                List<Widget> tiles = [];
                for (int i = 0; i < _pickedPaths.length; i++) {
                  final path = _pickedPaths[i];
                  tiles.add(Stack(children: [
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(path), width: itemWidth, height: itemWidth, fit: BoxFit.cover)),
                    Positioned(right: 6, top: 6, child: GestureDetector(onTap: () => setState(() => _pickedPaths.removeAt(i)), child: const CircleAvatar(radius: 12, backgroundColor: Colors.black45, child: Icon(Icons.close, size: 16, color: Colors.white)))),
                  ]));
                }
                // 添加按钮
                tiles.add(GestureDetector(
                  onTap: _showSourceSheet,
                  child: Container(
                    width: itemWidth,
                    height: itemWidth,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.add, color: Colors.blue, size: 32), SizedBox(height: 6), Text('正脸', style: TextStyle(color: Colors.blue))]),
                  ),
                ));

                return SingleChildScrollView(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      runAlignment: WrapAlignment.start,
                      spacing: spacing,
                      runSpacing: spacing,
                      children: tiles.map((w) => SizedBox(width: itemWidth, height: itemWidth, child: w)).toList(),
                    ),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _pickedPaths.isEmpty ? null : () => Navigator.pop(context, _pickedPaths),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _pickedPaths.isEmpty ? Colors.grey[300] : Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
                  child: const Text('保存', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
