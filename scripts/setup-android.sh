#!/usr/bin/env bash
# One-shot Android build toolchain bootstrap (no root, no pacman).
# Installs a portable JDK 17 (Gradle-compatible) + Android cmdline-tools,
# platform-tools, platform android-34 and build-tools 34.0.0.
# Logs everything and drops a sentinel file on success/failure.
set -uo pipefail

LOG="${LOG:-/tmp/android-setup.log}"
SENTINEL_OK="/tmp/android-setup.ok"
SENTINEL_FAIL="/tmp/android-setup.fail"
rm -f "$SENTINEL_OK" "$SENTINEL_FAIL"

JDK="$HOME/jdk17"
SDK="$HOME/Android/Sdk"
CMDTOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
JDK_URL="https://api.adoptium.net/v3/binary/latest/17/ga/linux/x64/jdk/hotspot/normal/eclipse"

log(){ echo "[$(cat /proc/uptime | cut -d' ' -f1)] $*" | tee -a "$LOG"; }
fail(){ log "FAILED: $*"; touch "$SENTINEL_FAIL"; exit 1; }

: > "$LOG"
log "=== android toolchain bootstrap ==="

# --- 1. portable JDK 17 (Temurin) --------------------------------------------
if [ ! -x "$JDK/bin/javac" ]; then
  log "downloading Temurin JDK 17 ..."
  mkdir -p "$JDK"
  curl -fL --retry 3 -o /tmp/jdk17.tar.gz "$JDK_URL" >>"$LOG" 2>&1 || fail "jdk download"
  tar xzf /tmp/jdk17.tar.gz -C "$JDK" --strip-components=1 >>"$LOG" 2>&1 || fail "jdk extract"
fi
export JAVA_HOME="$JDK"
export PATH="$JAVA_HOME/bin:$PATH"
log "java: $("$JDK/bin/java" -version 2>&1 | head -1)"

# --- 2. Android command-line tools -------------------------------------------
if [ ! -x "$SDK/cmdline-tools/latest/bin/sdkmanager" ]; then
  log "downloading Android cmdline-tools ..."
  mkdir -p "$SDK/cmdline-tools"
  curl -fL --retry 3 -o /tmp/cmdtools.zip "$CMDTOOLS_URL" >>"$LOG" 2>&1 || fail "cmdtools download"
  rm -rf "$SDK/cmdline-tools/tmp" "$SDK/cmdline-tools/latest"
  unzip -q -o /tmp/cmdtools.zip -d "$SDK/cmdline-tools/tmp" >>"$LOG" 2>&1 || fail "cmdtools unzip"
  mv "$SDK/cmdline-tools/tmp/cmdline-tools" "$SDK/cmdline-tools/latest" || fail "cmdtools move"
  rmdir "$SDK/cmdline-tools/tmp" 2>/dev/null || true
fi
export ANDROID_HOME="$SDK"
export ANDROID_SDK_ROOT="$SDK"
export PATH="$SDK/cmdline-tools/latest/bin:$SDK/platform-tools:$PATH"

# --- 3. licenses + packages --------------------------------------------------
log "accepting licenses ..."
yes | sdkmanager --licenses >>"$LOG" 2>&1 || log "warn: license step returned non-zero (often ok)"
log "installing platform-tools, platforms;android-34, build-tools;34.0.0 ..."
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" >>"$LOG" 2>&1 \
  || fail "sdkmanager package install"

log "=== toolchain ready ==="
log "JAVA_HOME=$JDK"
log "ANDROID_HOME=$SDK"
touch "$SENTINEL_OK"
