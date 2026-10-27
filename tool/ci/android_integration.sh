#!/usr/bin/env bash
# Codemagic Linux runner: create a disposable emulator and keep failure logs.
set -euo pipefail

mkdir -p test-results
emulator_pid=''
cleanup() {
  adb -s emulator-5554 logcat -d > test-results/logcat.log 2>&1 || true
  if [[ -n "$emulator_pid" ]]; then
    kill "$emulator_pid" 2>/dev/null || true
  fi
}
trap cleanup EXIT

sdkmanager 'platform-tools' 'emulator' 'system-images;android-35;google_apis;x86_64'
# A here-string avoids a SIGPIPE from `yes` under pipefail.
avdmanager create avd --force --name blurly_ci \
  --package 'system-images;android-35;google_apis;x86_64' --device pixel_6 <<< 'no'
emulator -avd blurly_ci -port 5554 -no-window -no-audio -no-boot-anim \
  -no-snapshot -gpu swiftshader_indirect > test-results/emulator.log 2>&1 &
emulator_pid=$!

# adb wait-for-device alone does not mean Android has finished booting.
booted=false
for ((attempt = 0; attempt < 180; attempt++)); do
  if ! kill -0 "$emulator_pid" 2>/dev/null; then
    cat test-results/emulator.log
    exit 1
  fi
  if [[ "$(adb -s emulator-5554 shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == '1' ]]; then
    booted=true
    break
  fi
  sleep 2
done
if [[ "$booted" != true ]]; then
  printf '%s\n' 'Android emulator did not boot within six minutes.'
  exit 1
fi

adb -s emulator-5554 shell settings put global window_animation_scale 0
adb -s emulator-5554 shell settings put global transition_animation_scale 0
adb -s emulator-5554 shell settings put global animator_duration_scale 0
flutter test integration_test -d emulator-5554 --machine \
  | tee test-results/integration.json
