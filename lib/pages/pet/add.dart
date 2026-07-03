import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../shared/throttle.dart';
import 'nickname.dart';
import 'pet_type.dart';
import 'variety.dart';
import 'pet_gender.dart';
import 'pet_weight.dart';
import 'figure.dart';
import 'generating.dart';
import '../../services/api_client.dart';
import '../../services/pet_api_service.dart';
import '../../shared/image_picker_dialog.dart';
class AddPetPage extends StatefulWidget {
  final String? headimg;
  final String? imgs;

  const AddPetPage({super.key, this.headimg, this.imgs});

  @override
  State<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  String? _petType;
  String? _petVariety;
  double? _weight;
  String? _sex;
  String? _sterilization;
  String? _genderLabel;
  String? _nickname;
  final bool _neutered = false;
  DateTime? _ageDate;

  @override
  void initState() {
    super.initState();
    // 预填来自 figure.dart 的照片
    _faceImageUrl = widget.headimg;
    _imgs = widget.imgs;
  }

	String _formatAge() {
		if (_ageDate == null) return '必填';
		final now = DateTime.now();
		final diff = now.difference(_ageDate!);
		final days = diff.inDays;
		if (days < 30) return '$days天';
		// 用出生日期推算年月
		int years = now.year - _ageDate!.year;
		int months = now.month - _ageDate!.month;
		if (months < 0) { years--; months += 12; }
		if (years > 0) {
			return months > 0 ? '$years年$months个月' : '$years年';
		}
		return '$months个月';
	}
	File? _avatarImage;
	String? _faceImageUrl;
	String? _imgs;
	final ImagePicker _picker = ImagePicker();
	final _saveThrottle = ActionThrottle(interval: const Duration(milliseconds: 500));
	bool _saving = false;

	bool get _canSave =>
		_nickname != null && _nickname!.isNotEmpty &&
		_petType != null &&
		_petVariety != null &&
		_sex != null &&
		_ageDate != null &&
		_weight != null;

