import 'package:flutter/material.dart';
import 'pay_order.dart';

class ProductDetailsPage extends StatefulWidget {
	final String? imageUrl;
	final String? title;
	final String? price;
	final String? origin;

	const ProductDetailsPage({
		super.key,
		this.imageUrl,
		this.title,
		this.price,
		this.origin,
	});

	@override
	State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
	int _currentImage = 0;
	final PageController _imageController = PageController();

	@override
	void dispose() {
		_imageController.dispose();
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
					icon: const Icon(Icons.keyboard_arrow_left, color: Colors.black87, size: 34),
					onPressed: () => Navigator.of(context).maybePop(),
				),
				centerTitle: true,
				title: Text(
					widget.title ?? '智能喂食器 Mini',
					style: const TextStyle(color: Color(0xFF222222), fontSize: 17, fontWeight: FontWeight.w500),
				),
			),
			body: Column(
				children: [
					Expanded(
						child: SingleChildScrollView(
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									// Image carousel
									SizedBox(
										height: 320,
										child: Stack(
											alignment: Alignment.bottomCenter,
											children: [
												PageView.builder(
													controller: _imageController,
													onPageChanged: (index) {
														setState(() {
															_currentImage = index;
														});
													},
													itemCount: 3,
													itemBuilder: (context, index) {
														return Image.network(
															widget.imageUrl ??
																'https://images.unsplash.com/photo-1592194996308-7b43878e84a6?q=800&w=800&auto=format&fit=crop',
															fit: BoxFit.cover,
															width: double.infinity,
															height: double.infinity,
														);
													},
												),
												// Image indicator
												Positioned(
													bottom: 12,
													right: 16,
													child: Container(
														padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
														decoration: BoxDecoration(
															color: Colors.black45,
															borderRadius: BorderRadius.circular(14),
														),
														child: Text(
															'${_currentImage + 1} / 3',
															style: const TextStyle(color: Colors.white, fontSize: 12),
														),
													),
												),
											],
										),
									),

									// Price & info card
									Container(
										padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
										color: Colors.white,
										child: Column(
											crossAxisAlignment: CrossAxisAlignment.start,
											children: [
												// Price row
												Row(
													crossAxisAlignment: CrossAxisAlignment.center,
													textBaseline: TextBaseline.alphabetic,
													children: [
														Text(
															'\u00A5${widget.price ?? "279"}',
															style: const TextStyle(color: Color(0xFFFF2D2D), fontSize: 26, fontWeight: FontWeight.w700),
														),
														const SizedBox(width: 10),
														Container(
															padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
															decoration: BoxDecoration(
																color: const Color(0xFFFF2D2D),
																borderRadius: BorderRadius.circular(4),
															),
															child: Row(
																mainAxisSize: MainAxisSize.min,
																children: [
																	const Text('券后价', style: TextStyle(color: Colors.white, fontSize: 11)),
																	Text(' \u00A5249', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
																],
															),
														),
														const Spacer(),
														Text('已售 ${widget.origin ?? "128"}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
														const SizedBox(width: 6),
														const Text('剩余 85', style: TextStyle(color: Colors.grey, fontSize: 13)),
													],
												),

												const SizedBox(height: 12),

												// Title + share
												Row(
													crossAxisAlignment: CrossAxisAlignment.start,
													children: [
														Expanded(
															child: Text(
																'智能喂食器 Mini 猫咪自动喂食器定时定量出粮小型宠物远程投食器',
																style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF222222), height: 1.4),
															),
														),
														const SizedBox(width: 8),
														GestureDetector(
															onTap: () {},
															child: Column(
																mainAxisSize: MainAxisSize.min,
																children: [
																	const Icon(Icons.share_outlined, size: 20, color: Colors.grey),
																	const SizedBox(height: 2),
																	Text('分享', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
																],
															),
														),
													],
												),

												const SizedBox(height: 14),

												// Coupon row
												// InkWell(
												// 	onTap: () {},
												// 	child: Container(
												// 		padding: const EdgeInsets.symmetric(vertical: 8),
												// 		decoration: BoxDecoration(
												// 			border: Border.all(color: const Color(0xFFFF2D2D).withValues(alpha: 0.3), width: 1),
												// 			borderRadius: BorderRadius.circular(6),
												// 		),
												// 		child: Row(
												// 			children: [
												// 				Container(
												// 					margin: const EdgeInsets.only(left: 8, right: 10),
												// 					padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
												// 					decoration: BoxDecoration(
												// 						border: Border.all(color: const Color(0xFFFF2D2D), width: 1),
												// 						borderRadius: BorderRadius.circular(4),
												// 					),
												// 					child: const Text('10元无门槛券', style: TextStyle(color: Color(0xFFFF2D2D), fontSize: 12, fontWeight: FontWeight.w500)),
												// 				),
												// 				const Spacer(),
												// 				const Text('领券', style: TextStyle(color: Colors.grey, fontSize: 13)),
												// 				const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
												// 			],
												// 		),
												// 	),
												// ),

												const SizedBox(height: 14),

												// Guarantee row
												InkWell(
													onTap: () {},
													child: Padding(
														padding: const EdgeInsets.only(bottom: 8),
														child: Row(
															children: [
																const Icon(Icons.verified, size: 20, color: Colors.green),
																const SizedBox(width: 8),
																const Text('放心购', style: TextStyle(color: Color(0xFF222222), fontSize: 15, fontWeight: FontWeight.w500)),
																const SizedBox(width: 8),
																Expanded(
																	child: Text(
																		'品质保证 · 准时发货 · 专属客服 · 先行赔付',
																		style: TextStyle(color: Colors.grey[600], fontSize: 12),
																		overflow: TextOverflow.ellipsis,
																	),
																),
																const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
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
					),

					// Bottom bar
					Container(
						padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
						color: Colors.white,
						child: SizedBox(
							width: double.infinity,
							height: 48,
							child: ElevatedButton(
								style: ElevatedButton.styleFrom(
									backgroundColor: const Color(0xFFFF5A3C),
									foregroundColor: Colors.white,
									elevation: 0,
									shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
								),
								onPressed: () {
									Navigator.of(context).push(
										MaterialPageRoute(
											builder: (_) => PayOrderPage(
												title: widget.title,
												price: widget.price,
												imageUrl: widget.imageUrl,
											),
										),
									);
								},
								child: const Text('立即购买', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
							),
						),
					),
				],
			),
		);
	}
}
