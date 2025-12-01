#!/usr/bin/env bash
set -euo pipefail

if [ ! -f .env ]; then
  echo "⚠️  Không tìm thấy .env. Sao chép .env.example và điền GEMINI_API_KEY." >&2
  exit 1
fi

# shellcheck disable=SC1091
source .env

if [ -z "${GEMINI_API_KEY:-}" ]; then
  echo "❌ Biến GEMINI_API_KEY chưa được thiết lập trong .env" >&2
  exit 1
fi

flutter run --dart-define=GEMINI_API_KEY="${GEMINI_API_KEY}" "$@"
