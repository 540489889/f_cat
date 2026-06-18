import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'nickname.dart';
import 'pet_type.dart';
import 'variety.dart';
import 'pet_gender.dart';
import 'pet_weight.dart';
import 'pet_photo.dart';
import '../../services/api_client.dart';
import '../../services/pet_api_service.dart';
class AddPetPage extends StatefulWidget {
	const AddPetPage({super.key});

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
			return months > 0 ? '${years}年${months}个月' : '${years}年';
		}
		return '$months个月';
	}
	File? _avatarImage;
	String? _faceImageUrl;
	String? _imgs;
	final ImagePicker _picker = ImagePicker();

	Widget _row(String label, {String? trailing, VoidCallback? onTap}) {
		return GestureDetector(
			onTap: onTap,
			child: Container(
				width: double.infinity,
				padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
				margin: const EdgeInsets.only(bottom: 12),
				decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
				child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
					Text(label),
					Row(mainAxisSize: MainAxisSize.min, children: [
						Text(trailing ?? '必填', style: const TextStyle(color: Colors.black54)),
						const SizedBox(width: 4),
						const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
					]),
				]),
			),
		);
	}

	bool get _canSave =>
		_nickname != null && _nickname!.isNotEmpty &&
		_petType != null &&
		_petVariety != null &&
		_sex != null &&
		_ageDate != null &&
		_weight != null;

	Future<void> _savePet() async {
		if (!_canSave) return;
		final birthday = '${_ageDate!.year}-${_ageDate!.month.toString().padLeft(2, '0')}-${_ageDate!.day.toString().padLeft(2, '0')}T00:00:00.000Z';
		final type = _petType == '狗' ? 'dog' : 'cat';
		final result = await PetApiService.addPet(
			nickname: _nickname!,
			type: type,
			variety: _petVariety!,
			sex: _sex!,
			sterilization: _sterilization ?? 'n',
			birthday: birthday,
			weight: _weight!,
			headimg: _faceImageUrl,
			imgs: _imgs,
		);
		if (!mounted) return;
		if (result.isSuccess) {
			Navigator.pop(context, true);
		} else {
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text(result.message)),
			);
		}
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
			backgroundColor: const Color(0xFFFBF6F2),
			body: SafeArea(
				bottom: false,
				child: Column(
					children: [
						Padding(
							padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
							child: Row(children: [
								IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.keyboard_arrow_left, size: 34)),
								const Expanded(child: Center(child: Text('添加宠物', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)))),
								const SizedBox(width: 48),
							]),
						),
						Expanded(
							child: SingleChildScrollView(
								padding: const EdgeInsets.symmetric(horizontal: 16),
								child: Column(children: [
									const SizedBox(height: 8),
									Column(
										children: [
											Stack(alignment: Alignment.bottomRight, children: [
												GestureDetector(
													onTap: () async {
												final sel = await showModalBottomSheet<ImageSource>(context: context, builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
													ListTile(leading: const Icon(Icons.photo_library), title: const Text('从相册选择'), onTap: () => Navigator.pop(context, ImageSource.gallery)),
													ListTile(leading: const Icon(Icons.camera_alt), title: const Text('拍照'), onTap: () => Navigator.pop(context, ImageSource.camera)),
												]));
												if (sel != null) {
													final XFile? picked = await _picker.pickImage(source: sel, maxWidth: 1080, maxHeight: 1080, imageQuality: 80);
													if (picked != null) {
														setState(() => _avatarImage = File(picked.path));
														_uploadAvatar(picked.path);
													}
												}
													},
													child: Container(
														width: 120,
														height: 120,
														decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
														child: ClipOval(
															child: _avatarImage == null
																	? const Icon(Icons.pets, size: 64, color: Color(0xFFFF8A65))
																	: Image.file(_avatarImage!, width: 120, height: 120, fit: BoxFit.cover),
														),
													),
												),
												Positioned(
													right: 4,
													bottom: 4,
													child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFFFF8A65), shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.white, size: 20)),
												)
											]),
											const SizedBox(height: 8),
											const Text('点击上传宠物头像', style: TextStyle(color: Color(0xFF999999), fontSize: 13)),
										],
									),
									const SizedBox(height: 12),
									_row('昵称', trailing: _nickname ?? '必填', onTap: () async {
										final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const NicknamePage()));
										if (result is String && result.isNotEmpty) {
											setState(() => _nickname = result);
										}
									}),
									GestureDetector(
										onTap: () async {
											final sel = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const PetTypePage()));
											if (sel != null && sel.isNotEmpty) setState(() => _petType = sel);
										},
										child: Container(
											width: double.infinity,
											padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
											margin: const EdgeInsets.only(bottom: 12),
											decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
											child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
												const Text('宠物类型'),
												Row(mainAxisSize: MainAxisSize.min, children: [
													Text(_petType ?? '必填', style: const TextStyle(color: Colors.black54)),
													const SizedBox(width: 4),
													const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
												]),
											]),
										),
									),
									GestureDetector(
										onTap: () async {
											final sel = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => VarietyPage(mark: _petType == '狗' ? 'dog' : 'cat')));
											if (sel != null && sel.isNotEmpty) setState(() => _petVariety = sel);
										},
										child: Container(
											width: double.infinity,
											padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
											margin: const EdgeInsets.only(bottom: 12),
											decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
											child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
												const Text('品种'),
												Row(mainAxisSize: MainAxisSize.min, children: [
													Text(_petVariety ?? '必填', style: const TextStyle(color: Colors.black54)),
													const SizedBox(width: 4),
													const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
												]),
											]),
										),
									),
									GestureDetector(
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
										child: Container(
											width: double.infinity,
											padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
											margin: const EdgeInsets.only(bottom: 12),
											decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
											child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
												const Text('性别'),
												Row(mainAxisSize: MainAxisSize.min, children: [
													Text(_genderLabel ?? '必填', style: const TextStyle(color: Colors.black54)),
													const SizedBox(width: 4),
													const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
												]),
											]),
										),
									),
									// 宠物年龄（选择年月日）
									_row('宠物年龄', trailing: _formatAge(), onTap: () async {
										await _pickAge();
									}),
							
																		GestureDetector(
																			onTap: () async {
																				final sel = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const PetWeightPage()));
																				if (sel != null && sel.isNotEmpty) setState(() => _weight = double.tryParse(sel));
																			},
																			child: Container(
																				width: double.infinity,
																				padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
																				margin: const EdgeInsets.only(bottom: 12),
																				decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
																				child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
																					Text('体重'),
																					Row(mainAxisSize: MainAxisSize.min, children: [
																						Text(_weight != null ? '${_weight!.toStringAsFixed(1)} Kg' : '必填', style: const TextStyle(color: Colors.black54)),
																						const SizedBox(width: 4),
																						const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
																					]),
																				]),
																			),
																		),
									_row('正脸照', trailing: _imgs == null ? '未上传' : '已上传', onTap: () async {
										final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const PeiPhotoPage()));
										if (res is String && res.isNotEmpty) {
											setState(() => _imgs = res);
										}
									}),
									const SizedBox(height: 40),
								]),
							),
						),
						Padding(
							padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
							child: SizedBox(
								width: double.infinity,
								height: 52,
								child: ElevatedButton(
									onPressed: _canSave ? _savePet : null,
									style: ElevatedButton.styleFrom(
										backgroundColor: _canSave ? const Color(0xFFFF8A65) : const Color(0xFFDDDDDD),
										shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
									),
									child: const Text('保存', style: TextStyle(fontSize: 18, color: Colors.white)),
								),
							),
						)
					],
				),
			),
		);
	}
}

