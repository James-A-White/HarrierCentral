#!/usr/bin/env bash
# Stages the Next.js standalone build into deploy.zip for Azure App Service.
#
# Run from public-web/ AFTER `npm run build`:
#   ./scripts/stage-standalone.sh
#
# Steps:
#   1. Copy public/ and .next/static into the standalone bundle (Next doesn't).
#   2. Inject the Linux x64 sharp binaries the /_next/image optimizer needs at
#      runtime. We build on macOS, so node_modules holds darwin binaries and
#      npm prunes the "wrong" platform on every install — the linux packages
#      are therefore installed into a throwaway prefix and copied in, leaving
#      the project's node_modules untouched.
#   3. Zip the bundle to ../deploy.zip (i.e. public-web/deploy.zip).
#
# Deploy the result with:
#   az webapp deploy --name harriercentralpublicweb --resource-group harrier \
#     --src-path deploy.zip --type zip
set -euo pipefail
cd "$(dirname "$0")/.."

STANDALONE=.next/standalone
[ -d "$STANDALONE" ] || { echo "ERROR: $STANDALONE missing — run 'npm run build' first" >&2; exit 1; }

echo "==> Copying public/ and .next/static into standalone bundle"
cp -r public "$STANDALONE/public"
mkdir -p "$STANDALONE/.next"
cp -r .next/static "$STANDALONE/.next/static"

# sharp version must match what the app depends on so the loader accepts it.
SHARP_VERSION=$(node -p "require('./node_modules/sharp/package.json').version")
echo "==> Injecting Linux x64 sharp $SHARP_VERSION binaries for the image optimizer"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
npm install --prefix "$TMP" --force --no-save --no-audit --no-fund \
  --os=linux --cpu=x64 --libc=glibc "sharp@$SHARP_VERSION" >/dev/null 2>&1
mkdir -p "$STANDALONE/node_modules/@img"
cp -r "$TMP/node_modules/@img/sharp-linux-x64" \
      "$TMP/node_modules/@img/sharp-libvips-linux-x64" \
      "$STANDALONE/node_modules/@img/"

for pkg in sharp-linux-x64 sharp-libvips-linux-x64; do
  [ -d "$STANDALONE/node_modules/@img/$pkg" ] || { echo "ERROR: @img/$pkg missing from bundle" >&2; exit 1; }
done

echo "==> Zipping to deploy.zip"
rm -f deploy.zip
(cd "$STANDALONE" && zip -rq ../../deploy.zip .)
echo "==> Done: $(du -h deploy.zip | cut -f1) deploy.zip"
