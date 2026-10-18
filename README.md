# BoxLang + JRuby Rack examples

Three versions of **Fieldwork Service Desk**, running Ruby web applications inside
BoxLang through [bx-jruby-rack](https://github.com/tonyjunkes/bx-jruby-rack).
Every example is a standalone folder you can copy into your own project.

| Folder | What it demonstrates | Default URL |
| --- | --- | --- |
| [rails](rails/) | Rails MVC, controller validation, Active Record migrations and framework CSRF | http://localhost:8081 |
| [sinatra](sinatra/) | A modular Sinatra app, explicit routes, ERB and Rack middleware | http://localhost:8082 |
| [rack](rack/) | Plain Rack routing, request/response objects, ERB and explicit middleware | http://localhost:8083 |

All three implement the same dashboard, customers, tickets, assignments, priorities,
statuses, comments, search, filters and pagination. They start with five agents,
eight customers, 30 tickets and 45 comments. Switch demo agents without signing in.

## Start an example

Install **Java 21** and **CommandBox 6.3.5**. Run CommandBox with Java 21 too (set
`JAVA_HOME` and put its `bin` directory first on `PATH`). Network access is needed
for module, engine and gem downloads. No separate Ruby, database server, Docker,
Node.js or asset compilation is needed to run the examples.

From any one example folder:

```sh
cd rails
box install
box task run
box server start
```

Visit its default URL for the BoxLang landing page and runtime status. Choose
**Open service desk** to enter Ruby at `/ruby/`. Use `cd sinatra` or `cd rack` instead
for the other implementations. The three default server names and ports are distinct.

Setup installs released core 1.2.0 and Rack 1.1.0 packages, uses core's bundled
JRuby 10.1.2.0, installs locked Java-platform gems, creates a local session secret,
and prepares an embedded JDBC SQLite database. The engine is pinned to
`boxlang@1.18.6+62` (BoxLang runtime 1.18.0).

## Try the same workflow

1. Open the dashboard and inspect priority counts and team workloads.
2. Choose a different **Demo identity** and select **Switch agent**.
3. Create a customer, then create a ticket for that customer.
4. Assign it to an agent, set a priority, and move it to **In progress**.
5. Add an update to its conversation, then mark the ticket **Resolved**.
6. Find it with search and filters; open the customer's ticket history.

## How the pieces fit

```text
CommandBox / Jakarta Servlet host
  /                 BoxLang landing page and curated runtime diagnostics
  /ruby/*           bx-jruby-rack gateway -> framework -> Active Record -> SQLite
                      bx-jruby owns the JRuby runtime
```

The gateway receives Ruby requests before BoxLang parses their bodies. Mounted
requests bypass `Application.bx` callbacks. Only the outer `public/` folder is the
webroot. Ruby middleware serves its own local CSS beneath `/ruby/assets/`.
Ruby source, SQLite data, gems, generated config and modules stay outside it.

Each example owns all runtime code and dependencies. There is deliberately no shared
application package or sibling-checkout dependency. Rails uses Rails controllers
and views; Sinatra uses a modular Sinatra application; Rack uses an explicit router.
All use Active Record 7.2.4, JDBC SQLite adapter 72.1 and driver 3.46.1.1.
Rails stays on the module's verified 7.2.4 baseline; Sinatra is 4.2.1 and Rack is 3.2.7.

## Data and lifecycle

Data persists in each folder's ignored `storage/desk.sqlite3`. Stop the server before
setup, migrations or reset:

```sh
box server stop
box task run          # migrate existing data; seed only a new database
box server start
```

To discard changes and restore the demo:

```sh
box server stop
box task run reset
box server start
```

Setup and reset refuse to run against a running registered server. Reset deletes
only this example's SQLite database and its sidecars; the session secret persists.
If initial seeding is interrupted, use reset to rebuild the incomplete demo.
After moving an example, stop its old server and rerun setup to regenerate absolute
paths. Restart after changing Ruby source; hot Ruby reload is not supported.

These are local development examples. The agent selector is not authentication.
There are no uploads, email, background workers, live updates or WebSockets.
Start with one Ruby worker; each additional worker has its own framework runtime
and database pool. bx-cli/MiniServer web hosting needs a separate adapter and is
not supported by the current servlet gateway.

## Development and verification

Runtime folders contain their own troubleshooting and extension notes. Repository
test tooling additionally needs Node.js 22+ and npm:

```sh
npm ci
npx playwright install chromium
npm test
```

The acceptance runner copies all three examples into ignored paths containing
spaces, installs released modules, runs their documented setup, and tests actual
CommandBox HTTP servers together. It checks persistence, reset, source isolation,
CSRF, escaping, cookie isolation and application workflows. Browser checks capture
desktop/mobile screenshots under `output/`. The runner attempts every server's
shutdown in `finally` and fails the run if any shutdown fails, while retaining
the original test error. Log collection is best effort. CI repeats this on Windows
and Linux. Run `npm run test:cleanup` for the focused cleanup failure-path checks
without installing modules or starting servers; `npm test` includes these checks.

MIT licensed. See [LICENSE](LICENSE).
