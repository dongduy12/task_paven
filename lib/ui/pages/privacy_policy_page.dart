import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chính sách & Quyền riêng tư'),
        backgroundColor: theme.colorScheme.background,
        foregroundColor: theme.colorScheme.onBackground,
        elevation: 0,
      ),
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cam kết bảo vệ thông tin',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Chúng tôi ưu tiên bảo mật dữ liệu cá nhân của bạn. Ứng dụng chỉ '
                'thu thập thông tin cần thiết để cung cấp và cải thiện trải nghiệm '
                'quản lý công việc. Thông tin của bạn sẽ không được chia sẻ cho bên '
                'thứ ba khi không có sự đồng ý.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              Text(
                'Quyền của bạn',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              _buildBullet(
                context,
                'Xem, chỉnh sửa hoặc xoá dữ liệu cá nhân đã lưu trên ứng dụng.',
              ),
              _buildBullet(
                context,
                'Tùy chỉnh cài đặt thông báo và quyền truy cập hệ thống.',
              ),
              _buildBullet(
                context,
                'Liên hệ hỗ trợ qua email nếu cần thêm thông tin chi tiết.',
              ),
              const SizedBox(height: 18),
              Text(
                'Điều khoản sử dụng',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Bằng việc sử dụng ứng dụng, bạn đồng ý không sử dụng dữ liệu cho '
                'mục đích trái pháp luật, không chia sẻ thông tin tài khoản cho '
                'người khác và tuân thủ các quy định của cửa hàng ứng dụng.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.center,
                child: ElevatedButton.icon(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Đã hiểu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBullet(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.brightness_1, size: 8),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
