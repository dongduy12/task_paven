import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../controllers/task_controller.dart';
import '../../models/task.dart';
import '../../services/gemini_service.dart';
import '../theme.dart';

class AssistantMessage {
  const AssistantMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

class GeminiAssistantPage extends StatefulWidget {
  const GeminiAssistantPage({super.key});

  @override
  State<GeminiAssistantPage> createState() => _GeminiAssistantPageState();
}

class _GeminiAssistantPageState extends State<GeminiAssistantPage> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();
  late final TaskController _taskController;

  final RxList<AssistantMessage> _messages = <AssistantMessage>[].obs;
  final RxBool _isSending = false.obs;

  @override
  void initState() {
    super.initState();
    _taskController = Get.isRegistered<TaskController>()
        ? Get.find<TaskController>()
        : Get.put(TaskController());
    _apiKeyController.text = _geminiService.storedApiKey ?? '';
    _messages.add(const AssistantMessage(
      text:
          'Tôi là trợ lý Gemini. Bạn có thể yêu cầu kiểm tra trạng thái nhiệm vụ, thêm mới, đặt nhắc lịch hoặc nhờ tôi tóm tắt tiến độ tuần.',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _inputController.dispose();
    _apiKeyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trợ lý Gemini'),
        backgroundColor: theme.colorScheme.background,
        foregroundColor: theme.colorScheme.onBackground,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Cập nhật GEMINI_API_KEY',
            icon: const Icon(Icons.vpn_key_outlined),
            onPressed: _promptForApiKey,
          ),
        ],
      ),
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildApiKeyBanner(theme),
            Expanded(
              child: Obx(
                () => ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _AssistantBubble(message: message);
                  },
                ),
              ),
            ),
            _buildActionBar(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeyBanner(ThemeData theme) {
    if (_geminiService.isConfigured) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Chưa cấu hình GEMINI_API_KEY. Thêm --dart-define=GEMINI_API_KEY=YOUR_KEY khi build hoặc nhấn "Nhập API key" để lưu tạm thời (cục bộ, không commit).',
        style: theme.textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildActionBar(ThemeData theme) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom == 0
            ? 12
            : MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Nhắn tin cho trợ lý (ví dụ: Thêm nhiệm vụ mua sắm vào 5h chiều)',
                    hintStyle: GoogleFonts.lato(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Obx(
                () => IconButton(
                  onPressed: _isSending.value ? null : _sendMessage,
                  icon: _isSending.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: primaryClr),
              onPressed: _isSending.value ? null : _requestWeeklySummary,
              icon: const Icon(Icons.analytics_outlined, color: Colors.white),
              label: const Text(
                'Tóm tắt tiến độ tuần',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          if (!_geminiService.isConfigured)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _promptForApiKey,
                icon: const Icon(Icons.vpn_key, size: 18),
                label: const Text('Nhập API key'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _messages.add(AssistantMessage(text: text, isUser: true));
    _inputController.clear();
    await _scrollToBottom();

    _isSending.value = true;
    final reply = await _geminiService.sendChat(text);
    _messages.add(AssistantMessage(text: reply, isUser: false));
    _isSending.value = false;
    await _scrollToBottom();
  }

  Future<void> _requestWeeklySummary() async {
    _messages.add(const AssistantMessage(
      text: 'Đang tạo báo cáo tuần dựa trên các nhiệm vụ hiện có...',
      isUser: true,
    ));
    _isSending.value = true;

    final List<Task> tasks = List<Task>.from(_taskController.taskList);
    final summary = await _geminiService.generateWeeklySummary(tasks);
    _messages.add(AssistantMessage(text: summary, isUser: false));

    _isSending.value = false;
    await _scrollToBottom();
  }

  Future<void> _promptForApiKey() async {
    _apiKeyController.text = _geminiService.storedApiKey ?? '';
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Thiết lập GEMINI_API_KEY'),
          content: TextField(
            controller: _apiKeyController,
            decoration: const InputDecoration(
              labelText: 'Nhập API key (sẽ lưu cục bộ)',
              hintText: 'AIza... (không commit vào git)',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(''),
              child: const Text('Xóa key'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(_apiKeyController.text),
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    if (result.trim().isEmpty) {
      await _geminiService.clearApiKey();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa GEMINI_API_KEY lưu cục bộ.')),
        );
      }
      return;
    }

    await _geminiService.updateApiKey(result);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu GEMINI_API_KEY cục bộ cho phiên bản này.')),
      );
    }
  }

  Future<void> _scrollToBottom() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 60,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.message});

  final AssistantMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isUser
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.secondaryContainer;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 640),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              isUser ? 'Bạn' : 'Gemini',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.text,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            Text(
              DateFormat('HH:mm').format(DateTime.now()),
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
