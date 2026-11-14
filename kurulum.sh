#!/usr/bin/env bash
# Android platform dosyalarını üretir (yerel derleme için). CI aynı işi build-apk.yml içinde yapar.
set -e
cp android/app/src/main/AndroidManifest.xml /tmp/krypton_manifest.xml
TMP=$(mktemp -d)
flutter create --org com.krypton --project-name krypton_ai --platforms android "$TMP/app"
cp -r "$TMP/app/android/." android/
cp "$TMP/app/.metadata" . 2>/dev/null || true
cp /tmp/krypton_manifest.xml android/app/src/main/AndroidManifest.xml
for f in android/app/build.gradle android/app/build.gradle.kts; do
  [ -f "$f" ] || continue
  sed -i -E 's/applicationId\s*=?\s*"[^"]*"/applicationId = "com.krypton.ai"/; s/minSdk(Version)?\s*=?\s*flutter\.minSdkVersion/minSdk = 26/' "$f"
done
flutter pub get
