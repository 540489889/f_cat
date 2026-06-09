import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'success.dart';

class PayOrderPage extends StatefulWidget {
	final String? title;
	final String? price;
	final String? imageUrl;

	const PayOrderPage({super.key, this.title, this.price, this.imageUrl});

	@override
	State<PayOrderPage> createState() => _PayOrderPageState();
}

class _PayOrderPageState extends State<PayOrderPage> {
	int _quantity = 1;
	int _payMethod = 0; // 0=微信, 1=支付宝
	int _remainingSeconds = 3598; // 00:59:58
	Timer? _countdownTimer;
	final TextEditingController _remarkController = TextEditingController();
	final ValueNotifier<int> _countdownNotifier = ValueNotifier<int>(0);

	@override
	void dispose() {
		_remarkController.dispose();
		_countdownTimer?.cancel();
		_countdownNotifier.dispose();
		super.dispose();
	}

	String get _orderNo {
		final r = Random();
		return List.generate(16, (_) => r.nextInt(10).toString()).join();
	}

	String get _countdownText {
		final h = _remainingSeconds ~/ 3600;
		final m = (_remainingSeconds % 3600) ~/ 60;
		final s = _remainingSeconds % 60;
		return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
	}

	void _startCountdown() {
		_countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
			if (_remainingSeconds <= 0) {
				timer.cancel();
				Navigator.of(context).maybePop();
				return;
			}
			setState(() => _remainingSeconds--);
			_countdownNotifier.value++;
		});
	}

	void _showPaySheet() {
		setState(() => _remainingSeconds = 3598);
		showModalBottomSheet(
			context: context,
			isScrollControlled: true,
			useSafeArea: true,
			backgroundColor: Colors.transparent,
			builder: (ctx) => StatefulBuilder(
				builder: (context, setBottomState) {
					if (_countdownTimer == null || !_countdownTimer!.isActive) _startCountdown();
					return Container(
						decoration: const BoxDecoration(
							color: Colors.white,
							borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
						),
						child: Column(
							mainAxisSize: MainAxisSize.min,
							children: [
								Padding(
									padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
									child: Stack(
                  children: [
                    
                    const Center(
                      child: Text(
                        '支付详情',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF222222),
                        ),
                      ),
                    ),
                    // 关闭按钮放右边
                    Positioned(
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          _countdownTimer?.cancel();
                          Navigator.pop(ctx);
                        },
                        child: const Icon(Icons.close, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
								),
								Divider(height: 0.5, color: Colors.grey[200]),
								Center(
									child: Column(
										children: [
											const SizedBox(height: 24),
											Text('\u00A5${widget.price ?? "249"}.00', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: Color(0xFF222222))),
											ListenableBuilder(
												listenable: _countdownNotifier,
												builder: (_, _) {
													return Text('剩余支付时间：$_countdownText', style: TextStyle(color: Colors.grey[500], fontSize: 13));
												},
											),
										],
									),
								),
								const SizedBox(height: 28),
								Padding(
									padding: const EdgeInsets.symmetric(horizontal: 20),
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											const Text('选支付方式', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF222222))),
											const SizedBox(height: 14),
											_payOption(ctx, setBottomState, 0, 'assets/images/icon/pay-1.png', '微信支付'),
											const SizedBox(height: 12),
											_payOption(ctx, setBottomState, 1, 'assets/images/icon/pay-2.png', '支付宝支付'),
										],
									),
								),
								const SizedBox(height: 14),
								Padding(
									padding: const EdgeInsets.only(bottom: 6),
									child: Text('订单信息：$_orderNo', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
								),
								const SizedBox(height: 10),
								SafeArea(
									top: false,
									child: Padding(
										padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
										child: SizedBox(
											width: double.infinity,
											height: 48,
											child: ElevatedButton(
												style: ElevatedButton.styleFrom(
													backgroundColor: const Color(0xFFFF4D26),
													foregroundColor: Colors.white,
													elevation: 0,
													shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
												),
												onPressed: () {
													_countdownTimer?.cancel();
													Navigator.of(ctx).pop();
													final method = _payMethod == 0 ? '微信支付' : '支付宝支付';
													Navigator.of(context).push(MaterialPageRoute(
														builder: (_) => SuccessPage(
															title: widget.title,
															price: widget.price,
															payMethod: method,
														),
													));
												},
												child: const Text('确认支付', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
											),
										),
									),
								),
							],
						),
					);
				},
			),
		);
	}

	Widget _payOption(BuildContext ctx, StateSetter setState, int index, String imagePath, String label) {
		return GestureDetector(
			onTap: () { setState(() => _payMethod = index); },
			child: Container(
				padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
				decoration: BoxDecoration(
					border: Border.all(color: _payMethod == index ? const Color(0xFFFF8A65) : Colors.grey[300]!),
					borderRadius: BorderRadius.circular(10),
				),
				child: Row(
					children: [
						Image.asset(imagePath, width: 24, height: 24),
						const SizedBox(width: 10),
						Text(label, style: const TextStyle(fontSize: 15, color: Color(0xFF222222))),
						const Spacer(),
						_payMethod == index
							? Container(
								width: 22,
								height: 22,
								decoration: const BoxDecoration(
									color: Color(0xFFFF8A65),
									shape: BoxShape.circle,
								),
								child: const Icon(Icons.check, color: Colors.white, size: 14),
							)
							: Container(
								width: 22,
								height: 22,
								decoration: BoxDecoration(
									shape: BoxShape.circle,
									border: Border.all(color: Colors.grey),
								),
							),
					],
				),
			),
		);
	}

	@override
	Widget build(BuildContext context) {
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
				title: const Text('确认订单', style: TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.w500)),
			),
			body: Column(
				children: [
					Expanded(
						child: SingleChildScrollView(
							child: Column(
								children: [
									// Address card
									Container(
										margin: const EdgeInsets.all(12),
										padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
										decoration: BoxDecoration(
											color: Colors.white,
											borderRadius: BorderRadius.circular(12),
										),
										child: IntrinsicHeight(
											child: Row(
												children: [
													Container(
														padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
														decoration: BoxDecoration(
															color: const Color(0xFFFF8A65).withValues(alpha: 0.15),
															borderRadius: BorderRadius.circular(4),
														),
														child: const Text('默认', style: TextStyle(color: Color(0xFFFF8A65), fontSize: 11)),
													),
													const SizedBox(width: 10),
													Expanded(
														child: Column(
															crossAxisAlignment: CrossAxisAlignment.start,
															mainAxisSize: MainAxisSize.min,
															children: [
																Text(
																	'重庆市南岸区光明路18号东原·翡...',
																	style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF222222)),
																),
																const SizedBox(height: 4),
																const Text(
																	'李德胜  182****3210',
																	style: TextStyle(color: Colors.grey, fontSize: 13),
																),
															],
														),
													),
													const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
												],
											),
										),
									),

									// Shipping info
									Container(
										margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
										padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
										decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
										child: Row(
											children: [
												const Icon(Icons.inventory_2_outlined, size: 20, color: Colors.black87),
												const SizedBox(width: 10),
												const Text('快递', style: TextStyle(fontSize: 14, color: Colors.black87)),
												const Spacer(),
												const Text('免运费', style: TextStyle(fontSize: 13, color: Colors.black87)),
											],
										),
									),

									// Product card
									Container(
										margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
										padding: const EdgeInsets.all(16),
										decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
										child: Column(
											crossAxisAlignment: CrossAxisAlignment.start,
											children: [
												Row(
													crossAxisAlignment: CrossAxisAlignment.start,
													children: [
														ClipRRect(
															borderRadius: BorderRadius.circular(10),
															child: Image.network(
																widget.imageUrl ?? 'https://images.unsplash.com/photo-1592194996308-7b43878e84a6?q=800&w=800&auto=format&fit=crop',
																width: 88,
																height: 88,
																fit: BoxFit.cover,
															),
														),
														const SizedBox(width: 12),
														Expanded(
															child: Column(
																crossAxisAlignment: CrossAxisAlignment.start,
																children: [
																	Text(
																		widget.title ?? '智能喂食器 Mini 猫咪自动喂食器定时定量出粮小型宠物远程投食器',
																		style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF222222), height: 1.35),
																	),
																	const SizedBox(height: 2),
																	Text(widget.title?.split(' ')[0] ?? '智能喂食器 Mini', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
																	const SizedBox(height: 6),
																	Container(
																		padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
																		decoration: BoxDecoration(
																			color: const Color(0xFFE8F5E9),
																			borderRadius: BorderRadius.circular(4),
																		),
																		child: const Text('7天无理由退货', style: TextStyle(color: Colors.green, fontSize: 11)),
																	),
																],
															),
														),
													],
												),
												const SizedBox(height: 14),
												Row(
													children: [
														Text('\u00A5${widget.price ?? "249"}', style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w700)),
														const Spacer(),
														GestureDetector(
															onTap: () => setState(() { if (_quantity > 1) _quantity--; }),
															child: Container(
																width: 28,
																height: 28,
																decoration: BoxDecoration(border: Border.all(color: Colors.grey[400]!), borderRadius: BorderRadius.circular(4)),
																child: const Center(child: Text('-', style: TextStyle(color: Colors.grey))),
															),
														),
														const SizedBox(width: 18),
														SizedBox(
															width: 32,
															child: Text('$_quantity', textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
														),
														const SizedBox(width: 18),
														GestureDetector(
															onTap: () => setState(() { _quantity++; }),
															child: Container(
																width: 28,
																height: 28,
																decoration: BoxDecoration(border: Border.all(color: Colors.grey[400]!), borderRadius: BorderRadius.circular(4)),
																child: const Center(child: Text('+', style: TextStyle(color: Colors.grey))),
															),
														),
													],
												),
											],
										),
									),

									// Guarantee row
									Container(
										margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
										padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
										decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
										child: Row(
											children: [
												const Icon(Icons.verified, size: 22, color: Colors.green),
												const SizedBox(width: 8),
												const Text('放心购', style: TextStyle(color: Colors.green, fontSize: 15, fontWeight: FontWeight.w500)),
												const Spacer(),
												const Text('商家赠送', style: TextStyle(color: Colors.black54, fontSize: 13)),
												const SizedBox(width: 4),
												const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
											],
										),
									),

									// Price summary
									Container(
										margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
										padding: const EdgeInsets.all(16),
										decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
										child: Column(
											children: [
												_buildPriceRow('商品总价', '共 1 件商品', '\u00A5${widget.price ?? "249"}.00'),
												Padding(
													padding: const EdgeInsets.symmetric(vertical: 14),
													child: Divider(height: 0.5, thickness: 0.5, color: Colors.grey[300]),
												),
												Row(
													children: [
														const Text('优惠券', style: TextStyle(fontSize: 14, color: Colors.black87)),
														const Spacer(),
														const Text('暂无可用', style: TextStyle(color: Colors.grey, fontSize: 13)),
														const SizedBox(width: 4),
														const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
													],
												),
											],
										),
									),

									// Remark input
									Container(
										margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
										padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
										decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
										child: Row(
											crossAxisAlignment: CrossAxisAlignment.start,
											children: [
												const Padding(
													padding: EdgeInsets.only(top: 2),
													child: Text('订单备注', style: TextStyle(fontSize: 14, color: Colors.black87)),
												),
												const SizedBox(width: 12),
												Expanded(
													child: TextField(
														controller: _remarkController,
														maxLength: 250,
														buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
														decoration: InputDecoration.collapsed(hintText: '备注建议提前协商（250字以内）', hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13)),
														style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
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
						padding: const EdgeInsets.fromLTRB(16, 10, 16, 34),
						color: Colors.white,
						child: SafeArea(
							top: false,
							child: Row(
								children: [
									const Text('应付：', style: TextStyle(fontSize: 14, color: Colors.black87)),
									Text('\u00A5${widget.price ?? "249"}.00', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFFFF2D2D))),
									const Spacer(),
									ElevatedButton(
										style: ElevatedButton.styleFrom(
											backgroundColor: const Color(0xFFFF4D26),
											foregroundColor: Colors.white,
											elevation: 0,
											padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 13),
											shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
										),
										onPressed: _showPaySheet,
										child: const Text('提交订单', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
									),
								],
							),
						),
					),
				],
			),
		);
	}

	Widget _buildPriceRow(String label, String subLabel, String value) {
		return Row(
			children: [
				Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
				const SizedBox(width: 6),
				Text(subLabel, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
				const Spacer(),
				Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
			],
		);
	}
}
