#!/bin/bash

# SafeRide AI - Automatic Mobile Car Monitoring
# Run without buttons - just like the Python desktop version

echo "🚗 Starting SafeRide AI Car Monitoring App on Mobile Device"
echo "📱 No buttons needed - automatic detection will start immediately"
echo "✅ Just like the Python desktop version you experienced"

cd /Users/venkataraju/projects/saferide_ai_app

echo "📦 Installing dependencies..."
flutter pub get

echo "📱 Available devices:"
flutter devices

echo "🚀 Running SafeRide AI with automatic detection..."
echo "💡 The app will start monitoring immediately when it opens"
echo "🔊 Voice alerts will trigger automatically for dangerous behaviors"
echo "📳 Vibration feedback for immediate attention"

# Run on the available mobile device
flutter run
