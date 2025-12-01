#!/usr/bin/env bash
set -euo pipefail

if [ -z "${GEMINI_API_KEY:-}" ]; then
  if [ -f .env ]; then
    # shellcheck disable=SC1091
    source .env
  else
    echo "⚠️  Không tìm thấy biến môi trường GEMINI_API_KEY hoặc file .env." >&2
    echo "➡️  Sao chép .env.example thành .env và điền GEMINI_API_KEY của bạn (file này đã bị .gitignore)." >&2
    exit 1
  fi
fi

if [ -z "${GEMINI_API_KEY:-}" ]; then
  echo "❌ Biến GEMINI_API_KEY chưa được thiết lập. Cập nhật .env hoặc export GEMINI_API_KEY trước khi chạy." >&2
  exit 1
fi

flutter run --dart-define=GEMINI_API_KEY="${GEMINI_API_KEY}" "$@"
