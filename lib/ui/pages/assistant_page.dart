import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../controllers/task_controller.dart';
import '../../models/task.dart';
import '../../services/gemini_service.dart';
import '../theme.dart';

class AssistantMessage {
  const AssistantMessage({required this.text, required this.isUser});

  factory AssistantMessage.fromJson(Map<String, dynamic> json) {
    return AssistantMessage(
      text: json['text'] as String? ?? '',
      isUser: json['isUser'] == true,
    );
  }

  final String text;
  final bool isUser;

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
      };
}

class _GeminiMessageStore {
  static const _historyKey = 'gemini_chat_history';

  _GeminiMessageStore([GetStorage? box]) : _box = box ?? GetStorage();

  final GetStorage _box;

  List<AssistantMessage> read() {
    final raw = _box.read<List<dynamic>>(_historyKey) ?? <dynamic>[];
    return raw
        .whereType<Map>()
        .map((entry) => AssistantMessage.fromJson(
            entry.map((key, value) => MapEntry(key.toString(), value))))
        .toList();
  }

  Future<void> save(List<AssistantMessage> messages) async {
    await _box.write(
      _historyKey,
      messages.map((message) => message.toJson()).toList(),
    );
  }
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
  final _GeminiMessageStore _messageStore = _GeminiMessageStore();
  late final TaskController _taskController;

  final RxList<AssistantMessage> _messages = <AssistantMessage>[].obs;
  final RxBool _isSending = false.obs;

  @override
  void initState() {
    super.initState();
    _taskController = Get.isRegistered<TaskController>()
        ? Get.find<TaskController>()
        : Get.put(TaskController());
    _taskController.getTasks();
    _apiKeyController.text = _geminiService.storedApiKey ?? '';
    _restoreMessages();
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

    await _addMessage(AssistantMessage(text: text, isUser: true));
    _inputController.clear();
    await _scrollToBottom();

    await _handleTaskCommands(text);

    _isSending.value = true;
    final reply = await _geminiService.sendChat(text);
    await _addMessage(AssistantMessage(text: reply, isUser: false));
    _isSending.value = false;
    await _scrollToBottom();
  }

