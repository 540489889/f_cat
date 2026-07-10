import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_client.dart';
import '../../services/pet_api_service.dart';
import '../../shared/image_picker_dialog.dart';
import '../../shared/throttle.dart';
import 'nickname.dart';
import 'pet_type.dart';
import 'variety.dart';
import 'pet_gender.dart';
import 'pet_weight.dart';
import 'figure.dart';
import 'three.dart';

class InformationPage extends StatefulWidget {
	final int petId;
	const InformationPage({super.key, required this.petId});

	@override
	State<InformationPage> createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage> {
	String? _nickname;
	String? _petType;
  String? _petVariety;
	double? _weight;
	String? _sex;
	String? _sterilization;
	String? _genderLabel;
	final bool _neutered = false;
	DateTime? _ageDate;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final pet = await PetApiService.getPetDetail(widget.petId);
    if (pet == null || !mounted) return;
    setState(() {
      _nickname = pet.nickname;
      _petType = pet.type == 'cat' ? '猫' : (pet.type == 'dog' ? '狗' : pet.type);
      _petVariety = pet.variety;
      _weight = pet.weight;
      _sex = pet.sex;
      _sterilization = pet.sterilization;
      final gender = pet.sex == 'male' ? 'GG' : 'MM';
      _genderLabel = pet.sterilization == 'y' ? '绝育$gender' : gender;
      _headimgUrl = pet.headimg.isNotEmpty ? pet.headimg : null;
      _faceImageUrl = pet.imgFace.isNotEmpty ? pet.imgFace : null;
      _imgBodyUrl = pet.imgBody;
      _imgWholeUrl = pet.imgWhole;
      if (pet.birthday.isNotEmpty) {
        _ageDate = DateTime.tryParse(pet.birthday);
      }
    });
  }

