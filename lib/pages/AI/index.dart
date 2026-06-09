import 'package:flutter/material.dart';

class AIPage extends StatefulWidget {
  const AIPage({super.key});

  @override
  State<AIPage> createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_MessageData> _messages = [
    _MessageData(
      isUser: false,
      content: '喵~你好！我是你的AI宠物小伙伴，随时陪你聊天、讲故事、记录宠物日常，还能给你暖心小建议~有什么需要，尽管告诉我哦！ (=^·ω·^=)',
    ),
    _MessageData(isUser: true, content: '你是什么模型？'),
    _MessageData(
      isUser: false,
      content: '"喵~你好！我是你的AI宠物小伙伴，随时陪你聊天、讲故事、记录宠物日常，还能给你暖心小建议~有什么需要，尽管告诉我哦！ (=^·ω·^=)"',
    ),
    _MessageData(isUser: true, content: '如何养一只狸花猫？'),
  ];

  final _quickTags = ['水量分析', '饮食建议', '今日心情', '健康周报'];

  void _sendMessage() {
    if (_textController.text.trim().isEmpty) return;
    setState(() {
      _messages.add(_MessageData(isUser: true, content: _textController.text.trim()));
      _messages.add(const _MessageData(isUser: false, isLoading: true));
    });
    _textController.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.keyboard_arrow_left, size: 34),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Smart Core',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Image.asset('assets/images/icon/add-1.png', width: 24, height: 24),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // 选择宠物栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ClipOval(
                  child: Image.asset('assets/images/pet_avatar.png', width: 24, height: 24, fit: BoxFit.cover),
                ),
                const SizedBox(width: 6),
                const Text(
                  '选择宠物',
                  style: TextStyle(fontSize: 14, color: Color(0xFF333333)),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF666666)),
              ],
            ),
          ),

          // 聊天内容区
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length + 1,
              itemBuilder: (context, index) {
                // 第一个位置放欢迎区域
                if (index == 0) {
                  return _buildWelcomeArea();
                }
                final msg = _messages[index - 1];
                return _buildMessageItem(msg);
              },
            ),
          ),

          // 底部输入区
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildWelcomeArea() {
    return Column(
      children: [
        const SizedBox(height: 20),
        // 头像
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFF7A45).withValues(alpha: 0.15),
          ),
          padding: const EdgeInsets.all(16),
          child: Image.asset('assets/images/icon/bluetooth-ico.png', fit: BoxFit.contain),
        ),
        const SizedBox(height: 20),
        const Text(
          '回答由AI生成，仅供参考',
          style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildMessageItem(_MessageData msg) {
    final isUser = msg.isUser;

    if (msg.isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Image.asset('assets/images/icon/bluetooth-ico.png', width: 28, height: 28),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'Smart Core 正在思考中...',
                style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
              ),
            ),
          ],
        ),
      );
    }

    if (isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(left: 50),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF7A45),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              msg.content,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset('assets/images/icon/bluetooth-ico.png', width: 28, height: 28),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(right: 50),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  msg.content,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF333333), height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 快捷标签
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickTags.map((tag) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE8D4C8)),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF8B6914)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            // 输入框
            Row(
              children: [
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.mic, size: 24, color: Color(0xFFBBBBBB)),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE8D4C8)),
                    ),
                    child: TextField(
                      controller: _textController,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: '有什么问题都可以问我哦~',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFF7A45),
                    ),
                    child: Center(
                      child: Image.asset('assets/images/icon/send-1.png', width: 20, height: 20),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageData {
  final bool isUser;
  final String content;
  final bool isLoading;
  const _MessageData({
    required this.isUser,
    this.content = '',
    this.isLoading = false,
  });
}
