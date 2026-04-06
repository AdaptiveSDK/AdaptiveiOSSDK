#!/usr/bin/env bash
# =============================================================================
# publish_ios.sh
# Push all AdaptiveSDK podspecs to CocoaPods Trunk (v1.0.5).
# SPM is already available via the 1.0.5 tag pushed to GitHub.
#
# Prerequisites:
#   1. You have a CocoaPods Trunk session:
#        pod trunk register dev_team@aladwaa.org 'AlAdwaa' --description='mac'
#      (check session: pod trunk me)
#   2. Run from the repo root:
#        bash publish_ios.sh
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_ROOT"

echo "──────────────────────────────────────────"
echo " Adaptive iOS SDK v1.0.5 – publish to CocoaPods"
echo "──────────────────────────────────────────"

# ── 1. Verify trunk session ──────────────────────────────────────────────────
echo ""
echo "▶ Verifying CocoaPods trunk session…"
pod trunk me

# ── 2. Push in dependency order ──────────────────────────────────────────────
SPECS=(
  "AdaptiveCore.podspec"
  "AdaptiveAnalytics.podspec"
  "AdaptiveMessaging.podspec"
  "AdaptiveSDK.podspec"
)

for spec in "${SPECS[@]}"; do
  name="${spec%.podspec}"
  echo ""
  echo "▶ Pushing ${name} 1.0.5 to CocoaPods trunk…"
  pod trunk push "$spec" --allow-warnings --skip-import-validation
  echo "✅ ${name} published"
done

echo ""
echo "══════════════════════════════════════════"
echo " ✅  iOS SDK v1.0.5 published!"
echo ""
echo "  CocoaPods (add to Podfile):"
echo "    pod 'AdaptiveCore',      '~> 1.0'"
echo "    pod 'AdaptiveAnalytics', '~> 1.0'"
echo "    pod 'AdaptiveMessaging', '~> 1.0'"
echo "    # or the meta-pod:"
echo "    pod 'AdaptiveSDK',       '~> 1.0'"
echo ""
echo "  Swift Package Manager:"
echo "    URL : https://github.com/AdaptiveSDK/AdaptiveiOSSDK"
echo "    Tag : 1.0.5"
echo "══════════════════════════════════════════"
