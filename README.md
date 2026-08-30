# Cloady Templates

The application catalog for [Cloady](https://cloady.com), as plain compose projects.

Every top-level folder is a standard, locally runnable Docker Compose project named
after its catalog slug:

```
supabase/
  docker-compose.yml   the template - vanilla compose, no custom extensions
  configs/             files referenced by the compose configs section
  env_schema.json      Cloady sidecar: env var titles, secrets, generate directives
  icon.png             catalog tile icon
```

The compose file is the contract: `cd supabase && docker compose up` works with no
Cloady knowledge. The sidecars are additive - deleting them leaves a working compose
project. Cloady-specific behaviour derives from native compose semantics only:
`ports:` are public, `expose:` is private, volume sizes come from
`volumes.<name>.driver_opts.size`, and a service declaring `env_file: [".env"]`
receives the app's environment variables at deploy time.

## Publishing

CI validates every changed project and publishes it as an OCI artifact to
`ghcr.io/neptolab/cloady-templates/<slug>:<version>`.

## Syncing into a Cloady control plane

```
npx tsx scripts/sync-templates.ts /path/to/this/checkout
```

The control plane keeps its `applications` table as a cache derived from this repo;
this repo is the source of truth. Deployed instances snapshot their template at
install time and are never affected by catalog updates.

## Provenance

Most templates originate from upstream compose collections; provenance and
catalog metadata (name, hint, sort order) live in the Cloady control plane.
Config files vendored from upstream projects (for example Supabase's kong.yml
and SQL bootstrap, Apache-2.0) retain their original licenses. See LICENSES.md.
