import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/api_client.dart';
import 'add.dart';

/// 宠物介绍页（添加宠物第 2 步）
///
/// 用户可通过语音录制介绍宠物，
/// 录制完成后上传音频文件到后台。
class PetIntroducePage extends StatefulWidget {
  final String? headimg;
  final String? imgs;

  const PetIntroducePage({super.key, this.headimg, this.imgs});

  @override
  State<PetIntroducePage> createState() => _PetIntroducePageState();
}

class _PetIntroducePageState extends State<PetIntroducePage> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  bool _hasRecorded = false;
  String? _audioPath;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    try {
      await _recorder.openRecorder();
    } catch (e) {
      debugPrint('[PetIntroduce] 录音器初始化失败: $e');
    }
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('需要麦克风权限')),
        );
      }
      return;
    }

    final path = '${Directory.systemTemp.path}/pet_intro_${DateTime.now().millisecondsSinceEpoch}.aac';
    await _recorder.startRecorder(
      toFile: path,
      codec: Codec.aacADTS,
    );
    setState(() {
      _isRecording = true;
      _hasRecorded = false;
      _audioPath = null;
    });
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stopRecorder();
    if (path != null && path.isNotEmpty) {
      setState(() {
        _isRecording = false;
        _hasRecorded = true;
        _audioPath = path;
      });
      await _uploadAudio(path);
    } else {
      setState(() => _isRecording = false);
    }
  }

  Future<void> _uploadAudio(String filePath) async {
    setState(() => _uploading = true);

    final result = await ApiClient.instance.uploadFile(
      '/app/user/file/upload',
      filePath: filePath,
      fileField: 'file',
      extraFields: {'scene': 'voice'},
    );

    if (!mounted) return;

    setState(() => _uploading = false);

    if (result.isSuccess && result.data != null) {
      final url = result.data is String
          ? result.data as String
          : result.asMap['url']?.toString() ?? '';
      debugPrint('[PetIntroduce] 音频上传成功: $url');
    } else {
      debugPrint('[PetIntroduce] 音频上传失败: ${result.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('音频上传失败: ${result.message}')),
      );
    }
  }

  void _goToAddPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPetPage(
          headimg: widget.headimg,
          imgs: widget.imgs,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F4),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 顶部导航
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.keyboard_arrow_left,
                        color: Color(0xFF222222), size: 34),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        '添加宠物',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF222222),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 标题
            const Text(
              '先来介绍一下它',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 8),
            // 副标题
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                '你可以通过语音或手动输入来介绍它，\n帮助我们更准确的了解它。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF999999),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 语音内容卡片
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '语音内容',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF222222),
                            ),
                          ),
                          if (_isRecording || _uploading)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF7A47),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _uploading ? '上传中...' : '录音中',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFFF7A47),
                                  ),
                                ),
                              ],
                            ),
                          if (_hasRecorded && !_uploading)
                            const Text(
                              '录制完成',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF07C160),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _hasRecorded && _audioPath != null
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 40,
                                      color: const Color(0xFF07C160).withValues(alpha: 0.6),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      '语音录制完成',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF999999),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  '例如：它叫豆包，品种是比熊，性别是弟弟，2岁，体重15斤"',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFFCCCCCC),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 录音状态指示器
            if (_isRecording) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mic,
                    size: 20,
                    color: const Color(0xFFFF7A47).withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '正在录音...',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFFFF7A47).withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ] else if (_uploading) ...[
              const SizedBox(height: 24),
              const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFFF7A47),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else
              const SizedBox(height: 50),
            // 底部按钮
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _uploading
                        ? null
                        : (_isRecording ? _stopRecording : _startRecording),
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7A47),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Center(
                        child: Text(
                          _isRecording
                              ? '结束录音'
                              : _hasRecorded
                                  ? '重新录制'
                                  : '开始语音输入',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_isRecording)
                    GestureDetector(
                      onTap: _goToAddPage,
                      child: const Text(
                        '跳过',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFFF7A47),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