  Future<void> _requestWeeklySummary() async {
    await _addMessage(const AssistantMessage(
      text: 'Đang tạo báo cáo tuần dựa trên các nhiệm vụ hiện có...',
      isUser: true,
    ));
    _isSending.value = true;

    final List<Task> tasks = List<Task>.from(_taskController.taskList);
    final summary = await _geminiService.generateWeeklySummary(tasks);
    await _addMessage(AssistantMessage(text: summary, isUser: false));

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

  Future<void> _addMessage(AssistantMessage message) async {
    _messages.add(message);
    await _messageStore.save(_messages);
  }

  void _restoreMessages() {
    final saved = _messageStore.read();
    if (saved.isEmpty) {
      _messages.add(const AssistantMessage(
        text:
            'Tôi là trợ lý Gemini. Bạn có thể yêu cầu kiểm tra trạng thái nhiệm vụ, thêm mới, đặt nhắc lịch hoặc nhờ tôi tóm tắt tiến độ tuần.',
        isUser: false,
      ));
      _messageStore.save(_messages);
      return;
    }

    _messages.assignAll(saved);
  }

  Future<void> _handleTaskCommands(String userInput) async {
    final normalized = userInput.toLowerCase();
    final creationKeywords = [
      'thêm nhiệm vụ',
      'tạo nhiệm vụ',
      'add task',
      'create task',
    ];

    if (creationKeywords.any(normalized.contains)) {
      final title = _extractTitle(userInput, creationKeywords);
      if (title != null && title.isNotEmpty) {
        final scheduledStart = _parseScheduledStart(userInput);
        final newTask = _buildTaskFromInput(title, scheduledStart);

        try {
          final id = await _taskController.addTask(task: newTask);
          if (id > 0 && id != 9000) {
            final dateText = DateFormat.yMd().format(scheduledStart);
            final timeText = DateFormat('HH:mm').format(scheduledStart);
            await _addMessage(AssistantMessage(
              text:
                  'Đã thêm nhiệm vụ "$title" vào ngày $dateText lúc $timeText.',
              isUser: false,
            ));
          } else {
            await _addMessage(const AssistantMessage(
              text:
                  'Không thể thêm nhiệm vụ mới từ Gemini. Vui lòng kiểm tra lại dữ liệu hoặc khởi động lại ứng dụng.',
              isUser: false,
            ));
          }
        } catch (error) {
          await _addMessage(AssistantMessage(
            text:
                'Không thể lưu nhiệm vụ do lỗi cơ sở dữ liệu: ${error.toString()}',
            isUser: false,
          ));
        }
      }
    }

    if (normalized.contains('xóa nhiệm vụ') || normalized.contains('xoá nhiệm vụ')) {
      final title = _extractTitle(userInput, ['xóa nhiệm vụ', 'xoá nhiệm vụ']);
      if (title != null && title.isNotEmpty) {
        await _taskController.getTasks();
        final deleted = await _deleteTaskByTitle(title);
        if (deleted) {
          await _addMessage(AssistantMessage(
            text: 'Đã xóa nhiệm vụ chứa từ khóa "$title".',
            isUser: false,
          ));
        } else {
          await _addMessage(AssistantMessage(
            text: 'Không tìm thấy nhiệm vụ phù hợp với "$title" để xóa.',
            isUser: false,
          ));
        }
      }
    }
  }

  String? _extractTitle(String input, List<String> keywords) {
    final lower = input.toLowerCase();
    for (final keyword in keywords) {
      final index = lower.indexOf(keyword);
      if (index != -1) {
        final rawTitle = input.substring(index + keyword.length);
        final cleaned = rawTitle.replaceFirst(RegExp(r'^[\s:,-]+'), '').trim();
        if (cleaned.isNotEmpty) return cleaned;
      }
    }
    return null;
  }

  Task _buildTaskFromInput(String title, DateTime scheduledStart) {
    final dateFormatter = DateFormat.yMd();
    final timeFormatter = DateFormat('hh:mm a');

    return Task(
      title: title,
      note: 'Tạo từ cuộc hội thoại với Gemini',
      isCompleted: 0,
      date: dateFormatter.format(scheduledStart),
      startTime: timeFormatter.format(scheduledStart),
      endTime: timeFormatter.format(scheduledStart.add(const Duration(minutes: 30))),
      color: 0,
      remind: 0,
      repeat: 'None',
    );
  }

  DateTime _parseScheduledStart(String rawInput) {
    final now = DateTime.now();
    final normalized = rawInput.toLowerCase();
    final scheduledDate = _parseDateFromInput(normalized, now) ??
        DateTime(now.year, now.month, now.day);
    final startTime = _parseTimeOfDay(normalized, now);

    return DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      startTime.hour,
      startTime.minute,
    );
  }

  DateTime? _parseDateFromInput(String normalizedInput, DateTime now) {
    final explicitDateMatch =
        RegExp(r'(\d{1,2})[\\/-](\d{1,2})(?:[\\/-](\d{2,4}))?')
            .firstMatch(normalizedInput);
    if (explicitDateMatch != null) {
      final day = int.tryParse(explicitDateMatch.group(1)!);
      final month = int.tryParse(explicitDateMatch.group(2)!);
      final yearRaw = explicitDateMatch.group(3);
      final year = _resolveYear(yearRaw, now.year);

      if (day != null && month != null) {
        final parsed = DateTime(year, month, day);
        if (yearRaw == null &&
            parsed.isBefore(DateTime(now.year, now.month, now.day))) {
          return DateTime(year + 1, month, day);
        }
        return parsed;
      }
    }

    if (normalizedInput.contains('hôm nay')) {
      return DateTime(now.year, now.month, now.day);
    }
    if (normalizedInput.contains('ngày mai') || normalizedInput.contains('mai')) {
      final tomorrow = now.add(const Duration(days: 1));
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    }
    if (normalizedInput.contains('ngày mốt') || normalizedInput.contains('mốt')) {
      final nextTwoDays = now.add(const Duration(days: 2));
      return DateTime(nextTwoDays.year, nextTwoDays.month, nextTwoDays.day);
    }

    final weekday = _extractWeekday(normalizedInput);
    if (weekday != null) {
      final daysToAdd = (weekday - now.weekday + 7) % 7;
      return DateTime(now.year, now.month, now.day)
          .add(Duration(days: daysToAdd));
    }

    return null;
  }

