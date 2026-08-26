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
echo "==> Injecting Linux x64 sharp $SHARP_VERSION for the image optimizer"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
npm install --prefix "$TMP" --force --no-save --no-audit --no-fund \
  --os=linux --cpu=x64 --libc=glibc "sharp@$SHARP_VERSION" >/dev/null 2>&1

# Next's file tracing copies sharp INCOMPLETELY (the traced top-level copy is
# missing its dist/ main entry) and Node resolves next's own NESTED copy
# (next/node_modules/sharp, darwin-only binaries) first — either way sharp
# fails to load on Azure and Next silently serves unoptimized originals
# (observed in prod 2026-08-26). Replace BOTH copies with the complete
# freshly-installed package, including its runtime deps (detect-libc etc.),
# platform binaries under @img/ alongside each copy.
inject_sharp() {
  local dest="$1"
  mkdir -p "$dest"
  for pkg in "$TMP"/node_modules/*/; do
    local name; name=$(basename "$pkg")
    [ "$name" = ".bin" ] && continue
    rm -rf "${dest:?}/$name"
    cp -r "$TMP/node_modules/$name" "$dest/$name"
  done
}
inject_sharp "$STANDALONE/node_modules"
[ -d "$STANDALONE/node_modules/next/node_modules" ] && inject_sharp "$STANDALONE/node_modules/next/node_modules"

for dest in "$STANDALONE/node_modules" "$STANDALONE/node_modules/next/node_modules"; do
  [ -d "$dest" ] || continue
  for f in "@img/sharp-linux-x64/package.json" "@img/sharp-libvips-linux-x64/package.json"; do
    [ -f "$dest/$f" ] || { echo "ERROR: $f missing from $dest" >&2; exit 1; }
  done
  MAIN=$(cd "$dest/sharp" && node -p "require('./package.json').main")
  [ -f "$dest/sharp/$MAIN" ] || { echo "ERROR: sharp main entry ($MAIN) missing in $dest" >&2; exit 1; }
done

echo "==> Zipping to deploy.zip"
rm -f deploy.zip
(cd "$STANDALONE" && zip -rq ../../deploy.zip .)
echo "==> Done: $(du -h deploy.zip | cut -f1) deploy.zip"
