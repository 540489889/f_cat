import 'package:flutter/material.dart';
import 'pay_order.dart';
import '../../services/mall_api_service.dart';

class ProductDetailsPage extends StatefulWidget {
	final int? id;
	final String? imageUrl;
	final String? title;
	final String? price;
	final String? origin;

	const ProductDetailsPage({
		super.key,
		this.id,
		this.imageUrl,
		this.title,
		this.price,
		this.origin,
	});

	@override
	State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
	MallProduct? _detail;
	bool _isLoading = false;

	@override
	void initState() {
		super.initState();
		if (widget.id != null) _loadDetail();
	}

	Future<void> _loadDetail() async {
		setState(() => _isLoading = true);
		final result = await MallApiService.getDeviceDetail(id: widget.id!);
		if (!mounted) return;
		setState(() {
			_isLoading = false;
			if (result.isSuccess) _detail = result.product;
		});
	}

	@override
	void dispose() {
		super.dispose();
	}

	String get _title => _detail?.title ?? widget.title ?? '';
	String get _priceStr => _detail?.price.toStringAsFixed(0) ?? widget.price ?? '0';
	String? get _originStr => _detail?.orgPrice?.toStringAsFixed(0) ?? widget.origin;
	String? get _imgUrl => _detail?.imglogo ?? widget.imageUrl;
	String get _subtitle => _detail?.subtitle ?? '';
	int get _sales => _detail?.sales ?? 0;
	int get _stock => _detail?.stock ?? 0;

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
					_title.isNotEmpty ? _title : '商品详情',
					style: const TextStyle(color: Color(0xFF222222), fontSize: 17, fontWeight: FontWeight.w500),
				),
			),
			body: _isLoading
				? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A47)))
				: Column(
						children: [
							Expanded(
								child: SingleChildScrollView(
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											// Image
											SizedBox(
												height: 320,
												child: Stack(
													alignment: Alignment.bottomCenter,
													children: [
														Image.network(
															_imgUrl ??
																'https://images.unsplash.com/photo-1592194996308-7b43878e84a6?q=800&w=800&auto=format&fit=crop',
															fit: BoxFit.cover,
															width: double.infinity,
															height: double.infinity,
															errorBuilder: (_, _, _) => Container(
																color: const Color(0xFFF0F0F0),
																child: const Center(child: Icon(Icons.image, color: Color(0xFFCCCCCC), size: 48)),
															),
														),
														if (_detail != null && _detail!.imgs != null)
															Positioned(
																bottom: 12,
																right: 16,
																child: Container(
																	padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
																	decoration: BoxDecoration(
																		color: Colors.black45,
																		borderRadius: BorderRadius.circular(14),
																	),
																	child: const Text('1 / 1', style: TextStyle(color: Colors.white, fontSize: 12)),
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
															crossAxisAlignment: CrossAxisAlignment.end,
															children: [
																Text(
																	'\u00A5$_priceStr',
																	style: const TextStyle(color: Color(0xFFFF2D2D), fontSize: 26, fontWeight: FontWeight.w700),
																),
																if (_originStr != null) ...[
																	const SizedBox(width: 8),
																	Text(
																		'\u00A5$_originStr',
																		style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 14, decoration: TextDecoration.lineThrough),
																	),
																],
																const Spacer(),
																Text('已售 $_sales', style: const TextStyle(color: Colors.grey, fontSize: 13)),
																const SizedBox(width: 6),
																Text('剩余 $_stock', style: const TextStyle(color: Colors.grey, fontSize: 13)),
															],
														),
														const SizedBox(height: 12),
														// Title + share
														Row(
															crossAxisAlignment: CrossAxisAlignment.start,
															children: [
																Expanded(
																	child: Text(
																		_title,
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
														if (_subtitle.isNotEmpty) ...[
															const SizedBox(height: 10),
															Container(
																padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
																decoration: BoxDecoration(color: const Color(0xFFFFE6E6), borderRadius: BorderRadius.circular(4)),
																child: Text(_subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFFFF2D2D))),
															),
														],
													],
												),
											),
											const SizedBox(height: 10),
											// Guarantee
											Container(
												margin: const EdgeInsets.symmetric(horizontal: 0),
												padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
												color: Colors.white,
												child: InkWell(
													onTap: () {},
													child: Column(
														crossAxisAlignment: CrossAxisAlignment.start,
														children: [
															Row(
																children: [
																	const Icon(Icons.verified, size: 20, color: Colors.green),
																	const SizedBox(width: 8),
																	const Text('放心购', style: TextStyle(color: Color(0xFF222222), fontSize: 15, fontWeight: FontWeight.w500)),
																],
															),
															const SizedBox(height: 6),
															Row(
																children: [
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
														],
													),
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
								child: SafeArea(
									top: false,
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
															productId: _detail?.id ?? widget.id ?? 0,
														),
													),
												);
											},
											child: const Text('立即购买', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
										),
									),
								),
							),
						],
					),
		);
	}
}
