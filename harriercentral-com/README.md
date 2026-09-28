# harriercentral.com

The Harrier Central marketing site: https://www.harriercentral.com

A static site on the Azure Static Web App **`harriercentral-web`** (resource
group `harrier`, Free tier). DNS for `harriercentral.com` is an Azure DNS
zone in the same resource group; the apex and `www` are custom hostnames on
the app.

## What is here

`site/` is the whole site, exactly as served — the folder a deploy uploads.

It started as a Wayback Machine mirror of the old WordPress site (2026-08-23)
and was partly redesigned by hand on 2026-08-24: the homepage, FAQ, About Us,
Contact, News, the privacy policy (Play Console's privacy URL), the
Instructions hub and `/index.php/delete_my_account/`. Those share
`site/css/hc.css`. The rest is still the mirrored WordPress markup — some of
its theme files never reached the Wayback Machine, so those pages look
bare-bones.

Until 2026-09-28 the site existed only on Azure, and every edit meant
crawling it back first. It was recovered into this folder by crawling the
live app and every URL the Wayback Machine ever recorded for the domain
(506 files).

`site/staticwebapp.config.json` holds the redirects. The old add-kennel
pages redirect (301) to **https://www.hashruns.org/add-kennel** (E12.F1.S7);
they used to submit to the API's anonymous `ProcessWpForm` endpoint, which
is gone.

## Deploying

```bash
./tools/deploy_harriercentral_com.sh
```

**A deploy replaces the whole site** with `site/`: anything not in the
folder disappears from the web. Production deploys follow the same rule as
everything else — only when James asks.
