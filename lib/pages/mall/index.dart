import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'details.dart';
import '../../config/route_map.dart';
import '../../main.dart';
import '../../services/mall_api_service.dart';
import '../../services/banner_api_service.dart';

class MallPage extends StatefulWidget {
	const MallPage({super.key});

	@override
	State<MallPage> createState() => _MallPageState();
}

class _MallPageState extends State<MallPage> {
	int _currentPage = 0;
	final CarouselSliderController _carouselController = CarouselSliderController();

	List<MallProduct> _products = [];
	bool _isLoading = true;
	String? _errorMsg;

	final List<BannerItem> _banners = [];

	void _loadBanners() {
		BannerApiService.getAdsByPosition(position: 'mall').then((result) {
			if (!mounted) return;
			if (result.isSuccess) {
				setState(() {
					_banners.clear();
					_banners.addAll(result.banners);
				});
				return;
			}
			// 接口失败用默认数据兜底
			setState(() {
				_banners.clear();
				_banners.addAll([
					BannerItem(image: 'assets/images/banner.png', linkType: 'page', url: 'productDetail?id=1'),
					BannerItem(image: 'assets/images/banner.png', linkType: 'page', url: 'addPet'),
					BannerItem(image: 'assets/images/banner.png', linkType: 'h5', url: 'https://www.baidu.com'),
				]);
			});
		});
	}

	void _onBannerTap(BannerItem item) {
		if (item.linkType == 'page' && item.url != null) {
			// 通用页面路由：后端传 url 如 "addPet"、"productDetail?id=1"
			AppRoutes.navigateTo(context, item.url!);
		} else if (item.linkType == 'h5' && item.url != null) {
			launchUrl(Uri.parse(item.url!), mode: LaunchMode.externalApplication);
		} else if (item.linkType == 'device') {
			HomeShell.globalKey.currentState?.switchToTab(2);
			Navigator.of(context).popUntil((route) => route.isFirst);
		} else if (item.linkType == 'home') {
			Navigator.of(context).popUntil((route) => route.isFirst);
		}
	}

	@override
	void initState() {
		super.initState();
		_loadBanners();
		_loadProducts();
	}

	Future<void> _loadProducts() async {
		setState(() {
			_isLoading = true;
			_errorMsg = null;
		});
		final result = await MallApiService.getProductList();
		if (!mounted) return;
		setState(() {
			_isLoading = false;
			if (result.isSuccess) {
				_products = result.products;
			} else {
				_errorMsg = result.message;
			}
		});
	}

	Widget _buildBannerImage(String image) {
		if (image.isEmpty) return Image.asset('assets/images/banner.png', fit: BoxFit.cover, width: double.infinity);
		if (image.startsWith('http')) {
			return Image.network(image, fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => Image.asset('assets/images/banner.png', fit: BoxFit.cover, width: double.infinity));
		}
		return Image.asset(image, fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => Image.asset('assets/images/banner.png', fit: BoxFit.cover, width: double.infinity));
	}

