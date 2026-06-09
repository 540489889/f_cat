import 'package:flutter/material.dart';

class SuccessPage extends StatelessWidget {
	final String? title;
	final String? price;
	final String? payMethod; // '微信支付' 或 '支付宝支付'

	const SuccessPage({super.key, this.title, this.price, this.payMethod});

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
				title: const Text('支付成功', style: TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.w500)),
			),
			body: Padding(
				padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
				child: SizedBox(
					width: double.infinity,
					child: Container(
						padding: const EdgeInsets.only(top: 52, bottom: 48),
					decoration: BoxDecoration(
						color: Colors.white,
						borderRadius: BorderRadius.circular(16),
					),
					child: Column(
						mainAxisSize: MainAxisSize.min,
						children: [
							SizedBox(
								width: 80,
								height: 72,
								child: Stack(
									alignment: Alignment.center,
									children: [
										Positioned(top: 0, left: 14, child: _buildDot(const Color(0xFFE8F5E9), 7)),
										Positioned(top: 6, right: 10, child: _buildDot(const Color(0xFFC8E6C9), 8)),
										Positioned(bottom: 2, left: 4, child: _buildDot(const Color(0xFFF1F8E9), 10)),
										Positioned(bottom: 10, right: 12, child: _buildDot(const Color(0xFFE8F5E9), 6)),
										Container(
											width: 54,
											height: 54,
											decoration: const BoxDecoration(
												color: Color(0xFF07C160),
												shape: BoxShape.circle,
											),
											child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
										),
									],
								),
							),
							const SizedBox(height: 22),
							const Text('支付成功', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: Color(0xFF222222))),
							const SizedBox(height: 10),
							Text('${payMethod ?? "微信支付"} \u00A5${price ?? "249"}.00', style: TextStyle(color: Colors.grey[500], fontSize: 13.5)),
							const SizedBox(height: 34),
							SizedBox(
								width: 150,
								height: 42,
								child: OutlinedButton(
									style: OutlinedButton.styleFrom(
										foregroundColor: const Color(0xFF222222),
										side: BorderSide(color: Colors.grey[400]!, width: 1),
										shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
									),
									onPressed: () {},
									child: const Text('查看订单', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
								),
							),
						],
					),
					),
				),
			),
		);
	}

	Widget _buildDot(Color color, double size) {
		return Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
	}
}
