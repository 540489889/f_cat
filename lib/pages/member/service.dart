import 'package:flutter/material.dart';

class ServicePage extends StatelessWidget {
	const ServicePage({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: const Color(0xFFFFF5F0),
			appBar: AppBar(
				backgroundColor: const Color(0xFFFFF5F0),
				elevation: 0,
				leading: IconButton(
					icon: const Icon(Icons.keyboard_arrow_left, color: Colors.black87, size: 34),
					onPressed: () => Navigator.of(context).maybePop(),
				),
				centerTitle: true,
				title: const Text('客服', style: TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.w500)),
			),
			body: Column(
				children: [
					Expanded(
						child: ListView(
							padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
							children: [
								Padding(
									padding: const EdgeInsets.only(left: 4, bottom: 12),
									child: Row(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											// 头像
											Container(
												width: 40,
												height: 40,
												decoration: BoxDecoration(
													color: const Color(0xFFFF8A65).withValues(alpha: 0.2),
													borderRadius: BorderRadius.circular(20),
												),
												child: ClipOval(
													child: Image.asset('assets/images/logo.png', width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_, __, ___) =>
														const Icon(Icons.pets, color: Color(0xFFFF8A65), size: 22)),
												),
											),
											const SizedBox(width: 10),
											Flexible(
												child: Container(
													padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
													decoration: BoxDecoration(
														color: Colors.white,
														borderRadius: BorderRadius.circular(12),
														boxShadow: [
															BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
														],
													),
													child: Column(
														crossAxisAlignment: CrossAxisAlignment.start,
														mainAxisSize: MainAxisSize.min,
														children: [
															const Text(
																'智能养宠，在只创。很抱歉让您进入售后状态，给您带来困扰了。在服务的过程中您有任何不满或者建议一定要告诉我们要，期待与您一路同行。',
																style: TextStyle(fontSize: 14, color: Color(0xFF333333), height: 1.5),
															),
															const SizedBox(height: 8),
															Text('4月31日 09:00', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
														],
													),
												),
											),
										],
									),
								),
							],
						),
					),

					// 底部输入栏
					SafeArea(
						top: false,
						child: Container(
              
							padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
							decoration: const BoxDecoration(
								color: Colors.white,
								// border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
							),
							child: Row(
								crossAxisAlignment: CrossAxisAlignment.center,
								children: [
									GestureDetector(
										onTap: () {},
										child: Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey[400]!)),
											child: const Center(child: Icon(Icons.mic_none, color: Colors.grey, size: 20)))),
									const SizedBox(width: 8),
									Expanded(
										child: Container(
											height: 38,
											padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
											decoration: BoxDecoration(
												color: const Color(0xFFF5F5F5),
												borderRadius: BorderRadius.circular(19),
											),
											child: TextField(
											textAlignVertical: TextAlignVertical.center,
												decoration: InputDecoration.collapsed(hintText: '请输入消息', hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13)),
												style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
											),
										),
									),
									const SizedBox(width: 8),
									GestureDetector(
										onTap: () {},
										child: Container(width: 34, height: 34, decoration: const BoxDecoration(color: Color(0xFFFF8A65), shape: BoxShape.circle),
											child: const Icon(Icons.send_rounded, color: Colors.white, size: 17))),
									const SizedBox(width: 8),
									GestureDetector(
										onTap: () {},
										child: Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey[350]!)),
											child: const Center(child: Icon(Icons.add, color: Colors.grey, size: 18)))),
								],
							),
						),
					),
				],
			),
		);
	}
}
