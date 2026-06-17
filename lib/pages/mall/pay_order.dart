import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'success.dart';
import 'address.dart';
import '../../services/mall_api_service.dart';
import '../../services/address_api_service.dart';
import '../../services/order_api_service.dart';

class PayOrderPage extends StatefulWidget {
	final int productId;

	const PayOrderPage({super.key, required this.productId});

	@override
	State<PayOrderPage> createState() => _PayOrderPageState();
}

class _PayOrderPageState extends State<PayOrderPage> {
	int _quantity = 1;
	int _payMethod = 0; // 0=微信, 1=支付宝
	int _remainingSeconds = 3598;
	int _selectedAddressIndex = 0;
	bool _isLoading = true;
	MallProduct? _product;
	Timer? _countdownTimer;
	final TextEditingController _remarkController = TextEditingController();
	final ValueNotifier<int> _countdownNotifier = ValueNotifier<int>(0);

	List<AddressItem> _addresses = [];

	double get _unitPrice => _product?.price ?? 0;
	double get _totalPrice => _unitPrice * _quantity;
	String get _productTitle => _product?.title ?? '商品';
	String? get _productImage => _product?.imglogo;

	@override
	void initState() {
		super.initState();
		_loadProduct();
		_loadAddresses();
	}

	Future<void> _loadProduct() async {
		final result = await MallApiService.getDeviceDetail(id: widget.productId);
		if (!mounted) return;
		setState(() {
			_isLoading = false;
			if (result.isSuccess) _product = result.product;
		});
	}

	Future<void> _loadAddresses() async {
		final result = await AddressApiService.getAddressList();
		if (!mounted) return;
		setState(() {
			_addresses = result.addresses;
		});
	}

