import 'dart:async';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';

class GeminiService {
  GeminiService({String? apiKey, GenerativeModel? model})
      : _apiKey = apiKey ?? const String.fromEnvironment('GEMINI_API_KEY'),
        _model = model;

  final String _apiKey;
  GenerativeModel? _model;
  ChatSession? _chatSession;

  bool get isConfigured => _apiKey.isNotEmpty;

  GenerativeModel get _resolvedModel {
    _model ??= GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
    return _model!;
  }

  Future<String> sendChat(String userMessage) async {
    if (userMessage.trim().isEmpty) {
      return 'Hãy nhập nội dung để tôi có thể hỗ trợ bạn.';
    }

    if (!isConfigured) {
      return _missingKeyMessage;
    }

    _chatSession ??= _resolvedModel.startChat(history: [
      Content.text(
        'You are an assistant that manages a to-do list application. '
        'You can add tasks, mark tasks done, update reminders, and summarize progress. '
        'Keep answers concise and actionable.',
      ),
    ]);

    try {
      final response = await _chatSession!.sendMessage(Content.text(userMessage));
      return response.text ?? 'Tôi chưa nhận được phản hồi, vui lòng thử lại.';
    } on GenerativeAIException catch (error) {
      return 'Không thể gọi Gemini: ${error.message}';
    } catch (error) {
      return 'Đã xảy ra lỗi khi gửi yêu cầu: $error';
    }
  }

  Future<String> generateWeeklySummary(List<Task> tasks) async {
    if (!isConfigured) {
      return _missingKeyMessage;
    }

    if (tasks.isEmpty) {
      return 'Chưa có nhiệm vụ để tổng hợp. Hãy thêm nhiệm vụ trước khi tạo báo cáo tuần.';
    }

    final completed = tasks.where((task) => task.isCompleted == 1).toList();
    final pending = tasks.where((task) => task.isCompleted != 1).toList();
    final formatter = DateFormat.yMMMd();

    final completedText = completed.isEmpty
        ? 'Không có nhiệm vụ nào được hoàn thành.'
        : completed
            .map((task) =>
                '- ${task.title ?? 'Nhiệm vụ'} (hoàn thành ngày ${task.date ?? 'N/A'})')
            .join('\n');

    final pendingText = pending.isEmpty
        ? 'Không còn nhiệm vụ tồn đọng.'
        : pending
            .map((task) {
              final due = _formatDueDate(task.date, formatter);
              return '- ${task.title ?? 'Nhiệm vụ'} (hạn $due)';
            })
            .join('\n');

    final prompt =
        'Hãy tạo bản tóm tắt tiến độ tuần cho ứng dụng quản lý nhiệm vụ. '\
        'Phân tích các nhiệm vụ hoàn thành, nhiệm vụ trễ, ưu tiên tuần tới và gợi ý nhắc lịch.\n\n'
        'Nhiệm vụ hoàn thành:\n$completedText\n\n'
        'Nhiệm vụ còn lại hoặc trễ:\n$pendingText\n\n'
        'Trả lời bằng tiếng Việt và liệt kê đề xuất ưu tiên trong tuần tới.';

    try {
      final response = await _resolvedModel.generateContent([Content.text(prompt)]);
      return response.text ?? 'Không thể tạo bản tóm tắt, vui lòng thử lại.';
    } on GenerativeAIException catch (error) {
      return 'Không thể gọi Gemini: ${error.message}';
    } catch (error) {
      return 'Đã xảy ra lỗi khi tổng hợp tuần: $error';
    }
  }

  String get _missingKeyMessage =>
      'Gemini chưa được cấu hình. Thiết lập biến môi trường GEMINI_API_KEY hoặc truyền apiKey khi khởi tạo.';

  String _formatDueDate(String? dueDate, DateFormat formatter) {
    if (dueDate == null) return 'chưa có hạn';
    try {
      return formatter.format(DateFormat.yMd().parse(dueDate));
    } catch (_) {
      return dueDate;
    }
  }
}
