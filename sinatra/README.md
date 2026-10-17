# Fieldwork Service Desk: Sinatra

A standalone Sinatra application hosted in BoxLang through
[bx-jruby-rack](https://github.com/tonyjunkes/bx-jruby-rack). Copy this entire folder
anywhere; no other example folder is needed.

## Run

Use Java 21 and CommandBox 6.3.5. Set `JAVA_HOME` to Java 21 and put its `bin` on
`PATH` before running CommandBox. Downloads require network access. No standalone
Ruby, RDBMS, Docker or frontend tooling is required.

```sh
box install
box task run
box server start
```

Open http://localhost:8082/ for the BoxLang host/status page, or
http://localhost:8082/ruby/ for the service desk. Configuration pins the verified
BoxLang servlet engine and released module pair. Setup installs the frozen Ruby
bundle using JRuby shipped with core, generates gateway configuration, creates a
random session secret, migrates SQLite, and seeds only a new database.

Explore the dashboard; switch demo agents; create and edit customers and tickets;
assign work; change priorities/status; add comments; search and filter the queue.
The seeded demo has five agents, eight customers, 30 tickets and 45 comments.
The demo identity selector provides session behavior without login or account setup.

## Stop, update or reset

```sh
box server stop
box task run
box server start
```

Setup preserves edits and the session secret. It applies migrations without
reseeding existing data. To discard data and restore the demo, stop the server
and use `box task run reset` instead. Both tasks reject a running registered server.
If seeding is interrupted, reset rebuilds the incomplete demo.

Restart after Ruby changes. If you relocate this folder, stop the old server first
and rerun setup to regenerate absolute paths. Keep `storage/session-secret` private;
it also appears in ignored generated runtime configuration.

## Layout and customization

```text
app/           Ruby source, Gemfile.lock, views, migrations, app-owned CSS
public/        BoxLang landing/status page; the only CommandBox webroot
task.cfc       Explicit setup/reset using bundled JRuby
server.json    Host, port, engine and gateway settings
modules/       Installed core and Rack packages (ignored)
bundles/       Installed gems (ignored)
config/        Generated host configuration with absolute paths (ignored)
storage/       SQLite database and persistent random secret (ignored)
```

Edit models in `app/app/models`, add timestamped migrations in `app/db/migrate`,
and extend this framework's routes and views. Keep new fields allowlisted in form
handlers and add validation. Apply migrations through setup with the server stopped.
The other examples own independent implementations of the same workflow.

The server binds to loopback and mounts Ruby at `/ruby`. Change the port/name in
`server.json` for another copy. If changing the mount, update the setup config,
cookie paths and BoxLang links, then rerun setup.
Only `public/` should ever be the outer webroot. Do not expose the project root.

## Troubleshooting

- **Module or gateway missing:** run `box install` from this folder before setup.
- **Wrong Java / gem install failure:** check `java -version` and `box info`; run
  CommandBox under Java 21. Keep the lockfile; do not install MRI-native gems.
- **Port in use:** stop the other server or change `web.http.port` in `server.json`.
- **Startup failure:** inspect `box server log`; ensure setup completed and rerun
  it with the server stopped. Do not manually copy generated absolute config.
- **CSRF rejection:** reload the form and retain browser cookies. Every mutation
  requires its framework's authenticity token; tokens are not exposed by diagnostics.
- **Old Ruby code:** stop and start the server after edits.

This is a local development example with one Ruby worker. It does not provide
authentication, production deployment configuration, MiniServer hosting, uploads,
background jobs, email or WebSockets. See the module's deployment guidance before
adapting it for a public environment.
