#!/bin/bash
echo "🔧 Исправление структуры Gradle для Android проекта..."

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