	Future<void> _savePet() async {
		await _saveThrottle.run(() async {
		if (!_canSave || _saving) return;
		setState(() => _saving = true);
		final birthday = '${_ageDate!.year}-${_ageDate!.month.toString().padLeft(2, '0')}-${_ageDate!.day.toString().padLeft(2, '0')}T00:00:00.000Z';
		final type = _petType == '狗' ? 'dog' : 'cat';
		// 解析 _imgs（逗号分隔）为三张照片：正脸、侧身、全身
		final imgList = (_imgs ?? '').split(',');
		final result = await PetApiService.addPet(
			nickname: _nickname!,
			type: type,
			variety: _petVariety!,
			sex: _sex!,
			sterilization: _sterilization ?? 'n',
			birthday: birthday,
			weight: _weight!,
			headimg: _faceImageUrl,
			imgFace: imgList.isNotEmpty ? imgList[0] : null,
			imgBody: imgList.length > 1 ? imgList[1] : null,
			imgWhole: imgList.length > 2 ? imgList[2] : null,
		);
		if (!mounted) return;
		setState(() => _saving = false);
		if (result.isSuccess) {
			Navigator.push(context, MaterialPageRoute(builder: (_) => Pet3DGenerationPage(petImageUrl: _faceImageUrl)));
		} else {
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text(result.message)),
			);
		}
		});
	}

	Future<void> _uploadAvatar(String filePath) async {
		final result = await ApiClient.instance.uploadFile(
			'/app/user/file/upload',
			filePath: filePath,
			fileField: 'file',
			extraFields: {'scene': 'avatar'},
		);
		if (!mounted) return;
		if (result.isSuccess && result.data != null) {
			final url = result.data is String ? result.data as String : result.asMap['url']?.toString() ?? '';
			if (url.isNotEmpty) {
				setState(() => _faceImageUrl = url);
				debugPrint('头像上传成功: $url');
			}
		} else {
			debugPrint('头像上传失败: ${result.message}');
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('头像上传失败: ${result.message}')),
			);
		}
	}

	Future<void> _pickAge() async {
		final now = DateTime.now();
		final picked = await showDatePicker(
			context: context,
			initialDate: _ageDate ?? now,
			firstDate: DateTime(2000),
			lastDate: now,
		);
		if (picked != null) setState(() => _ageDate = picked);
	}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F0),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 顶部导航
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.keyboard_arrow_left, size: 34),
                ),
                const Expanded(
                  child: Center(
                    child: Text('添加宠物', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF222222))),
                  ),
                ),
                const SizedBox(width: 48),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(children: [
                  const SizedBox(height: 20),
                  // 头像上传
                  GestureDetector(
                    onTap: () async {
                      final sel = await showImagePickerDialog(context);
                      if (sel != null) {
                        final XFile? picked = await _picker.pickImage(source: sel, maxWidth: 1080, maxHeight: 1080, imageQuality: 80);
                        if (picked != null) {
                          setState(() => _avatarImage = File(picked.path));
                          _uploadAvatar(picked.path);
                        }
                      }
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF7A47), Color(0xFFE85B2A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFFFF7A47).withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3)),
                            ],
                          ),
                          padding: const EdgeInsets.all(3),
                          child: ClipOval(
                            child: Container(
                              color: Colors.white,
                              child: _avatarImage != null
                                  ? Image.file(_avatarImage!, width: 90, height: 90, fit: BoxFit.cover)
                                  : _faceImageUrl != null
                                      ? Image.network(_faceImageUrl!, width: 90, height: 90, fit: BoxFit.cover)
                                      : const Icon(Icons.pets, size: 40, color: Color(0xFFFF7A47)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 14, color: const Color(0xFFFF7A47).withValues(alpha: 0.7)),
                            const SizedBox(width: 4),
                            Text('点击上传宠物头像', style: TextStyle(fontSize: 13, color: const Color(0xFFFF7A47).withValues(alpha: 0.7))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  // 信息填写卡片
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildFieldRow(
                          icon: Icons.edit_outlined,
                          label: '昵称',
                          value: _nickname ?? '必填',
                          onTap: () async {
                            final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const NicknamePage()));
                            if (result is String && result.isNotEmpty) setState(() => _nickname = result);
                          },
                          isFirst: true,
                        ),
                        const Divider(height: 1, indent: 52, color: Color(0xFFF5F5F5)),
                        _buildFieldRow(
                          icon: Icons.pets_outlined,
                          label: '宠物类型',
                          value: _petType ?? '必填',
                          onTap: () async {
                            final sel = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const PetTypePage()));
                            if (sel != null && sel.isNotEmpty) setState(() => _petType = sel);
                          },
                        ),
                        const Divider(height: 1, indent: 52, color: Color(0xFFF5F5F5)),
                        _buildFieldRow(
                          icon: Icons.category_outlined,
                          label: '品种',
                          value: _petVariety ?? '必填',
                          onTap: () async {
                            final sel = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => VarietyPage(mark: _petType == '狗' ? 'dog' : 'cat')));
                            if (sel != null && sel.isNotEmpty) setState(() => _petVariety = sel);
                          },
                        ),
                        const Divider(height: 1, indent: 52, color: Color(0xFFF5F5F5)),
                        _buildFieldRow(
                          icon: Icons.wc_outlined,
                          label: '性别',
                          value: _genderLabel ?? '必填',
                          onTap: () async {
                            final sel = await Navigator.push<Map<String, String>>(context, MaterialPageRoute(builder: (_) => const PetGenderPage()));
                            if (sel != null) {
                              setState(() {
                                _sex = sel['sex'];
                                _sterilization = sel['sterilization'];
                                _genderLabel = sel['label'];
                              });
                            }
                          },
                        ),
                        const Divider(height: 1, indent: 52, color: Color(0xFFF5F5F5)),
                        _buildFieldRow(
                          icon: Icons.cake_outlined,
                          label: '宠物年龄',
                          value: _formatAge(),
                          onTap: () async { await _pickAge(); },
                        ),
                        const Divider(height: 1, indent: 52, color: Color(0xFFF5F5F5)),
                        _buildFieldRow(
                          icon: Icons.monitor_weight_outlined,
                          label: '体重',
                          value: _weight != null ? '${_weight!.toStringAsFixed(1)} Kg' : '必填',
                          onTap: () async {
                            final sel = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const PetWeightPage()));
                            if (sel != null && sel.isNotEmpty) setState(() => _weight = double.tryParse(sel));
                          },
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 正脸照
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
                      ],
                    ),
                    child: _buildFieldRow(
                      icon: Icons.photo_camera_outlined,
                      label: '正脸照',
                      value: _faceImageUrl != null ? '已上传' : '未上传',
                      onTap: () async {
                        final res = await Navigator.push<Map<String, String>>(
                          context,
                          MaterialPageRoute(builder: (_) => PetFigurePage(
                            isReupload: true,
                            existingHeadimg: _faceImageUrl,
                            existingImgs: _imgs,
                          )),
                        );
                        if (res != null && mounted) {
                          setState(() {
                            _faceImageUrl = res['headimg'];
                            _imgs = res['imgs'];
                          });
                        }
                      },
                      isFirst: true,
                      isLast: true,
                    ),
                  ),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
            // 底部按钮
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _canSave && !_saving ? _savePet : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canSave ? const Color(0xFFFF7A47) : const Color(0xFFDDDDDD),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: _canSave ? 4 : 0,
                    shadowColor: const Color(0xFFFF7A47).withValues(alpha: 0.3),
                  ),
                  child: _saving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('生成专属3D形象', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 1)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 12,
          top: isFirst ? 16 : 14,
          bottom: isLast ? 16 : 14,
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: const Color(0xFFFF7A47)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 15, color: Color(0xFF333333))),
            ),
            Text(value, style: TextStyle(fontSize: 14, color: value == '必填' ? const Color(0xFFCCCCCC) : const Color(0xFF999999))),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: Color(0xFFDDDDDD), size: 20),
          ],
        ),
      ),
    );
  }
}

