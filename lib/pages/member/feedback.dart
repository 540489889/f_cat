import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../shared/toast.dart';
import '../../shared/image_picker_dialog.dart';
import '../../shared/throttle.dart';
import '../../services/api_client.dart';

/// 投诉建议页面
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final List<File> _images = [];
  final ImagePicker _picker = ImagePicker();
  bool _submitting = false;
  final _submitThrottle = ActionThrottle();

  @override
  void dispose() {
    _contentController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _contentController.text.trim().isNotEmpty && !_submitting;

  Future<void> _pickImage() async {
    final source = await showImagePickerDialog(context);

    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (picked == null) return;

    setState(() {
      _images.add(File(picked.path));
    });
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _onSubmit() async {
    await _submitThrottle.run(() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      Toast.show(context, '请输入反馈内容');
      return;
    }

    setState(() => _submitting = true);

    // 先上传图片
    final uploadedUrls = <String>[];
    for (final img in _images) {
      final result = await ApiClient.instance.uploadFile(
        '/app/user/file/upload',
        filePath: img.path,
        fileField: 'file',
        extraFields: {'scene': 'feedback'},
      );
      if (result.isSuccess && result.data != null) {
        final url = result.data is String ? result.data as String : result.asMap['url']?.toString() ?? '';
        if (url.isNotEmpty) uploadedUrls.add(url);
      }
    }

    if (!mounted) return;

    // 提交投诉建议
    final body = <String, dynamic>{
      'content': content,
      'imgs': uploadedUrls.join(','),
      'contact': _contactController.text.trim(),
    };
    try {
      final res = await ApiClient.instance.post('/app/complaint/create', body: body);
      if (!mounted) return;
      if (res.isSuccess) {
        Toast.show(context, '提交成功');
        Navigator.pop(context);
      } else {
        Toast.show(context, res.message.isEmpty ? '提交失败' : res.message);
      }
    } catch (e) {
      if (mounted) Toast.show(context, '提交失败：$e');
    }

    if (mounted) setState(() => _submitting = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_left,
              color: Color(0xFF222222), size: 34),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          '投诉建议',
          style: TextStyle(
            color: Color(0xFF222222),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 投诉建议标题
                  const Text(
                    '投诉建议',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 反馈内容输入框
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _contentController,
                          minLines: 6,
                          maxLines: 6,
                          maxLength: 500,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF333333),
                          ),
                          decoration: const InputDecoration(
                            hintText:
                                '非常感谢您对我们产品的支持！\n请输入您的问题反馈/产品建议',
                            hintStyle: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF999999),
                              height: 1.5,
                            ),
                            border: InputBorder.none,
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 图片区域
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            // 已选择的图片
                            ..._images.asMap().entries.map((e) {
                              return _buildImageItem(e.value, e.key);
                            }),
                            // 添加图片按钮
                            if (_images.length < 4) _buildAddImageButton(),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 联系方式标题
                  const Text(
                    '联系方式',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 联系方式输入框
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _contactController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF333333),
                      ),
                      decoration: const InputDecoration(
                        hintText: '输入手机号，方便我们联系您解决问题',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF999999),
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 提交按钮
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: GestureDetector(
              onTap: _canSubmit ? _onSubmit : null,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: _canSubmit
                      ? const LinearGradient(
                          colors: [Color(0xFFFF7A47), Color(0xFFFF5C2E)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFFCCCCCC), Color(0xFFCCCCCC)],
                        ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: _canSubmit
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF7A47)
                                .withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          '提交',
                          style: TextStyle(
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
    );
  }

  Widget _buildImageItem(File image, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            image,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFF666666),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFFF7A47).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add_photo_alternate_outlined,
                size: 18,
                color: Color(0xFFFF7A47),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '添加',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF999999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
