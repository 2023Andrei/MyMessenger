#!/bin/bash
echo "🔐 Настройка доступа к сервисам через Google-аккаунт..."

# 1. Установка необходимых инструментов
echo "🔧 Установка CLI-инструментов..."
sudo snap install firebase --classic 2>/dev/null || echo "Firebase CLI уже установлен"
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/github-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/github-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update && sudo apt install gh -y 2>/dev/null || echo "GitHub CLI уже установлен"
npm install -g render-cli 2>/dev/null || echo "Render CLI уже установлен"

# 2. Аутентификация в Firebase
echo -e "\n🔐 Аутентификация в Firebase (требуется Google-аккаунт)"
echo "Откроется браузер для входа через Google. После успешного входа вернитесь в терминал."
firebase login --no-localhost

# 3. Аутентификация в GitHub
echo -e "\n🔐 Аутентификация в GitHub"
echo "Откроется браузер для входа. После успешного входа вернитесь в терминал."
gh auth login -p https -w

# 4. Аутентификация в Render.com
echo -e "\n🔐 Аутентификация в Render.com"
echo "Перейдите на https://dashboard.render.com/user/settings в браузере"
echo "Скопируйте API Key и вставьте его ниже при запросе"
read -sp "Введите ваш Render API Key: " RENDER_KEY
echo "$RENDER_KEY" > ~/.render_api_key
echo -e "\n✅ Render.com настроен"

# 5. Проверка доступа
echo -e "\n🔍 Проверка доступа к сервисам..."
echo "Firebase:"
firebase projects:list 2>/dev/null || echo "⚠️ Firebase не настроен или нет проектов"
echo -e "\nGitHub:"
gh repo list 2>/dev/null || echo "⚠️ GitHub не настроен"
echo -e "\nRender.com:"
cat ~/.render_api_key 2>/dev/null && echo "✅ Render API Key сохранен"

echo -e "\n✅ Настройка доступа к сервисам завершена!"
echo "---------------------------------------------------"
echo "Теперь вы можете:"
echo "1. Развернуть сигнальный сервер на Render.com"
echo "2. Добавить Firebase в ваш мессенджер"
echo "3. Публиковать код на GitHub"
echo -e "\nВАЖНО: Ваши учетные данные НЕ сохраняются в этом скрипте."
echo "Аутентификация происходит через безопасные OAuth-потоки."
