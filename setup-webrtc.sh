#!/bin/bash
echo "🔧 Настройка WebRTC для аудио звонков (рабочая версия)..."

# 1. Исправление settings.gradle.kts
echo "🔧 Исправление settings.gradle.kts..."
cat > settings.gradle.kts << 'EOF'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
include(":app")
