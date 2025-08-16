#!/bin/bash
echo "🔧 Установка необходимых CLI-инструментов..."

# 1. Устанавливаем Node.js (требуется для Firebase и Render)
echo "🔧 Установка Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# 2. Устанавливаем Firebase CLI
echo "🔧 Установка Firebase CLI..."
sudo npm install -g firebase-tools

# 3. Устанавливаем GitHub CLI
echo "🔧 Установка GitHub CLI..."
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/github-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/github-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install -y gh

# 4. Устанавливаем Render CLI
echo "🔧 Установка Render CLI..."
sudo npm install -g render-cli

# 5. Проверяем установку
echo -e "\n🔍 Проверка установленных инструментов..."
echo "Node.js: $(node -v)"
echo "npm: $(npm -v)"
echo "Firebase: $(firebase --version)"
echo "GitHub CLI: $(gh --version)"
echo "Render CLI: $(render --version 2>/dev/null || echo 'Render CLI установлен, но версия не определена')"

# 6. Настройка аутентификации
echo -e "\n🔐 Настройка аутентификации..."

# Firebase
echo -e "\n🔧 Аутентификация в Firebase (требуется Google-аккаунт)"
echo "Откроется браузер для входа через Google. После успешного входа вернитесь в терминал."
firebase login --no-localhost

# GitHub
echo -e "\n🔧 Аутентификация в GitHub"
echo "Откроется браузер для входа. После успешного входа вернитесь в терминал."
gh auth login -p https -w

# Render.com
echo -e "\n🔧 Аутентификация в Render.com"
echo "Перейдите на https://dashboard.render.com/user/settings в браузере"
echo "Скопируйте API Key и вставьте его ниже при запросе"
read -sp "Введите ваш Render API Key: " RENDER_KEY
echo "$RENDER_KEY" > ~/.render_api_key
echo -e "\n✅ Render.com настроен"

# 7. Финальная проверка
echo -e "\n✅ Установка и настройка завершены!"
echo "---------------------------------------------------"
echo "Теперь вы можете:"
echo "1. Развернуть сигнальный сервер на Render.com"
echo "2. Добавить Firebase в ваш мессенджер"
echo "3. Публиковать код на GitHub"
echo -e "\n💡 Совет: Чтобы проверить доступ к сервисам, выполните:"
echo "   firebase projects:list"
echo "   gh repo list"
echo "   render projects list"