	@override
	void dispose() {
		_remarkController.dispose();
		_countdownTimer?.cancel();
		_countdownNotifier.dispose();
		super.dispose();
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

	Future<void> _submitOrder() async {
		if (_addresses.isEmpty || _selectedAddressIndex >= _addresses.length) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('请先选择收货地址')),
			);
			return;
		}
		final addressId = _addresses[_selectedAddressIndex].id;
		final result = await OrderApiService.createOrder(
			deviceId: widget.productId,
			quantity: _quantity,
			addressId: addressId,
			remark: _remarkController.text.trim().isNotEmpty ? _remarkController.text.trim() : null,
		);
		if (!mounted) return;
		if (result.isSuccess) {
			_showPaySheet(orderSn: result.orderSn, totalPrice: result.totalPrice);
		} else {
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text(result.message)),
			);
		}
	}

	void _showAddressSheet() async {
		// 弹窗前先刷新地址列表
		final result = await AddressApiService.getAddressList();
		if (!mounted) return;
		if (result.isSuccess) {
			setState(() => _addresses = result.addresses);
		}

		if (!mounted) return;
		showModalBottomSheet(
			context: context,
			isScrollControlled: true,
			useSafeArea: true,
			backgroundColor: Colors.transparent,
			builder: (ctx) => StatefulBuilder(
				builder: (context, setSheetState) {
					return Container(
						decoration: const BoxDecoration(
							color: Colors.white,
							borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
						),
						child: Column(
							mainAxisSize: MainAxisSize.min,
							children: [
								// Title bar
								Padding(
									padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
									child: Stack(
										children: [
											const Center(
												child: Text(
													'选择收货地址',
													style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF222222)),
												),
											),
											Positioned(
												right: 0,
												child: GestureDetector(
													onTap: () => Navigator.pop(ctx),
													child: const Icon(Icons.close, color: Colors.grey),
												),
											),
										],
									),
								),
								const Divider(height: 0.5, color: Color(0xFFEEEEEE)),
								// Address list
								..._addresses.asMap().entries.map((entry) {
									final i = entry.key;
									final addr = entry.value;
									final isSelected = _selectedAddressIndex == i;
									return Slidable(
										key: Key('addr_${addr.id}'),
										endActionPane: ActionPane(
											extentRatio: 0.22,
											motion: const ScrollMotion(),
											children: [
												CustomSlidableAction(
													onPressed: (c) async {
														final confirm = await showDialog<bool>(
															context: c,
															builder: (ctx) => AlertDialog(
																backgroundColor: Colors.white,
																title: const Text('确认删除'),
																content: const Text('确定要删除该收货地址吗？'),
																actions: [
																	TextButton(
																		onPressed: () => Navigator.pop(ctx, false),
																		child: const Text('取消', style: TextStyle(color: Colors.grey)),
																	),
																	TextButton(
																		onPressed: () => Navigator.pop(ctx, true),
																		child: const Text('删除', style: TextStyle(color: Colors.red)),
																	),
																],
															),
														);
														if (confirm != true) return;
														final result = await AddressApiService.deleteAddress(id: addr.id);
														if (result.isSuccess) {
															setSheetState(() {
																_addresses.removeAt(i);
																if (_selectedAddressIndex >= _addresses.length) {
																	_selectedAddressIndex = (_addresses.length - 1).clamp(0, 999);
																}
															});
															setState(() {
																_addresses.removeAt(i);
																if (_selectedAddressIndex >= _addresses.length) {
																	_selectedAddressIndex = (_addresses.length - 1).clamp(0, 999);
																}
															});
														}
													},
													backgroundColor: Colors.red,
													child: const Column(
														mainAxisAlignment: MainAxisAlignment.center,
														children: [
															Icon(Icons.delete, color: Colors.white, size: 22),
															SizedBox(height: 4),
															Text('删除', style: TextStyle(color: Colors.white, fontSize: 12)),
														],
													),
												),
											],
										),
										child: Column(
										children: [
											GestureDetector(
												behavior: HitTestBehavior.opaque,
												onTap: () {
													setSheetState(() => _selectedAddressIndex = i);
													setState(() => _selectedAddressIndex = i);
													Navigator.pop(ctx);
												},
												child: Container(
													color: Colors.white,
													padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
													child: Row(
														crossAxisAlignment: CrossAxisAlignment.center,
														children: [
															// Radio
															Container(
																width: 20,
																height: 20,
																decoration: BoxDecoration(
																	shape: BoxShape.circle,
																	color: isSelected ? const Color(0xFFFF8A65) : Colors.transparent,
																	border: Border.all(
																		color: isSelected ? const Color(0xFFFF8A65) : Colors.grey[300]!,
																		width: 2,
																	),
																),
																child: isSelected
																	? const Icon(Icons.check, color: Colors.white, size: 12)
																	: null,
															),
															const SizedBox(width: 12),
															// Content
															Expanded(
																child: Column(
																	crossAxisAlignment: CrossAxisAlignment.start,
																	children: [
																		Row(
																			children: [
																				Text(
																					addr.name,
																					style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF222222)),
																				),
																				const SizedBox(width: 12),
																				Text(
																					addr.phone,
																					style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
																				),
																				const Spacer(),
																				if (addr.isDefault)
																					Container(
																						padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
																						decoration: BoxDecoration(
																							color: const Color(0xFFFF8A65).withValues(alpha: 0.12),
																							borderRadius: BorderRadius.circular(4),
																						),
																						child: const Text('默认', style: TextStyle(color: Color(0xFFFF8A65), fontSize: 11)),
																					),
																			],
																		),
																		const SizedBox(height: 6),
																		Text(
																			addr.region + ' ' + addr.detail,
																			style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
																		),
																	],
																),
															),
															const SizedBox(width: 8),
															GestureDetector(
																onTap: () async {
																	Navigator.pop(ctx);
																	await Navigator.of(context).push(
																		MaterialPageRoute(
																			builder: (_) => AddressEditPage(address: addr),
																		),
																	);
																	_loadAddresses();
																},
																child: const Padding(
																	padding: EdgeInsets.all(4),
																	child: Icon(Icons.edit_outlined, size: 18, color: Color(0xFF999999)),
																),
															),
														],
													),
												),
											),
											if (i != _addresses.length - 1)
												const Padding(
													padding: EdgeInsets.only(left: 52),
													child: Divider(height: 0.5, color: Color(0xFFEEEEEE)),
												),
										],
									),
								);
								}),
								const SizedBox(height: 10),
								// Add new address button
								SafeArea(
									top: false,
									child: Padding(
										padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
										child: SizedBox(
											width: double.infinity,
											height: 44,
											child: OutlinedButton(
												style: OutlinedButton.styleFrom(
													foregroundColor: const Color(0xFFFF8A65),
													side: const BorderSide(color: Color(0xFFFF8A65)),
													shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
												),
												onPressed: () async {
													Navigator.pop(ctx);
													await Navigator.of(context).push(
														MaterialPageRoute(builder: (_) => const AddressEditPage()),
													);
													_loadAddresses();
												},
												child: const Text('添加新地址', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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

	void _showPaySheet({String orderSn = '', double totalPrice = 0}) {
		_remainingSeconds = 3598;
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
											Text('\u00A5${totalPrice.toStringAsFixed(0)}.00', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: Color(0xFF222222))),
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
									child: Text('订单号：$orderSn', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
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
															title: _productTitle,
															price: _totalPrice.toStringAsFixed(0),
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
			body: _isLoading
				? const Center(child: CircularProgressIndicator(color: Color(0xFFFF8A65)))
				: Column(
				children: [
					Expanded(
						child: SingleChildScrollView(
							child: Column(
								children: [
									// Address + Shipping card
									Container(
										margin: const EdgeInsets.all(12),
										padding: const EdgeInsets.all(16),
										decoration: BoxDecoration(
											color: Colors.white,
											borderRadius: BorderRadius.circular(12),
										),
										child: Column(
											children: [
												// Address
												GestureDetector(
													onTap: _addresses.isEmpty
														? () async {
																await Navigator.of(context).push(
																	MaterialPageRoute(builder: (_) => const AddressEditPage()),
																);
																_loadAddresses();
															}
														: _showAddressSheet,
													behavior: HitTestBehavior.opaque,
													child: _addresses.isEmpty
														? const Row(
																children: [
																	Icon(Icons.location_on_outlined, size: 22, color: Color(0xFFFF8A65)),
																	SizedBox(width: 10),
																	Text('添加收货地址', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF222222))),
																	Spacer(),
																	Icon(Icons.add, color: Color(0xFFFF8A65), size: 22),
																],
															)
														: IntrinsicHeight(
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
																						_addresses[_selectedAddressIndex].detail.length > 15
																							? '${_addresses[_selectedAddressIndex].detail.substring(0, 15)}...'
																							: _addresses[_selectedAddressIndex].detail,
																						style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF222222)),
																					),
																					const SizedBox(height: 4),
																					Text(
																						'${_addresses[_selectedAddressIndex].name}  ${_addresses[_selectedAddressIndex].phone}',
																						style: const TextStyle(color: Colors.grey, fontSize: 13),
																					),
																				],
																			),
																		),
																		const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
																	],
																),
															),
												),
												const Padding(
													padding: EdgeInsets.symmetric(vertical: 12),
													child: Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
												),
												// Shipping
												Row(
													children: [
														const Icon(Icons.inventory_2_outlined, size: 20, color: Colors.black87),
														const SizedBox(width: 10),
														const Text('快递', style: TextStyle(fontSize: 14, color: Colors.black87)),
														const Spacer(),
														const Text('免运费', style: TextStyle(fontSize: 13, color: Colors.black87)),
													],
												),
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
																_productImage ?? '',
																width: 88,
																height: 88,
																fit: BoxFit.cover,
																errorBuilder: (_, __, ___) => Container(width: 88, height: 88, color: const Color(0xFFF0F0F0)),
															),
														),
														const SizedBox(width: 12),
														Expanded(
															child: Column(
																crossAxisAlignment: CrossAxisAlignment.start,
																children: [
																	Text(
																		_productTitle,
																		style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF222222), height: 1.35),
																	),
																	const SizedBox(height: 2),
																	Text('型号：${_product?.model ?? ''}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
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
                            	const Spacer(),
														Text('\u00A5${_unitPrice.toStringAsFixed(0)}', style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w700)),
															const SizedBox(width: 60),
														GestureDetector(
															onTap: () => setState(() { if (_quantity > 1) _quantity--; }),
															child: Container(
																width: 28,
																height: 28,
																decoration: BoxDecoration(border: Border.all(color: Colors.grey[400]!), borderRadius: BorderRadius.circular(4)),
																child: const Center(child: Text('-', style: TextStyle(color: Colors.grey))),
															),
														),
														const SizedBox(width: 5),
														SizedBox(
															width: 32,
															child: Text('$_quantity', textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
														),
														const SizedBox(width: 5),
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
												const SizedBox(height: 12),
												const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
												const SizedBox(height: 12),
												Row(
													children: [
														const Icon(Icons.verified, size: 20, color: Colors.green),
														const SizedBox(width: 8),
														const Text('放心购', style: TextStyle(color: Colors.green, fontSize: 15, fontWeight: FontWeight.w500)),
														const Spacer(),
														const Text('商家赠送', style: TextStyle(color: Colors.black54, fontSize: 13)),
														const SizedBox(width: 4),
														const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
													],
												),
											],
										),
									),

									// Price summary + Remark
									Container(
										margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
										padding: const EdgeInsets.all(16),
										decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
										child: Column(
											children: [
												_buildPriceRow('商品总价', '共 $_quantity 件商品', '\u00A5${_totalPrice.toStringAsFixed(0)}.00'),
												const Padding(
													padding: EdgeInsets.symmetric(vertical: 12),
													child: Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
												),
												Row(
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
									Text('\u00A5${_totalPrice.toStringAsFixed(0)}.00', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFFFF2D2D))),
									const Spacer(),
									ElevatedButton(
										style: ElevatedButton.styleFrom(
											backgroundColor: const Color(0xFFFF4D26),
											foregroundColor: Colors.white,
											elevation: 0,
											padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 13),
											shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
										),
										onPressed: _submitOrder,
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
