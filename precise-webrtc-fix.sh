#!/bin/bash
echo "🔥 ТОЧНОЕ РЕШЕНИЕ ПРОБЛЕМЫ С WEBRTC (БЕЗ ОШИБКИ 401)..."

# 1. ПОЛНОЕ УДАЛЕНИЕ ВСЕХ УПОМИНАНИЙ WEBRTC
echo "🔧 Полное удаление всех упоминаний WebRTC..."
sed -i '/webrtc/d' app/build.gradle.kts
echo "✅ Все упоминания WebRTC удалены из build.gradle.kts"

# 2. ПОЛНОЕ УДАЛЕНИЕ JitPack ИЗ settings.gradle.kts
echo "🔧 Полное удаление JitPack из settings.gradle.kts..."
sed -i '/jitpack/d' app/settings.gradle.kts
echo "✅ JitPack удален из settings.gradle.kts"

# 3. Дополнительные действия (если необходимо)
# Здесь можно добавить дополнительные команды, если нужно

