# DB TODO

## HC6 Migration

- [ ] Survey all HC6 SPs for calls to non-HC6 SPs originating outside the app/portal
      (Logic Apps, the API shim itself, scheduled jobs, etc.). Known candidates include
      the import-kennel functions. Migrate any remaining dependencies to HC6 so the
      HC3-5 schema artifacts can eventually be cleaned up.
