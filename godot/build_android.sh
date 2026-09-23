#!/bin/sh
# Offline Android APK (Godot prebuilt template, no Gradle). Needs Android SDK build-tools + JDK 17
# set in Godot editor settings (export/android/android_sdk_path, java_sdk_path) and a release keystore
# passed via env - never commit the keystore or its password.
#   GODOT_ANDROID_KEYSTORE_RELEASE_PATH=... GODOT_ANDROID_KEYSTORE_RELEASE_USER=issen \
#   GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=... ./build_android.sh
set -e
GODOT=${GODOT:-$HOME/godot/Godot_v4.5.2-stable_linux.x86_64}
mkdir -p export_android
"$GODOT" --headless --import >/dev/null 2>&1 || true
"$GODOT" --headless --export-release "Android" export_android/issen.apk
