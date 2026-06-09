import 'package:flutter/material.dart';

class AlbumPage extends StatelessWidget {
	const AlbumPage({super.key});

	@override
	Widget build(BuildContext context) {
		final images = [
			'https://images.unsplash.com/photo-1518791841217-8f162f1e1131?q=80&w=800&auto=format&fit=crop&ixlib=rb-4.0.3&s=2',
			'https://images.unsplash.com/photo-1518791841217-8f162f1e1131?q=80&w=800&auto=format&fit=crop&ixlib=rb-4.0.3&s=2',
			'https://images.unsplash.com/photo-1518020382113-a7e8fc38eac9?q=80&w=800&auto=format&fit=crop&ixlib=rb-4.0.3&s=3',
		];

		return Scaffold(
			backgroundColor: Colors.white,
			appBar: AppBar(
				backgroundColor: Colors.white,
				elevation: 0,
				leading: IconButton(
					icon: const Icon(Icons.keyboard_arrow_left, color: Color(0xFF222222), size: 34),
					onPressed: () => Navigator.of(context).maybePop(),
				),
				centerTitle: true,
				title: const Text(
					'我的相册',
					style: TextStyle(color: Color(0xFF222222), fontWeight: FontWeight.w600),
				),
			),
			body: SafeArea(
				child: DefaultTabController(
					length: 3,
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Container(
								color: Colors.white,
								child: TabBar(
									dividerColor: Colors.transparent,
									indicatorColor: const Color(0xFFFF6A40),
									labelColor: const Color(0xFF222222),
									unselectedLabelColor: const Color(0xFF9E9E9E),
									labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
									tabs: const [
										Tab(text: '图片'),
										Tab(text: '视频'),
										Tab(text: '每日精彩'),
									],
								),
							),
							const SizedBox(height: 12),
							const Padding(
								padding: EdgeInsets.symmetric(horizontal: 16.0),
								child: Text(
									'2026年5月',
									style: TextStyle(fontSize: 14, color: Color(0xFF222222)),
								),
							),
							const SizedBox(height: 12),
							Expanded(
								child: TabBarView(
									children: [
										// 图片页
										Padding(
											padding: const EdgeInsets.symmetric(horizontal: 16.0),
											child: GridView.count(
												crossAxisCount: 3,
												mainAxisSpacing: 12,
												crossAxisSpacing: 12,
												childAspectRatio: 1,
												children: List.generate(images.length, (index) {
													return _ImageCard(
														imageUrl: images[index],
														timestamp: index == 0 ? '05/24 18:36:24' : (index == 1 ? '05/22 18:36:24' : '05/20 18:36:24'),
													);
												}),
											),
										),
										// 视频页 placeholder
										const Center(child: Text('暂无视频')), 
										// 每日精彩 placeholder
										const Center(child: Text('每日精彩')),
									],
								),
							),
						],
					),
				),
			),
		);
	}
}

class _ImageCard extends StatelessWidget {
	final String imageUrl;
	final String timestamp;

	const _ImageCard({super.key, required this.imageUrl, required this.timestamp});

	@override
	Widget build(BuildContext context) {
		return ClipRRect(
			borderRadius: BorderRadius.circular(12),
			child: Stack(
				fit: StackFit.expand,
				children: [
					Image.network(imageUrl, fit: BoxFit.cover),
					Positioned(
						left: 4,
						bottom: 4,
						child: Container(
							padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
							decoration: BoxDecoration(
								color: Colors.black.withValues(alpha: 0.2),
								borderRadius: BorderRadius.circular(4),
							),
							child: Text(
								timestamp,
								style: const TextStyle(color: Colors.white, fontSize: 12),
							),
						),
					),
				],
			),
		);
	}
}

