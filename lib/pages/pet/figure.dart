import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_client.dart';
import '../../shared/image_picker_dialog.dart';
import 'introduce.dart';
import 'generating.dart';

class PetFigurePage extends StatefulWidget {
  final bool isReupload;
  final bool for3D;
  final String? existingHeadimg;
  final String? existingImgs;

  const PetFigurePage({
    super.key,
    this.isReupload = false,
    this.for3D = false,
    this.existingHeadimg,
    this.existingImgs,
  });

  @override
  State<PetFigurePage> createState() => _PetFigurePageState();
}

class _PetFigurePageState extends State<PetFigurePage> {
  static final Map<String, String?> _cachedUrls = {
    'front': null,
    'side': null,
    'body': null,
  };

  final ImagePicker _picker = ImagePicker();

  final Map<String, File?> _photos = {
    'front': null,
    'side': null,
    'body': null,
  };

  final Map<String, String?> _photoUrls = {
    'front': null,
    'side': null,
    'body': null,
  };

  bool _uploading = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _photoUrls['front'] = widget.existingHeadimg ?? _cachedUrls['front'];
    _photoUrls['side'] = _cachedUrls['side'];
    _photoUrls['body'] = _cachedUrls['body'];
    if (widget.existingImgs != null && widget.existingImgs!.isNotEmpty) {
      final urls = widget.existingImgs!.split(',');
      final keys = ['front', 'side', 'body'];
      for (int i = 0; i < urls.length && i < keys.length; i++) {
        if (urls[i].isNotEmpty) {
          _photoUrls[keys[i]] = urls[i];
        }
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  bool get _allUploaded =>
      _photoUrls['front'] != null &&
      _photoUrls['side'] != null &&
      _photoUrls['body'] != null;

  Future<void> _pickPhoto(String type) async {
    final source = await showImagePickerDialog(context);
    if (source == null || !mounted) return;

    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _photos[type] = File(picked.path));
    await _uploadPhoto(type, picked.path);
  }

  Future<void> _uploadPhoto(String type, String filePath) async {
    setState(() => _uploading = true);

    final result = await ApiClient.instance.uploadFile(
      '/app/user/file/upload',
      filePath: filePath,
      fileField: 'file',
      extraFields: {'scene': 'pet'},
    );

    if (!mounted) return;

    setState(() => _uploading = false);

    if (result.isSuccess && result.data != null) {
      final url = result.data is String
          ? result.data as String
          : result.asMap['url']?.toString() ?? '';
      if (url.isNotEmpty) {
        setState(() => _photoUrls[type] = url);
        _cachedUrls[type] = url;
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败: ${result.message}')),
        );
      }
    }
  }

  Widget _buildPhotoItem({
    required int index,
    required String title,
    required String subtitle,
    required String type,
    required String iconAsset,
  }) {
    final photo = _photos[type];
    final url = _photoUrls[type];
    final hasPhoto = photo != null || (url != null && url.isNotEmpty);
    final isUploading = _uploading && !hasPhoto && url == null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEEE), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF7A47),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$index',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 34),
                  child: Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF999999),
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _pickPhoto(type),
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: hasPhoto ? const Color(0xFFFFF3EE) : Colors.white,
                image: hasPhoto
                    ? DecorationImage(
                        image: photo != null
                            ? FileImage(photo) as ImageProvider
                            : NetworkImage(url!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: hasPhoto
                  ? Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF7A47),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ],
                    )
                  : isUploading
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFFF7A47),
                            ),
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Image.asset(
                                  iconAsset,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _DashedBorderPainter(
                                    color: const Color(0xFFFFCBB8),
                                    strokeWidth: 1.5,
                                    dashWidth: 6,
                                    gapWidth: 4,
                                    borderRadius: 12,
                                  ),
                                ),
                              ),
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.camera_alt_outlined,
                                      size: 28,
                                      color: const Color(0xFFFF7A47).withValues(alpha: 0.7),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '点击上传',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: const Color(0xFFFF7A47).withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F4),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.keyboard_arrow_left,
                        color: Color(0xFF222222), size: 34),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        '宠物信息',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF222222),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              '上传宠物照片',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '添加 3 个角度，档案会更准确。',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF999999),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildPhotoItem(
                      index: 1,
                      title: '正脸照',
                      subtitle: '请拍摄宠物正脸清晰的照片',
                      type: 'front',
                      iconAsset: 'assets/images/icon/photo1.png',
                    ),
                    _buildPhotoItem(
                      index: 2,
                      title: '侧身照',
                      subtitle: '请拍摄宠物侧身的照片',
                      type: 'side',
                      iconAsset: 'assets/images/icon/photo2.png',
                    ),
                    _buildPhotoItem(
                      index: 3,
                      title: '全身照',
                      subtitle: '请拍摄宠物全身的照片',
                      type: 'body',
                      iconAsset: 'assets/images/icon/photo3.png',
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: GestureDetector(
                onTap: _allUploaded && _ready
                    ? () async {
                        if (widget.for3D) {
                          // 3D模式：上传完成后跳转到3D生成页
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => Pet3DGenerationPage(petImageUrl: _photoUrls['front']),
                          ));
                        } else if (widget.isReupload) {
                          final imgs = _photoUrls.values
                              .whereType<String>()
                              .toList()
                              .join(',');
                          await Future.delayed(Duration.zero);
                          if (mounted) {
                            Navigator.pop(context, <String, String>{
                              'headimg': _photoUrls['front'] ?? '',
                              'imgs': imgs,
                            });
                          }
                        } else {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PetIntroducePage(
                                headimg: _photoUrls['front'],
                                imgs: _photoUrls.values
                                    .whereType<String>()
                                    .toList()
                                    .join(','),
                              ),
                            ),
                          );
                          if (result == true && mounted) {
                            Navigator.pop(context, true);
                          }
                        }
                      }
                    : null,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _allUploaded
                        ? const Color(0xFFFF7A47)
                        : const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Center(
                    child: Text(
                      widget.for3D ? '重新生成3D形象' : (widget.isReupload ? '确认' : '下一步'),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
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

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double gapWidth;
  final double borderRadius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.dashWidth = 6,
    this.gapWidth = 4,
    this.borderRadius = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      var distance = 0.0;
      final length = metric.length;
      while (distance < length) {
        final end = (distance + dashWidth).clamp(0, length).toDouble();
        final segment = metric.extractPath(distance, end);
        canvas.drawPath(segment, paint);
        distance += dashWidth + gapWidth;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.gapWidth != gapWidth ||
      oldDelegate.borderRadius != borderRadius;
}