import 'dart:async';
import 'package:flutter/material.dart';
import 'details.dart';

class MallPage extends StatefulWidget {
	const MallPage({super.key});

	@override
	State<MallPage> createState() => _MallPageState();
}

class _MallPageState extends State<MallPage> {
	final PageController _pageController = PageController();
	int _currentPage = 0;
	Timer? _timer;

	final List<Map<String, String>> _banners = [
		{
			'image': 'https://images.unsplash.com/photo-1543852786-1cf6624b9987?q=80&w=800&auto=format&fit=crop&ixlib=rb-4.0.3&s=4',
		},
		{
			'image': 'https://images.unsplash.com/photo-1592194996308-7b43878e84a6?q=80&w=800&auto=format&fit=crop&ixlib=rb-4.0.3&s=2',
		}
	];

	@override
	void initState() {
		super.initState();
		_startAutoPlay();
	}

	void _startAutoPlay() {
		_timer = Timer.periodic(const Duration(seconds: 3), (timer) {
			if (!mounted) return;
			final nextPage = (_currentPage + 1) % _banners.length;
			_pageController.animateToPage(
				nextPage,
				duration: const Duration(milliseconds: 4000),
				curve: Curves.easeInOut,
			);
		});
	}

	@override
	void dispose() {
		_timer?.cancel();
		_pageController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		final products = [
			{
				'id': '1',
				'title': '智能饮水机 PRO',
				'price': '249',
				'origin': '279',
				'image': 'https://images.unsplash.com/photo-1543852786-1cf6624b9987?q=80&w=800&auto=format&fit=crop&ixlib=rb-4.0.3&s=4'
			},
			{
				'id': '2',
				'title': '智能喂食器 Mini',
				'price': '249',
				'origin': '279',
				'image': 'https://images.unsplash.com/photo-1592194996308-7b43878e84a6?q=80&w=800&auto=format&fit=crop&ixlib=rb-4.0.3&s=2'
			},
			{
				'id': '3',
				'title': '智能猫砂盆 Smart',
				'price': '249',
				'origin': '279',
				'image': 'https://images.unsplash.com/photo-1546182990-dffeafbe841d?q=80&w=800&auto=format&fit=crop&ixlib=rb-4.0.3&s=3'
			}
		];

		return Scaffold(
			backgroundColor: const Color(0xFFF8F5F2),
			appBar: AppBar(
				backgroundColor: Colors.transparent,
				elevation: 0,
				leading: IconButton(
					icon: const Icon(Icons.keyboard_arrow_left, color: Color(0xFF222222), size: 34),
					onPressed: () => Navigator.of(context).maybePop(),
				),
				centerTitle: true,
				title: Column(
					children: const [
						Text(
							'宠物智能商城',
							style: TextStyle(color: Color(0xFF222222), fontWeight: FontWeight.w600),
						),
						SizedBox(height: 6),
						Text(
							'智能科技  宠爱相伴',
							style: TextStyle(color: Color(0xFFBFA79E), fontSize: 12),
						),
					],
				),
			),
			body: SingleChildScrollView(
				child: Padding(
					padding: const EdgeInsets.symmetric(horizontal: 16.0),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							const SizedBox(height: 8),
							// Banner carousel
							Column(
								children: [
									SizedBox(
										height: 188,
										child: PageView.builder(
											controller: _pageController,
											onPageChanged: (index) {
												setState(() {
													_currentPage = index;
												});
											},
											itemCount: _banners.length,
											itemBuilder: (context, index) {
												final banner = _banners[index];
												return Container(
													margin: const EdgeInsets.symmetric(horizontal: 2),
													decoration: BoxDecoration(
														borderRadius: BorderRadius.circular(16),
													),
													clipBehavior: Clip.antiAlias,
													// child: Image.network(
													// 	banner['image']!,
													// 	fit: BoxFit.cover,
													// 	width: double.infinity,
													// ),
                          child: Image.asset(
                            'assets/images/banner.png', // 你的本地图片路径
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
												);
											},
										),
									),
									const SizedBox(height: 10),
									// Dot indicators
									Row(
										mainAxisAlignment: MainAxisAlignment.center,
										children: List.generate(_banners.length, (index) {
											return AnimatedContainer(
												duration: const Duration(milliseconds: 300),
												margin: const EdgeInsets.symmetric(horizontal: 4),
												width: _currentPage == index ? 20 : 8,
												height: 8,
												decoration: BoxDecoration(
													color: _currentPage == index
														? const Color(0xFFFF8A65)
														: const Color(0xFFD9C5BD),
													borderRadius: BorderRadius.circular(4),
												),
											);
										}),
									),
								],
							),
							const SizedBox(height: 18),
							// All products header
							Row(
								mainAxisAlignment: MainAxisAlignment.spaceBetween,
								children: [
									const Text('全部商品', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
									Row(
										children: const [
											Icon(Icons.verified, color: Color(0xFFFF8A65), size: 18),
											SizedBox(width: 8),
											Text('正品保证', style: TextStyle(color: Color(0xFFFF8A65))),
											SizedBox(width: 12),
											Icon(Icons.local_shipping, color: Color(0xFFFF8A65), size: 18),
											SizedBox(width: 8),
											Text('快速配送', style: TextStyle(color: Color(0xFFFF8A65))),
										],
									)
								],
							),
							const SizedBox(height: 12),
							// Product list
							Column(
								children: products.map((p) {
									return Padding(
										padding: const EdgeInsets.only(bottom: 12.0),
										child: _ProductCard(
											title: p['title']!,
											price: p['price']!,
											origin: p['origin']!,
											imageUrl: p['image']!,
											onTap: () {
												Navigator.of(context).push(
													MaterialPageRoute(
														builder: (_) => ProductDetailsPage(
															imageUrl: p['image'],
															title: p['title'],
															price: p['price'],
															origin: p['origin'],
														),
													),
												);
											},
										),
									);
								}).toList(),
							),
							const SizedBox(height: 6),
							Center(
								child: Text('更多产品即将上线', style: TextStyle(color: Colors.grey[500])),
							),
							const SizedBox(height: 24),
						],
					),
				),
			),
		);
	}
}

