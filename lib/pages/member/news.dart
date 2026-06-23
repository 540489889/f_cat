import 'package:flutter/material.dart';
import 'device_news.dart';

class NewsPage extends StatelessWidget {
	const NewsPage({super.key});

	@override
	Widget build(BuildContext context) {
		final items = [
			{
				'icon': Icons.pets,
				'iconColor': const Color(0xFFFF7A47),
				'bgColor': const Color(0xFFFF7A47).withValues(alpha: 0.1),
				'title': '宠物消息',
				'subtitle': '0 条消息',
				'type': 'pet',
			},
			{
				'icon': Icons.devices_other,
				'iconColor': const Color(0xFF4CAF50),
				'bgColor': const Color(0xFF4CAF50).withValues(alpha: 0.1),
				'title': '设备消息',
				'subtitle': '0 条消息',
				'type': 'device',
			},
			{
				'icon': Icons.notifications_outlined,
				'iconColor': const Color(0xFF5C8DFF),
				'bgColor': const Color(0xFF5C8DFF).withValues(alpha: 0.1),
				'title': '公告',
				'subtitle': '0 条消息',
				'type': 'notice',
			},
		];

		return Scaffold(
			backgroundColor: const Color(0xFFF5F5F5),
			appBar: AppBar(
				backgroundColor: Colors.white,
				elevation: 0,
				leading: IconButton(
					icon: const Icon(Icons.keyboard_arrow_left, color: Colors.black87, size: 34),
					onPressed: () => Navigator.of(context).maybePop(),
				),
				centerTitle: true,
				title: const Text('消息中心', style: TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.w500)),
			),
			body: ListView.separated(
				padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
				itemCount: items.length,
				separatorBuilder: (_, _) => const SizedBox(height: 10),
				itemBuilder: (context, index) {
					final item = items[index];
					return GestureDetector(
						onTap: () {
							Navigator.of(context).push(
								MaterialPageRoute(builder: (_) => DeviceNewsPage(type: item['type'] as String)),
							);
						},
						child: Container(
							decoration: BoxDecoration(
								color: Colors.white,
								borderRadius: BorderRadius.circular(14),
							),
							padding: const EdgeInsets.fromLTRB(18, 20, 14, 20),
							child: Row(
								children: [
									Container(
										width: 44,
										height: 44,
										decoration: BoxDecoration(color: item['bgColor'] as Color, borderRadius: BorderRadius.circular(12)),
										child: Icon(item['icon'] as IconData, color: item['iconColor'] as Color, size: 24),
									),
									const SizedBox(width: 14),
									Expanded(
										child: Column(
											crossAxisAlignment: CrossAxisAlignment.start,
											mainAxisSize: MainAxisSize.min,
											children: [
												Text('${item['title']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF222222))),
												const SizedBox(height: 3),
												Text('${item['subtitle']}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
											],
										),
									),
									const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
								],
							),
						),
					);
				},
			),
		);
	}
}
