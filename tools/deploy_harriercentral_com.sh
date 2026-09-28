#!/usr/bin/env bash
# Deploy harriercentral.com (harriercentral-com/site) to the Azure Static Web
# App harriercentral-web. A deploy REPLACES the whole site with the folder.
# See harriercentral-com/README.md. Needs `az login`.
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SITE="$REPO_ROOT/harriercentral-com/site"
[[ -f "$SITE/index.html" ]] || { echo "No site at $SITE" >&2; exit 1; }
echo "Deploying $(find "$SITE" -type f | wc -l | tr -d ' ') files from $SITE"
TOKEN="$(az staticwebapp secrets list -n harriercentral-web -g harrier --query properties.apiKey -o tsv)"
npx --yes @azure/static-web-apps-cli deploy "$SITE" --deployment-token "$TOKEN" --env production