class _ProductCard extends StatelessWidget {
	final String title;
	final String price;
	final String origin;
	final String imageUrl;
	final VoidCallback? onTap;

	const _ProductCard({required this.title, required this.price, required this.origin, required this.imageUrl, this.onTap});

	@override
	Widget build(BuildContext context) {
		return GestureDetector(
			onTap: onTap,
			child: Container(
				decoration: BoxDecoration(
					color: Colors.white,
					borderRadius: BorderRadius.circular(14),
				),
				padding: const EdgeInsets.all(12),
				child: Row(
					children: [
						ClipRRect(
							borderRadius: BorderRadius.circular(10),
							child: Image.network(imageUrl, width: 88, height: 88, fit: BoxFit.cover),
						),
						const SizedBox(width: 12),
						Expanded(
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
									const SizedBox(height: 8),
									Container(
										padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
										decoration: BoxDecoration(color: const Color(0xFFFFE6E6), borderRadius: BorderRadius.circular(4)),
										child: const Text('减30.00元', style: TextStyle(color: Color(0xFFFF2D2D))),
									),
									const SizedBox(height: 8),
									Row(
										crossAxisAlignment: CrossAxisAlignment.end,
										children: [
											Text('¥$price', style: const TextStyle(color: Color(0xFFFF2D2D), fontSize: 20, fontWeight: FontWeight.w700)),
											const SizedBox(width: 8),
											Text('¥$origin', style: const TextStyle(color: Color(0xFFBDBDBD), decoration: TextDecoration.lineThrough)),
										],
									),
								],
							),
						),
						const SizedBox(width: 8),
						Container(
							width: 34,
							height: 34,
							decoration: const BoxDecoration(color: Color(0xFFFF2D2D), shape: BoxShape.circle),
							child: const Icon(Icons.add, color: Colors.white),
						),
					],
				),
			),
		);
	}
}
