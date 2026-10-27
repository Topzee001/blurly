#!/usr/bin/env bash
# Validate the exact signing identity Gradle will use, before a long build.
set -euo pipefail

: "${CM_KEYSTORE_PATH:?Upload the keystore with reference blurly_upload_keystore.}"
: "${CM_KEYSTORE_PASSWORD:?Set the keystore/store password on the signing identity.}"
: "${CM_KEY_ALIAS:?Set the key alias on the signing identity.}"
: "${CM_KEY_PASSWORD:?Set the private key password on the signing identity.}"

# JKS can use different passwords for the store and the private key. Listing
# the store validates only the first password, so also try recovering the key.
signing_check_dir=$(mktemp -d)
trap 'rm -rf "$signing_check_dir"' EXIT

if ! keytool -list \
  -keystore "$CM_KEYSTORE_PATH" \
  -storepass:env CM_KEYSTORE_PASSWORD \
  -alias "$CM_KEY_ALIAS" \
  >"$signing_check_dir/list.log" 2>&1; then
  cat "$signing_check_dir/list.log"
  printf '%s\n' 'Could not open the keystore or find the alias. Check the file, store password and alias.'
  exit 1
fi

if ! keytool -importkeystore \
  -srckeystore "$CM_KEYSTORE_PATH" \
  -srcstorepass:env CM_KEYSTORE_PASSWORD \
  -srcalias "$CM_KEY_ALIAS" \
  -srckeypass:env CM_KEY_PASSWORD \
  -destkeystore "$signing_check_dir/check.p12" \
  -deststoretype PKCS12 \
  -deststorepass:env CM_KEYSTORE_PASSWORD \
  -noprompt \
  >"$signing_check_dir/keytool.log" 2>&1; then
  # keytool writes some failures to stdout. Preserve the actual diagnostic.
  cat "$signing_check_dir/keytool.log"
  printf '\nCould not recover the Android private key for alias %s.\n' "$CM_KEY_ALIAS"
  printf '%s\n' \
    'In Codemagic, edit the blurly_upload_keystore signing identity.' \
    'Check the private key password separately from the keystore password.' \
    'If you accepted the default key password during creation, they are the same.' \
    'The JKS format warning alone does not prevent signing.'
  exit 1
fi

printf '%s\n' 'Android store password, alias and private key password are valid.'