	@override
	void dispose() {
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
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
							if (_banners.isNotEmpty)
								CarouselSlider(
									carouselController: _carouselController,
									options: CarouselOptions(
										height: 188,
										autoPlay: true,
										autoPlayInterval: const Duration(seconds: 3),
										autoPlayAnimationDuration: const Duration(milliseconds: 800),
										enlargeCenterPage: true,
										viewportFraction: 1,
										onPageChanged: (index, _) => setState(() => _currentPage = index),
									),
									items: _banners.map((banner) {
										return GestureDetector(
											onTap: () => _onBannerTap(banner),
											child: Container(
												margin: const EdgeInsets.symmetric(horizontal: 4),
												decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
												clipBehavior: Clip.antiAlias,
												child: _buildBannerImage(banner.image),
											),
										);
									}).toList(),
								),
							if (_banners.length > 1) ...[
								const SizedBox(height: 10),
								Row(
									mainAxisAlignment: MainAxisAlignment.center,
									children: List.generate(_banners.length, (index) {
										return AnimatedContainer(
											duration: const Duration(milliseconds: 300),
											margin: const EdgeInsets.symmetric(horizontal: 4),
											width: _currentPage == index ? 20 : 8,
											height: 8,
											decoration: BoxDecoration(
												color: _currentPage == index ? const Color(0xFFFF8A65) : const Color(0xFFD9C5BD),
												borderRadius: BorderRadius.circular(4),
											),
										);
									}),
								),
							],
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
							if (_isLoading)
								const Padding(
									padding: EdgeInsets.only(top: 60, bottom: 60),
									child: Center(child: CircularProgressIndicator(color: Color(0xFFFF8A65))),
								)
							else if (_errorMsg != null)
								Padding(
									padding: const EdgeInsets.only(top: 60, bottom: 60),
									child: Center(
										child: Column(
											children: [
												Text(_errorMsg!, style: const TextStyle(color: Color(0xFF999999))),
												const SizedBox(height: 12),
												TextButton(
													onPressed: _loadProducts,
													child: const Text('点此重试'),
												),
											],
										),
									),
								)
							else
								..._products.map((p) {
									return Padding(
										padding: const EdgeInsets.only(bottom: 12.0),
										child: _ProductCard(
											title: p.title,
											subtitle: p.subtitle ?? '',
											price: p.price.toStringAsFixed(0),
											origin: p.orgPrice?.toStringAsFixed(0) ?? '',
											model: p.model ?? '',
											imageUrl: p.imglogo ?? '',
											onTap: () {
												Navigator.of(context).push(
													MaterialPageRoute(
														builder: (_) => ProductDetailsPage(
															id: p.id,
															imageUrl: p.imglogo,
															title: p.title,
															price: p.price.toStringAsFixed(0),
															origin: p.orgPrice?.toStringAsFixed(0),
														),
													),
												);
											},
										),
									);
								}),
							const SizedBox(height: 6),
							if (!_isLoading && _errorMsg == null)
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
	final String subtitle;
	final String price;
	final String origin;
	final String model;
	final String imageUrl;
	final VoidCallback? onTap;

	const _ProductCard({required this.title, this.subtitle = '', required this.price, required this.origin, this.model = '', required this.imageUrl, this.onTap});

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
							child: Image.network(
								imageUrl,
								width: 88,
								height: 88,
								fit: BoxFit.cover,
								errorBuilder: (_, __, ___) => Container(
									width: 88,
									height: 88,
									color: const Color(0xFFF0F0F0),
									child: const Icon(Icons.image, color: Color(0xFFCCCCCC)),
								),
							),
						),
						const SizedBox(width: 12),
						Expanded(
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
									const SizedBox(height: 8),
									if (subtitle.isNotEmpty)
										Container(
											padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
											decoration: BoxDecoration(color: const Color(0xFFFFE6E6), borderRadius: BorderRadius.circular(4)),
											child: Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFFFF2D2D))),
										),
									const SizedBox(height: 8),
									if (model.isNotEmpty)
										Text('型号：$model', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
									const SizedBox(height: 4),
									Row(
										children: [
											Flexible(
												child: Text('¥$price', style: const TextStyle(color: Color(0xFFFF2D2D), fontSize: 18, fontWeight: FontWeight.w700)),
											),
											if (origin.isNotEmpty) ...[
												const SizedBox(width: 6),
												Flexible(
													child: Text('¥$origin', style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 12, decoration: TextDecoration.lineThrough)),
												),
											],
										],
									),
								],
							),
						),
						const SizedBox(width: 8),
						// Container(
						// 	width: 30,
						// 	height: 30,
						// 	decoration: const BoxDecoration(color: Color(0xFFFF2D2D), shape: BoxShape.circle),
						// 	child: const Icon(Icons.add, color: Colors.white, size: 18),
						// ),
					],
				),
			),
		);
	}
}


