# hcwebapi.azurewebsites.net — redirect only

The kennels' Data API links used to point at `hcwebapi.azurewebsites.net`. That site
was deleted in the August 2026 cost clean-up, so links pasted into kennel websites
stopped working, and the free name could have been taken by anyone. On 2026-10-14 it
was reclaimed as an empty web app on the free F1 plan `Harrier` (RG `HarrierCentral`)
whose only content is `web.config`: every request is redirected (302) to
`https://harriercentralpublicapi.azurewebsites.net/api/<same path>?<same query>`.

Deploy after editing:

```bash
az webapp deploy -g HarrierCentral -n hcwebapi \
  --src-path api/legacy-hcwebapi/web.config --type static --target-path web.config
```

Never put `--` inside the XML comment in `web.config`: it makes the file invalid and
IIS answers every request with a 500.
