#!/bin/bash

# SafeRide AI Mobile App Runner
echo "🚗 Starting SafeRide AI Car Monitoring App on Mobile Device"
echo "📱 Deploying to Android device..."

# Navigate to Flutter project directory
cd /Users/venkataraju/projects/saferide_ai_app

# Check if pubspec.yaml exists
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found in current directory"
    echo "Current directory: $(pwd)"
    exit 1
fi

echo "✅ Found pubspec.yaml in: $(pwd)"

# Get Flutter dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Check available devices
echo "📱 Available devices:"
flutter devices

# Run on Android device (will prompt for device selection if multiple)
echo "🚀 Running SafeRide AI on mobile device..."
flutter run -d V2207
