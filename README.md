# task_paven

Task item paven

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Cấu hình API key cho Gemini

> Lưu ý: Tuyệt đối **không** hardcode API key trực tiếp trong code. Chỉ truyền vào runtime qua biến môi trường hoặc từ nguồn bảo mật (Firebase Remote Config, backend).

### 1) Dùng file `.env` + `--dart-define`

1. Sao chép `.env.example` thành `.env` và thay giá trị:
   ```bash
   cp .env.example .env
   # mở .env và thay your-gemini-api-key
   ```
2. Khi chạy hoặc build, truyền biến môi trường qua `--dart-define-from-file` (Flutter sẽ gán vào `const String.fromEnvironment('GEMINI_API_KEY')` trong `GeminiService`):
   ```bash
   flutter run --dart-define-from-file=.env
   # hoặc
   flutter build apk --dart-define-from-file=.env
   ```

> Tip: bạn có thể dùng script hỗ trợ để tránh quên truyền biến môi trường:
>
> ```bash
> ./scripts/run_with_gemini_env.sh
> # hoặc thêm tham số thiết bị
> ./scripts/run_with_gemini_env.sh -d emulator-5554
> ```

### 2) Lưu API key trong Firebase Remote Config

1. Lưu khóa (ví dụ key `gemini_api_key`) trên Remote Config và bật mã hóa phía server nếu có.
2. Fetch & activate Remote Config sớm khi khởi động app, sau đó khởi tạo `GeminiService` với giá trị lấy được:
   ```dart
   final apiKey = remoteConfig.getString('gemini_api_key');
   final gemini = GeminiService(apiKey: apiKey);
   ```
3. Nếu chưa fetch được khóa, hãy ẩn hoặc vô hiệu nút/trang trợ lý Gemini để tránh lỗi gọi API.

### 3) Lấy API key từ backend riêng

1. Lưu khóa trên server/backend (hoặc service secrets manager), không ghi vào app.
2. Cung cấp endpoint bảo mật (có auth) để trả về API key hoặc token proxy.
3. Sau khi người dùng đăng nhập, gọi endpoint này, rồi khởi tạo `GeminiService` bằng khóa nhận được:
   ```dart
   final gemini = GeminiService(apiKey: fetchedKey);
   ```
4. Đừng lưu khóa vào storage lâu dài; chỉ giữ trong memory và làm mới định kỳ nếu cần.
