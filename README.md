# demo.hello-world

The demo module for Ulmero, in module format 1. Copy it to start a new module.
See `docs/MODULES.md` in `ulmero/platform` for the format.

It shows each part a module can have:

| Part | File |
|---|---|
| The manifest: feature key, page, nav item, routes, npm packages | `module.json` |
| Tables, created on first install | `schema.sql` |
| A migration and a scheduled task | `apps/api/register.ts` |
| Routes, gated by the feature key | `apps/api/server/api/demo/hello-world/` |
| Queries shared by the routes, and the module's own npm package (`left-pad`) | `apps/api/server/lib/hello-world.ts` |
| The admin page | `apps/admin/app/pages/demo/hello-world/index.vue` |
| The page's text in English, Spanish and French | `apps/admin/i18n/locales/` |

## Run it

In a core checkout, clone this repository to `modules/demo/hello-world` and run
`bun run dev`. To run it the way a customer build does, use `scripts/dev.sh`.

## Publish it

Raise `version` in `module.json` and merge to `main`. The workflow in
`.github/workflows/publish.yml` calls the publish workflow of `ulmero/platform`.
A version is published once: the same version again is refused.
