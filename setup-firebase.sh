#!/bin/bash
echo "🔥 Завершение настройки Firebase для мессенджера..."

# 1. Создаем новый проект Firebase (если еще не создан)
echo "🔧 Создание проекта Firebase..."
if ! firebase projects:list | grep -q "my-messenger"; then
    firebase projects:create my-messenger --display-name="Мой Мессенджер"
    echo "✅ Проект Firebase 'my-messenger' создан"
else
    echo "ℹ️ Проект Firebase 'my-messenger' уже существует"
fi

# 2. Выбираем проект для использования
echo "🔧 Выбор проекта Firebase..."
firebase use --add my-messenger --force
echo "✅ Проект Firebase выбран"

# 3. Инициализируем Firebase в проекте
echo "🔧 Инициализация Firebase в проекте..."
if [ ! -f "firebase.json" ]; then
    firebase init --no-localhost <<EOF
    firestore
    auth
    yes
    my-messenger
    build.gradle.kts
    yes
    com.example.mymessenger
    no
