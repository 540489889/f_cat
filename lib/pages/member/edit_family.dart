import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_client.dart';
import '../../services/home_api_service.dart';
import '../../shared/image_picker_dialog.dart';

/// 修改家庭信息页面（头像 + 名称）
class EditFamilyPage extends StatefulWidget {
  final int homeId;
  final String name;
  final String avatar;

  const EditFamilyPage({
    super.key,
    required this.homeId,
    required this.name,
    required this.avatar,
  });

  @override
  State<EditFamilyPage> createState() => _EditFamilyPageState();
}

class _EditFamilyPageState extends State<EditFamilyPage> {
  late TextEditingController _nameController;
  String _avatarUrl = '';
  bool _saving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _avatarUrl = widget.avatar;
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.removeListener(() {});
    _nameController.dispose();
    super.dispose();
  }

  bool get _hasChanged =>
      _nameController.text.trim() != widget.name ||
      _avatarUrl != widget.avatar;

  // ---- 选择头像 ----
  Future<void> _pickAvatar() async {
    final source = await showImagePickerDialog(context);

    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked == null) return;

    await _uploadAvatar(picked.path);
  }

  Future<void> _uploadAvatar(String filePath) async {
    setState(() => _saving = true);
    final result = await ApiClient.instance.uploadFile(
      '/app/user/file/upload',
      filePath: filePath,
      fileField: 'file',
      extraFields: {'scene': 'avatar'},
    );
    if (!mounted) return;
    if (result.isSuccess && result.data != null) {
      final url = result.data is String
          ? result.data as String
          : result.asMap['url']?.toString() ?? '';
      if (url.isNotEmpty) {
        setState(() => _avatarUrl = url);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('头像上传失败: ${result.message}')),
      );
    }
    setState(() => _saving = false);
  }

  // ---- 保存 ----
  Future<void> _onSave() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('家庭名称不能为空')),
      );
      return;
    }

    setState(() => _saving = true);

    final result = await HomeApiService.updateHome(
      homeId: widget.homeId,
      name: newName,
      avatar: _avatarUrl,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      Navigator.pop(context, {
        'name': newName,
        'avatar': _avatarUrl,
      });
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: ${result.message}')),
      );
    }
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
          '修改家庭信息',
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
              child: Column(
                children: [
            const SizedBox(height: 20),
            // ---- 头像区域 ----
            GestureDetector(
              onTap: _saving ? null : _pickAvatar,
              child: Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(52),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_avatarUrl.isNotEmpty)
                      ClipOval(
                        child: Image.network(
                          _avatarUrl,
                          width: 104,
                          height: 104,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _defaultAvatarPlaceholder(),
                        ),
                      )
                    else
                      _defaultAvatarPlaceholder(),
                    // 相机图标
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7A47),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '点击更换家庭头像',
              style: TextStyle(
                color: Color(0xFF999999),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            // ---- 家庭名称输入 ----
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text(
                      '家庭名称',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        textAlign: TextAlign.right,
                        maxLength: 20,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF333333),
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '请输入家庭名称',
                          hintStyle: TextStyle(
                            color: Color(0xFFCCCCCC),
                            fontSize: 16,
                          ),
                          counterText: '',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
                ],
              ),
            ),
          ),
          // ---- 保存按钮（固定在底部） ----
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: GestureDetector(
              onTap: _saving ? null : _onSave,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: _hasChanged && !_saving
                      ? const LinearGradient(
                          colors: [Color(0xFFFF7A47), Color(0xFFFF5C2E)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFFCCCCCC), Color(0xFFCCCCCC)],
                        ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: _hasChanged && !_saving
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF7A47).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          '保存',
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

  Widget _defaultAvatarPlaceholder() {
    return const Icon(
      Icons.home,
      size: 48,
      color: Color(0xFFCCCCCC),
    );
  }
}
