import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/user_state.dart';
import '../../main.dart';
import '../../shared/toast.dart';

class BindMobilePage extends StatefulWidget {
  final String cacheKey;
  const BindMobilePage({super.key, required this.cacheKey});

  @override
  State<BindMobilePage> createState() => _BindMobilePageState();
}

class _BindMobilePageState extends State<BindMobilePage> {
  final _phoneCtrl = TextEditingController(text: '');
  final _codeCtrl = TextEditingController(text: '');
  bool _sending = false;
  bool _logining = false;
  int _secondsLeft = 0;

  bool get _canSubmit =>
      _phoneCtrl.text.trim().length == 11 &&
      _codeCtrl.text.trim().length == 6;

  void _sendCode() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length != 11) {
      _showSnack('请输入正确的手机号');
      return;
    }
    setState(() => _sending = true);
    final result = await AuthService.sendSmsCode(phone);
    if (mounted) {
      setState(() => _sending = false);
      _showSnack(result.message);
      if (result.isSuccess) {
        _secondsLeft = 60;
        _startCountdown();
      }
    }
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
        _startCountdown();
      }
    });
  }

  void _submit() async {
    final phone = _phoneCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    if (phone.length != 11) {
      _showSnack('请输入手机号');
      return;
    }
    if (code.length != 6) {
      _showSnack('请输入验证码');
      return;
    }
    setState(() => _logining = true);
    final result = await AuthService.bindMobile(
      cacheKey: widget.cacheKey,
      mobile: phone,
      code: code,
    );
    debugPrint('bindMobile 结果: ${result.isSuccess}, ${result.message}');
    if (!mounted) return;
    setState(() => _logining = false);
    if (result.isSuccess) {
      await context.read<UserState>().onLoginSuccess(
            accessToken: result.accessToken!,
            refreshToken: result.refreshToken!,
            expiresIn: result.expiresIn ?? 1800,
            userInfo: result.userInfo,
          );
      if (mounted) _onLoginDone();
    } else {
      _showSnack(result.message);
    }
  }

  void _onLoginDone() {
    globalWechatCallback = null;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    Toast.show(context, msg);
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.keyboard_arrow_left, size: 34),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '绑定手机号',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '为了您的账号安全，请绑定手机号码',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    const Text('+86',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        maxLength: 11,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          hintText: '手机号',
                          border: InputBorder.none,
                          counterText: '',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(28),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          hintText: '验证码',
                          border: InputBorder.none,
                          counterText: '',
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 12, thickness: 1,
                        color: Colors.grey),
                    TextButton(
                      onPressed:
                          _sending || _secondsLeft > 0 ? null : _sendCode,
                      child: Text(
                        _secondsLeft > 0
                            ? '${_secondsLeft}s后重试'
                            : _sending
                                ? '发送中...'
                                : '发送验证码',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_logining || !_canSubmit) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canSubmit
                        ? const Color(0xFFFF8A65)
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _logining
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          '绑定并登录',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
