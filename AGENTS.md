# Contributor guidance

Read README.md for the application workflow and each example's README.md before
changing setup. The module's transport contract lives in
[bx-jruby-rack](https://github.com/tonyjunkes/bx-jruby-rack/blob/main/docs/deployment.md).

## Ownership

- Each framework folder is independently copyable. Keep runtime code, gems,
  migrations and assets inside that folder; shared repository code is test-only.
- Preserve feature and seed parity across the three apps while using each
  framework's own routing, rendering and CSRF mechanisms.
- Keep source, gems, modules, generated config, secrets and data outside the outer
  public webroot. Diagnostics expose curated status fields only.
- Setup migrates existing databases without reseeding. Reset requires a stopped
  server and recreates only that example's database. Preserve session secrets.
- Use four-space indentation and document non-obvious lifecycle or compatibility choices.

## Verification

Use Java 21 for CommandBox and bundled JRuby. Install repository test dependencies
with `npm ci` and Chromium with `npx playwright install chromium`.

Run `npm test` for actual CommandBox HTTP/browser acceptance on copied standalone
apps. It downloads released modules, uses paths containing spaces, checks all three
frameworks together, and leaves ignored diagnostics under output/. Windows and
Linux CI run the same suite. Update READMEs when changing public setup or behavior.