	String _formatAge() {
		if (_ageDate == null) return '必填';
		final now = DateTime.now();
		final diff = now.difference(_ageDate!);
		final days = diff.inDays;
		if (days < 30) return '$days天';
		int years = now.year - _ageDate!.year;
		int months = now.month - _ageDate!.month;
		if (months < 0) { years--; months += 12; }
		if (years > 0) {
			return months > 0 ? '$years年$months个月' : '$years年';
		}
		return '$months个月';
	}
	File? _avatarImage;
	String? _headimgUrl;
	String? _faceImageUrl;
	String? _imgBodyUrl;
	String? _imgWholeUrl;
	final ImagePicker _picker = ImagePicker();
	final _saveThrottle = ActionThrottle(interval: const Duration(milliseconds: 500));
	final _deleteThrottle = ActionThrottle(interval: const Duration(milliseconds: 500));
	bool _saving = false;

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
				setState(() => _headimgUrl = url);
			}
		}
	}

	Future<void> _savePet() async {
		await _saveThrottle.run(() async {
		if (_nickname == null || _nickname!.isEmpty || _petType == null || _petVariety == null || _sex == null || _ageDate == null || _weight == null || _saving) return;
		setState(() => _saving = true);
		final birthday = '${_ageDate!.year}-${_ageDate!.month.toString().padLeft(2, '0')}-${_ageDate!.day.toString().padLeft(2, '0')}T00:00:00.000Z';
		final type = _petType == '狗' ? 'dog' : 'cat';
		final result = await PetApiService.updatePet(
			petId: widget.petId,
			nickname: _nickname!,
			type: type,
			variety: _petVariety!,
			sex: _sex!,
			sterilization: _sterilization ?? 'n',
			birthday: birthday,
			weight: _weight!,
			headimg: _headimgUrl,
			imgs: _faceImageUrl,
		);
		if (!mounted) return;
		setState(() => _saving = false);
		if (result.isSuccess) {
			Navigator.pop(context, true);
		} else {
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
		}
		});
	}

	void _showDeleteDialog() {
		showDialog(
			context: context,
			builder: (ctx) => AlertDialog(
				backgroundColor: Colors.white,
				shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
				title: const Text('确定删除宠物吗', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
				content: const Text('删除后所有宠物数据将清空', style: TextStyle(color: Colors.black54), textAlign: TextAlign.center),
				actions: [
					Row(
						children: [
							Expanded(
								child: OutlinedButton(
									onPressed: () => Navigator.pop(ctx),
									style: OutlinedButton.styleFrom(
										foregroundColor: Colors.black54,
										side: const BorderSide(color: Color(0xFFDDDDDD)),
										shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
									),
									child: const Text('不删除'),
								),
							),
							const SizedBox(width: 12),
							Expanded(
								child: OutlinedButton(
									onPressed: () {
										Navigator.pop(ctx);
										_deletePet();
									},
									style: OutlinedButton.styleFrom(
										foregroundColor: const Color(0xFFFF4D4F),
										side: const BorderSide(color: Color(0xFFFF4D4F)),
										shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
									),
									child: const Text('删除'),
								),
							),
						],
					),
				],
			),
		);
	}

	Future<void> _deletePet() async {
		await _deleteThrottle.run(() async {
		final result = await PetApiService.deletePet(widget.petId);
		if (!mounted) return;
		if (result.isSuccess) {
			Navigator.pop(context, true);
		} else {
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
		}
		});
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
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.keyboard_arrow_left, size: 34)),
                const Expanded(child: Center(child: Text('宠物档案', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF222222))))),
                TextButton(
                  onPressed: _showDeleteDialog,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF0F0),
                    foregroundColor: const Color(0xFFFF4D4F),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('删除', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(children: [
                  // const SizedBox(height: 20),
                  // 头像
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
                                  : _headimgUrl != null
                                      ? Image.network(_headimgUrl!, width: 90, height: 90, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.pets, size: 40, color: Color(0xFFFF7A47)))
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
                            Text('更换头像', style: TextStyle(fontSize: 13, color: const Color(0xFFFF7A47).withValues(alpha: 0.7))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
                          value: _nickname ?? '',
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
                          value: _petType ?? '',
                          onTap: () async {
                            final sel = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const PetTypePage()));
                            if (sel != null && sel.isNotEmpty) setState(() => _petType = sel);
                          },
                        ),
                        const Divider(height: 1, indent: 52, color: Color(0xFFF5F5F5)),
                        _buildFieldRow(
                          icon: Icons.category_outlined,
                          label: '品种',
                          value: _petVariety ?? '',
                          onTap: () async {
                            final sel = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => VarietyPage(mark: _petType == '狗' ? 'dog' : 'cat')));
                            if (sel != null && sel.isNotEmpty) setState(() => _petVariety = sel);
                          },
                        ),
                        const Divider(height: 1, indent: 52, color: Color(0xFFF5F5F5)),
                        _buildFieldRow(
                          icon: Icons.wc_outlined,
                          label: '性别',
                          value: _genderLabel ?? '',
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
                          value: _weight != null ? '${_weight!.toStringAsFixed(1)} Kg' : '',
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
                  // 正脸照 + 查看3D形象
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
                          icon: Icons.photo_camera_outlined,
                          label: '正脸照',
                          value: _faceImageUrl != null ? '已上传' : '未上传',
                          onTap: () async {
                            final imgsStr = [_faceImageUrl, _imgBodyUrl, _imgWholeUrl]
                                .where((e) => e != null && e.isNotEmpty)
                                .join(',');
                            final res = await Navigator.push<Map<String, String>>(
                              context,
                              MaterialPageRoute(builder: (_) => PetFigurePage(
                                isReupload: true,
                                existingHeadimg: _faceImageUrl,
                                existingImgs: imgsStr.isNotEmpty ? imgsStr : null,
                              )),
                            );
                            if (res != null && mounted) {
                              setState(() {
                                _faceImageUrl = res['headimg'];
                                _imgBodyUrl = null;
                                _imgWholeUrl = null;
                              });
                            }
                          },
                          isFirst: true,
                        ),
                        const Divider(height: 1, indent: 52, color: Color(0xFFF5F5F5)),
                        _buildFieldRow(
                          icon: Icons.view_in_ar_outlined,
                          label: '查看3D形象',
                          value: '',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Pet3DGeneratedPage())),
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
            // 底部保存按钮
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _savePet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A47),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 4,
                    shadowColor: const Color(0xFFFF7A47).withValues(alpha: 0.3),
                  ),
                  child: _saving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('保存', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 1)),
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
            if (value.isNotEmpty)
              Text(value, style: TextStyle(fontSize: 14, color: const Color(0xFF999999))),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: Color(0xFFDDDDDD), size: 20),
          ],
        ),
      ),
    );
  }
}

