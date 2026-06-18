import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'nickname.dart';
import 'pet_type.dart';
import 'variety.dart';
import 'pet_gender.dart';
import 'pet_weight.dart';
import 'pet_photo.dart';
class InformationPage extends StatefulWidget {
	const InformationPage({super.key});

	@override
	State<InformationPage> createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage> {
	String? _petType;
  String? _petVariety;
	double? _weight;
	String? _gender;
	final bool _neutered = false;
	DateTime? _ageDate;
	File? _avatarImage;
	String? _faceImageUrl;
	final ImagePicker _picker = ImagePicker();

	Widget _row(String label, {String? trailing, VoidCallback? onTap}) {
		return GestureDetector(
			onTap: onTap,
			child: Container(
				width: double.infinity,
				padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
				margin: const EdgeInsets.only(bottom: 12),
				decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
				child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text(trailing ?? '必填', style: const TextStyle(color: Colors.black54))]),
			),
		);
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
								const Expanded(child: Center(child: Text('宠物档案', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)))),
								const SizedBox(width: 48),
							]),
						),
						Expanded(
							child: SingleChildScrollView(
								padding: const EdgeInsets.symmetric(horizontal: 16),
								child: Column(children: [
									const SizedBox(height: 8),
																					// 头像 横排样式（和昵称行完全统一）
																					Container(
																						width: double.infinity,
																						padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
																						margin: const EdgeInsets.only(bottom: 12),
																						decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
																						child: Row(
																							children: [
																								const Text('头像', style: TextStyle(fontSize: 16, color: Colors.black87)),
																								const Spacer(),
																								Stack(
																									alignment: Alignment.bottomRight,
																									children: [
																										GestureDetector(
																											onTap: () async {
																												final sel = await showModalBottomSheet<ImageSource>(
																													context: context,
																													builder: (_) => Column(
																														mainAxisSize: MainAxisSize.min,
																														children: [
																															ListTile(leading: const Icon(Icons.photo_library), title: const Text('从相册选择'), onTap: () => Navigator.pop(context, ImageSource.gallery)),
																															ListTile(leading: const Icon(Icons.camera_alt), title: const Text('拍照'), onTap: () => Navigator.pop(context, ImageSource.camera)),
																														],
																													),
																												);
																												if (sel != null) {
																													final XFile? picked = await _picker.pickImage(source: sel, maxWidth: 1080, maxHeight: 1080, imageQuality: 80);
																													if (picked != null) setState(() => _avatarImage = File(picked.path));
																												}
																											},
																											child: Container(
																												width: 80,
																												height: 80,
																												decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
																												child: ClipOval(child: _avatarImage == null ? const Icon(Icons.pets, size: 40, color: Color(0xFFFF8A65)) : Image.file(_avatarImage!, width: 80, height: 80, fit: BoxFit.cover)),
																											),
																										),
																										Positioned(right: 2, bottom: 2, child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Color(0xFFFF8A65), shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.white, size: 16))),
																									],
																								),
																							],
																						),
																					),
									const SizedBox(height: 12),
									_row('昵称', trailing: '', onTap: () async {
										final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const NicknamePage()));
										if (result is String && result.isNotEmpty) {
											// handle returned nickname if needed
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
											child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('宠物类型'), Text(_petType ?? '必填', style: const TextStyle(color: Colors.black54))]),
										),
									),
									GestureDetector(
										onTap: () async {
											final sel = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => VarietyPage(mark: _petType == '汪星人' ? 'dog' : 'cat')));
											if (sel != null && sel.isNotEmpty) setState(() => _petVariety = sel);
										},
										child: Container(
											width: double.infinity,
											padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
											margin: const EdgeInsets.only(bottom: 12),
											decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
											child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('品种'), Text(_petVariety ?? '必填', style: const TextStyle(color: Colors.black54))]),
										),
									),
									GestureDetector(
										onTap: () async {
											final sel = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const PetGenderPage()));
											if (sel != null && sel.isNotEmpty) setState(() => _gender = sel);
										},
										child: Container(
											width: double.infinity,
											padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
											margin: const EdgeInsets.only(bottom: 12),
											decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
											child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('性别'), Text(_gender ?? '必填', style: const TextStyle(color: Colors.black54))]),
										),
									),
									// 宠物年龄（选择年月日）
									_row('宠物年龄', trailing: _ageDate != null ? '${_ageDate!.year}-${_ageDate!.month.toString().padLeft(2,'0')}-${_ageDate!.day.toString().padLeft(2,'0')}' : '必填', onTap: () async {
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
																				child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('体重'), Text(_weight != null ? '${_weight!.toStringAsFixed(1)} Kg' : '必填', style: const TextStyle(color: Colors.black54))]),
																			),
																		),
									_row('正脸照', trailing: _faceImageUrl == null ? '未上传' : '已上传', onTap: () async {
										final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const PeiPhotoPage()));
										if (res is String && res.isNotEmpty) {
											setState(() => _faceImageUrl = res);
										} else if (res is List && res.isNotEmpty) {
											final first = res.firstWhere((e) => e is String, orElse: () => null);
											if (first is String) setState(() => _faceImageUrl = first);
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
									onPressed: () => Navigator.pop(context),
									style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8A65), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
									child: const Text('删除', style: TextStyle(fontSize: 18, color: Colors.white)),
								),
							),
						)
					],
				),
			),
		);
	}
}