  int _resolveYear(String? yearRaw, int currentYear) {
    if (yearRaw == null) return currentYear;
    if (yearRaw.length == 2) {
      return 2000 + int.parse(yearRaw);
    }
    return int.tryParse(yearRaw) ?? currentYear;
  }

  int? _extractWeekday(String normalizedInput) {
    const weekdayKeywords = {
      'thứ 2': DateTime.monday,
      'thứ hai': DateTime.monday,
      'thứ 3': DateTime.tuesday,
      'thứ ba': DateTime.tuesday,
      'thứ 4': DateTime.wednesday,
      'thứ tư': DateTime.wednesday,
      'thứ 5': DateTime.thursday,
      'thứ năm': DateTime.thursday,
      'thứ 6': DateTime.friday,
      'thứ sáu': DateTime.friday,
      'thứ 7': DateTime.saturday,
      'thứ bảy': DateTime.saturday,
      'thứ bay': DateTime.saturday,
      'chủ nhật': DateTime.sunday,
      'chu nhat': DateTime.sunday,
      'cn': DateTime.sunday,
    };

    for (final entry in weekdayKeywords.entries) {
      if (normalizedInput.contains(entry.key)) {
        return entry.value;
      }
    }

    final numericMatch = RegExp(r'thứ\s*(\d)').firstMatch(normalizedInput);
    if (numericMatch != null) {
      final dayNumber = int.tryParse(numericMatch.group(1) ?? '');
      if (dayNumber != null && dayNumber >= 2 && dayNumber <= 7) {
        return dayNumber - 1;
      }
    }
    return null;
  }

  TimeOfDay _parseTimeOfDay(String normalizedInput, DateTime now) {
    final match = RegExp(
            r'(\d{1,2})(?:[:hH](\d{1,2}))?\s*(am|pm|a\.m\.|p\.m\.|sáng|sang|chiều|chieu|tối|toi|đêm|dem)?')
        .firstMatch(normalizedInput);

    if (match == null) {
      return TimeOfDay(hour: now.hour, minute: now.minute);
    }

    var hour = int.tryParse(match.group(1) ?? '') ?? now.hour;
    final minute = int.tryParse(match.group(2) ?? '0') ?? 0;
    final suffix = match.group(3) ?? '';

    final isPm =
        suffix.contains('pm') || suffix.contains('p.m') || suffix.contains('chiều') || suffix.contains('chieu') || suffix.contains('tối') || suffix.contains('toi') || suffix.contains('đêm') || suffix.contains('dem');
    final isAm =
        suffix.contains('am') || suffix.contains('a.m') || suffix.contains('sáng') || suffix.contains('sang');

    if (hour >= 1 && hour <= 12 && isPm && hour != 12) {
      hour += 12;
    } else if (hour == 12 && isAm) {
      hour = 0;
    }

    hour = hour.clamp(0, 23);
    final validatedMinute = minute.clamp(0, 59);

    return TimeOfDay(hour: hour, minute: validatedMinute);
  }

  Future<bool> _deleteTaskByTitle(String keyword) async {
    final query = keyword.toLowerCase();
    for (final task in _taskController.taskList) {
      final title = (task.title ?? '').toLowerCase();
      if (title.contains(query)) {
        await _taskController.deleteTasks(task);
        return true;
      }
    }
    return false;
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
