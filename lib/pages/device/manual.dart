import 'package:flutter/material.dart';
import 'match.dart';

class ManualPage extends StatelessWidget {
	const ManualPage({super.key});

	@override
	Widget build(BuildContext context) {
		final deviceItems = [
			{'img': 'assets/images/device/device1.png', 'title': '智能猫砂盆 Smart'},
			{'img': 'assets/images/device/device2.png', 'title': '智能猫砂盆 Smart'},
			{'img': 'assets/images/device/device3.png', 'title': '智能猫砂盆 Smart'},
			{'img': 'assets/images/device/device1.png', 'title': '智能猫砂盆 Smart'},
		];

		return Scaffold(
			appBar: AppBar(
				backgroundColor: Colors.white,
				elevation: 0,
				leading: IconButton(
					icon: const Icon(Icons.arrow_back, color: Colors.black87),
					onPressed: () => Navigator.of(context).pop(),
				),
				centerTitle: true,
				title: const Text('手动连接', style: TextStyle(color: Colors.black87)),
			),
			body: SingleChildScrollView(
				padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						const Text('全自动扫描厕所', style: TextStyle(fontSize: 14, color: Colors.black87)),
						const SizedBox(height: 12),

						GridView.count(
							crossAxisCount: 2,
							mainAxisSpacing: 12,
							crossAxisSpacing: 12,
							childAspectRatio: 1.25,
							physics: const NeverScrollableScrollPhysics(),
							shrinkWrap: true,
							children: deviceItems.map((it) {
								return _DeviceCard(image: it['img']!, title: it['title']!);
							}).toList(),
						),

						const SizedBox(height: 18),
						const Text('智能饮水机', style: TextStyle(fontSize: 14, color: Colors.black87)),
						const SizedBox(height: 12),

						GridView.count(
							crossAxisCount: 2,
							mainAxisSpacing: 12,
							crossAxisSpacing: 12,
							childAspectRatio: 1.25,
							physics: const NeverScrollableScrollPhysics(),
							shrinkWrap: true,
							children: deviceItems.map((it) {
								return _DeviceCard(image: it['img']!, title: it['title']!);
							}).toList(),
						),
					],
				),
			),
			backgroundColor: const Color(0xFFF6F6F6),
		);
	}
}

class _DeviceCard extends StatelessWidget {
	final String image;
	final String title;

	const _DeviceCard({required this.image, required this.title, super.key});

	@override
	Widget build(BuildContext context) {
		return GestureDetector(
			onTap: () {
				Navigator.push(
					context,
					MaterialPageRoute(builder: (_) => const MatchPage()),
				);
			},
			child: Container(
				decoration: BoxDecoration(
					color: Colors.white,
					borderRadius: BorderRadius.circular(12),
					boxShadow: [BoxShadow(color: Colors.black12.withValues(alpha: 0.03), blurRadius: 6, spreadRadius: 1)],
				),
				padding: const EdgeInsets.all(12),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						ClipRRect(
							borderRadius: BorderRadius.circular(8),
							child: Image.asset(image, width: double.infinity, height: 88, fit: BoxFit.cover),
						),
						const SizedBox(height: 10),
						Text(title, style: const TextStyle(fontSize: 13, color: Colors.black87)),
					],
				),
			),
		);
	}
}
