# SQL Bootcamp Labs — Data Engineering

Hands-on SQL labs for the Data Engineering bootcamp: aggregate functions,
`GROUP BY`/`HAVING`, joins & unions, `CASE WHEN` / pivot tables, and
subqueries. Everything runs against a local MySQL instance in a container —
no manual database setup required.

**New to containers, the terminal, or SQL entirely?** Skip straight to
[Step-by-Step Onboarding](#step-by-step-onboarding) — it assumes nothing.
Already comfortable with containers? Use the [Quick Start](#quick-start) below.

**Just want to write SQL, no installs?** Once the lab is running
(`podman-compose up -d`), open `http://<instructor-ip>:8888` in any
browser — that's a shared JupyterLab instance with the database connection
and the `exercises/` folder already there. See
[Option A in Step 5](#step-5--connect-and-run-your-first-query).

**Repo maintenance:** this repo is managed by `core session` — the
org-runink platform's own sovereign coding agent (`core` CLI, see
`~/Documents/core`) — via the `runink-core-agents` GitHub App, rather than
by ad hoc AI-assistant edits. It always lands changes as a draft PR on a
`core-session/*` branch for human review, never a direct push to `main`.

## Why Podman and not Docker

This lab runs on [Podman](https://podman.io/), not Docker. Two reasons, and
it's worth being precise about the first one because the internet is sloppy
about it:

**1. Licensing.** Docker *Engine* — the Linux daemon and CLI — is Apache-2.0
and free for anyone. The cost is in **Docker Desktop**, which is how you get
Docker at all on macOS and Windows: it requires a paid per-seat subscription
for professional use inside organisations above Docker's size threshold
(currently >250 employees or >$10M annual revenue). Students on macOS or
Windows therefore can't be told "just install Docker" without pointing them
at a product many of their future employers must pay for. Podman is
Apache-2.0 all the way through, on every OS, with no subscription tier and no
size threshold — so the tool you learn here is the tool you can actually use
at work.

**2. Rootless by default.** Podman runs containers as your own unprivileged
user with no background daemon. Docker's daemon runs as root, and putting
your user in the `docker` group is effectively granting passwordless root —
a detail worth knowing early if you're heading into data engineering.

Practically, nothing you type changes much: Podman implements the same
Compose file format and the same CLI verbs. `podman` is a drop-in for
`docker` in almost every command in this guide, and the file is still called
`docker-compose.yml` because that's the filename `podman-compose` looks for
by default — the format is an open spec, the name is just history.

The two places rootless genuinely differs are called out in
`docker-compose.yml` with comments: images must be **fully qualified**
(`docker.io/library/mysql:latest`, not `mysql:latest`), and the
`exercises/` bind mount needs `userns_mode: keep-id` so Jupyter can save your
work. Both are already configured for you.

## What's in here

Two databases, auto-created and auto-seeded the first time the container
starts:

| Database     | Tables                                   | Rows                                              | Used for |
|--------------|-------------------------------------------|----------------------------------------------------|----------|
| `superstore` | `customers`, `products`, `orders`, `returns` | 1,832 customers, 1,234 products, 8,060 order line items (2009–2012), 558 returns | Aggregate functions, `GROUP BY`/`HAVING`, joins, `CASE WHEN`/pivots, subqueries |
| `company`    | `employee`, `hire`, `hobby`, `review`     | 7 employees, 6 hire records, 4 hobbies, 6 reviews (intentionally sparse) | Joins, subqueries |

`superstore` is real order data, not synthetic: `orders` is one row per
product line item, so `OrderID` repeats when an order has multiple
products — `LineID` (`AUTO_INCREMENT`) is the actual primary key.

```
sql-bootcamp-labs/
├── README.md
├── docker-compose.yml        # recommended way to run the lab (via podman-compose)
├── db-init/                  # schema + seed SQL, auto-run on first container start
├── exercises/                # student worksheets (no answers) + sample CSVs — also mounted into jupyter-sql
│   └── extra/                # optional extra practice, one file per lecture
├── solutions/                # reference solutions (not exposed in the shared Jupyter console — see note below)
│   └── extra/                # solutions for the extra practice, with expected results
├── jupyter-sql/               # shared browser SQL console (JupyterLab + jupysql), pre-wired to mysql-lan
└── scripts/generate_superstore_data.py   # regenerates the superstore seed data
```

The `superstore` schema and its entity relationships (`customers` →
`orders` ← `products`, `orders` → `returns`) follow the ERD from the
"Introduction to Entity Relationships" lecture. The `company` schema's row
counts are intentionally small and intentionally sparse (not every
employee has a hire record, hobby, or review) so `LEFT`/`RIGHT`/`FULL`
joins produce visibly different, meaningful results.

## Quick Start

For students already comfortable with git and containers:

```bash
git clone https://github.com/org-runink/sql-bootcamp-labs.git
cd sql-bootcamp-labs
podman-compose up -d
```
Then either open `http://localhost:8888` in a browser for the shared
Jupyter SQL console (no login, `exercises/` is already there — see
[Option A](#step-5--connect-and-run-your-first-query)), or:
```bash
podman exec -it mysql-lan mysql -uroot -p123456
```
Then jump to [Doing the exercises](#doing-the-exercises).

---

## Step-by-Step Onboarding

A complete walkthrough from zero. Every step has a checkpoint so you know
whether it worked before moving to the next one. If a step's checkpoint
doesn't match, see [Troubleshooting](#troubleshooting) before continuing.

### Step 0 — What you'll be using

A quick glossary, since the rest of this guide uses these words a lot:

- **Terminal** — a text-based window where you type commands instead of
  clicking. macOS: `Terminal.app` or `iTerm2`. Windows: `Git Bash` (installed
  with Git) or `WSL`. Linux: whatever terminal your desktop ships with.
- **Podman** — a tool that runs pre-packaged applications ("containers")
  without you having to install and configure them yourself. We use it to
  run MySQL so nobody has to install MySQL by hand. It is the open-source,
  daemonless equivalent of Docker — see
  [Why Podman and not Docker](#why-podman-and-not-docker).
- **Container** — a running instance of an application (here: our MySQL
  server), isolated from the rest of your machine.
- **Image** — the packaged blueprint a container is started from (here:
  `docker.io/library/mysql:latest`, downloaded from Docker Hub the first time
  you run it — Docker Hub is a public image registry, and Podman pulls from
  it just fine).
- **Rootless** — Podman runs your containers as *your* user, not as root.
  Nothing here needs `sudo` except installing Podman itself.
- **`podman-compose`** — a tool for describing "start these containers with
  these settings" in a file (`docker-compose.yml`) instead of one long
  command.
- **Client** — a program you use to talk to the database and run SQL
  queries: the `mysql` command-line tool, a graphical app like DBeaver, or
  (recommended if this is all new) the browser-based Jupyter SQL console
  this lab ships with — no install required.

### Step 1 — Install Git (if you don't have it)

Check first:
```bash
git --version
```
If that prints a version number, skip to Step 2. Otherwise:

- **macOS**: `xcode-select --install` (installs Git via Apple's Command
  Line Tools), or `brew install git` if you have Homebrew.
- **Windows**: download and run the installer from
  https://git-scm.com/download/win — accept the defaults. This also
  installs **Git Bash**, a terminal you can use for every command below.
- **Linux (Debian/Ubuntu)**: `sudo apt install git`
- **Linux (Arch/CachyOS)**: `sudo pacman -S git`

✅ **Checkpoint:** `git --version` prints something like `git version 2.43.0`.

### Step 2 — Get the lab files onto your machine

"Cloning" downloads a copy of this repository to your computer.
```bash
git clone https://github.com/org-runink/sql-bootcamp-labs.git
cd sql-bootcamp-labs
```

✅ **Checkpoint:** `ls` (or `dir` on Windows) shows `README.md`,
`docker-compose.yml`, `db-init/`, `exercises/`, `solutions/`.

*Don't want to use git at all?* Click the green "Code" button on the
GitHub repo page → "Download ZIP" → unzip it → open a terminal inside
the unzipped folder. Everything below works the same either way.

### Step 3 — Install Podman

You need `podman` and `podman-compose`. Pick your OS:

**macOS**
```bash
brew install podman podman-compose
podman machine init          # one-time: creates the small Linux VM Podman runs containers in
podman machine start
```
(Containers are a Linux technology, so macOS needs a lightweight VM. Podman
manages it for you; you only ever run `podman machine start` again after a
reboot.)

**Windows**
Install [Podman Desktop](https://podman-desktop.io/) (free, open source, no
subscription) — it will offer to set up WSL2 for you, which you should
accept. Then open it and click "Initialize and start" on the Podman machine.
`podman-compose` is bundled. Or from a terminal with `winget`:
```powershell
winget install RedHat.Podman-Desktop
```

**Linux (Debian/Ubuntu)**
```bash
sudo apt install podman podman-compose
```

**Linux (Arch/CachyOS)**
```bash
sudo pacman -S podman podman-compose
```

No group membership, no daemon to enable, no logging out and back in — that
whole class of Docker setup problem doesn't exist here.

✅ **Checkpoint:** run both of these —
```bash
podman --version
podman run --rm docker.io/library/hello-world
```
The second command should print a paragraph starting with `"Hello from
Docker!"` (yes, really — that's the name of the test image, and Podman runs
it unchanged). If it fails, see [Troubleshooting](#troubleshooting).

### Step 4 — Start the lab

From inside the `sql-bootcamp-labs` folder:
```bash
podman-compose up -d
```
The first run downloads MySQL (a few hundred MB — can take a couple of
minutes on a slow connection), builds the Jupyter console image, and then
automatically creates and fills both databases. You'll see a wall of output;
that's normal.

Check that it's actually up and healthy:
```bash
podman ps
```

✅ **Checkpoint:** the `STATUS` column says something like
`Up X seconds (healthy)` for `mysql-lan`. If it says `(starting)`, wait a few
seconds and run the command again — first-time seeding of 3,000+ rows takes
a little while. `sql-console-lan` deliberately waits for MySQL to report
healthy before it starts, so seeing only one container for the first ~20
seconds is expected.

Want to watch it happen instead of waiting blind?
```bash
podman logs -f mysql-lan
```
(Press `Ctrl+C` to stop watching — this does not stop the container.)

*Prefer not to use compose at all?* The equivalent plain `podman run`,
matching the style used in class:
```bash
podman run --name mysql-lan \
  -p 0.0.0.0:3306:3306 \
  -e MYSQL_ROOT_PASSWORD=123456 \
  -v "$(pwd)/db-init:/docker-entrypoint-initdb.d" \
  -d docker.io/library/mysql:latest
```
`-p 0.0.0.0:3306:3306` binds MySQL to every network interface on the
host, not just `localhost` — that's deliberate here: it lets students on
the same classroom LAN connect to one shared instance (the instructor's
laptop) instead of each running their own container. Anyone on that
network who knows the port can attempt to connect, so only do this on a
network you trust (e.g. an isolated classroom Wi-Fi, not a public one),
and treat `123456` as a throwaway lab password, never a real one.

### Step 5 — Connect and run your first query

**Option A — the shared Jupyter SQL console (recommended, no install at
all):** `docker-compose.yml` runs a small JupyterLab instance
(`jupyter-sql/`) pre-wired to `mysql-lan`, so you can run queries and do
the exercises from a browser without installing anything. It comes up
automatically with `podman-compose up -d`.

Open `http://localhost:8888` (or the instructor machine's LAN IP, port
`8888`) — no login required. In the file browser on the left:
- `SQL_Console.ipynb` — the database connection is already configured in
  the first cell. Run it once, then write queries in `%%sql` cells below
  it, e.g.:
  ```
  %%sql
  SELECT * FROM superstore.products LIMIT 5;
  ```
- `exercises/` — the same worksheets described in
  [Doing the exercises](#doing-the-exercises), opened directly from the
  repo. Open one, read a task comment, then run your answer as a `%%sql`
  cell in `SQL_Console.ipynb` (or paste it into a new cell right in the
  exercise file's own scratch space).

Everything in this lab can be done in SQL — you shouldn't need any other
Python here. This JupyterLab instance is **shared** across everyone on the
classroom LAN (same as the database), not one-per-student: edits to
`exercises/` or `SQL_Console.ipynb` are visible to everyone connected. If
you'd rather keep your own private copy of your work, edit the exercise
files in your local git clone instead and run queries against
`mysql-lan` with any client below.

✅ **Checkpoint:** running `SELECT COUNT(*) FROM superstore.customers;`
returns `1832`.

**Option B — no extra install, using the container's own client:**
```bash
podman exec -it mysql-lan mysql -uroot -p123456
```
You should land on a `mysql>` prompt. Try:
```sql
USE superstore;
SELECT COUNT(*) FROM customers;
```
✅ **Checkpoint:** it returns `1832`.

**Option C — a `mysql` client installed on your own machine:**
```bash
# macOS
brew install mysql-client
# Debian/Ubuntu
sudo apt install mysql-client
# Arch/CachyOS
sudo pacman -S mysql-clients
```
Then:
```bash
mysql -h 127.0.0.1 -P 3306 -u root -p
# password: 123456
```
Students connecting over the classroom LAN (instead of running their own
container) use the instructor's machine's IP instead of `127.0.0.1`,
e.g. `mysql -h 192.168.1.42 -P 3306 -u root -p`.

**Option D — a graphical tool:**
[DBeaver](https://dbeaver.io/) (free) or [TablePlus](https://tableplus.com/)
let you browse tables, click around the schema, and see results in a
spreadsheet-like grid instead of a terminal. Create a new MySQL
connection with:
- Host: `127.0.0.1` (or the instructor's LAN IP, if connecting remotely)
- Port: `3306`
- Username: `root`
- Password: `123456`

Then open a SQL editor against the `superstore` or `company` database and
run any query in this repo.

### Step 6 — Confirm both databases seeded correctly

Run this (any client from Step 5 works) and compare against the
expected counts:
```sql
USE superstore;
SELECT COUNT(*) FROM customers;  -- 1832
SELECT COUNT(*) FROM products;   -- 1234
SELECT COUNT(*) FROM orders;     -- 8060
SELECT COUNT(*) FROM returns;    -- 558

USE company;
SELECT COUNT(*) FROM employee;   -- 7
SELECT COUNT(*) FROM hire;       -- 6
SELECT COUNT(*) FROM hobby;      -- 4
SELECT COUNT(*) FROM review;     -- 6
```

✅ **Checkpoint:** all eight numbers match. If they don't, see
[Troubleshooting](#troubleshooting).

You're fully set up — move on to the exercises below.

---

## Doing the exercises

Work through `exercises/` in order. Each file has the task prompts as SQL
comments with blank space underneath for you to write your own query. Open
these files either from your local git clone, or straight from the
`exercises/` folder in the Jupyter SQL console (Option A in Step 5) — same
files either way. Suggested workflow per file:

1. Read the comment describing the task.
2. Write your query underneath it and run it against the live database
   (any client from Step 5 works).
3. Sanity-check your result against the row counts/values described in
   the comment, or against the matching file in `solutions/`.
4. If you're stuck for more than a few minutes, peek at just the next
   line of the matching solution file rather than the whole thing — it's
   more useful to unstick yourself than to solve it end-to-end.

1. `Part1_Exercise_Build_Database_and_Tables.sql` — DDL practice: build a
   scratch database from CSVs by hand (the main `superstore`/`company`
   databases are already built for you by `db-init/`, so this is purely
   for practicing `CREATE TABLE`, primary/foreign keys, and `LOAD DATA
   LOCAL INFILE`). Run this one from a mysql client on your **host**
   machine (Option B or C), not inside the container and not from the
   Jupyter console, since `LOCAL INFILE` reads files from the client's
   filesystem.
2. `Part2_Exercise_Joins.sql` — `INNER`/`LEFT`/`RIGHT`/`FULL` joins on `company`.
3. `Part3_Exercise_CaseWhen_Pivot.sql` — `CASE WHEN` and pivot tables on `superstore`.
4. `Part3_Exercise_Subqueries.sql` — subqueries on `company` and `superstore`.

### Extra practice

`exercises/extra/` holds optional reinforcement exercises, one file per
lecture (aggregates, joins & set operators, subqueries, CASE WHEN/pivots),
plus three that go beyond the lectures (views and what "materialized" really
means here, cross-database queries and runtime objects, and ER modelling).
Solutions are in `solutions/extra/` and quote the actual expected results so
you can check yourself. See
[`exercises/extra/README.md`](exercises/extra/README.md) — it also flags the
places where the slides and MySQL disagree (`FULL OUTER JOIN` doesn't exist;
`INTERSECT`/`EXCEPT` do work; materialized views silently aren't).

**Extra 07 is a Jupyter notebook**, not a `.sql` file, because its ER
diagrams are written in [Mermaid](https://mermaid.js.org/) and JupyterLab
renders them as actual pictures inside the notebook. You read the problem,
draw your answer by editing a Markdown cell, run it to see the diagram, and
write the DDL in a `%%sql` cell directly underneath — all in one place.
Open it from the `exercises/extra/` folder in the Jupyter console (Option A
in Step 5).

## Troubleshooting

**`short-name "mysql:latest" did not resolve to an alias`**
Rootless Podman ships no default registry list, so it refuses to guess which
registry a bare image name means. Use the fully qualified name —
`docker.io/library/mysql:latest`. The compose file in this repo already
does; you'll only hit this if you type your own `podman run` or `podman pull`
with a short name.

**Jupyter says `Permission denied` when saving a notebook under `exercises/`**
Rootless Podman maps your host user to a different UID inside the container,
so a bind-mounted folder is read-only to the container user by default. The
`userns_mode: "keep-id:uid=1000,gid=100"` line on the `sql-console` service
fixes this by mapping your user onto `jovyan`. If you removed that line, put
it back and run `podman-compose up -d --force-recreate sql-console`.

**`Cannot connect to Podman` / `podman machine` errors on macOS or Windows**
The Linux VM that Podman runs containers in isn't started. Run
`podman machine start` (macOS/CLI) or open Podman Desktop and start the
machine there. It does not auto-start after a reboot.

**Image pull fails with `network is unreachable` mentioning an IPv6 address**
Some networks/VPNs advertise IPv6 without actually routing it. The pull tried
IPv6 first and failed — just retry `podman-compose up -d`; it falls back to
IPv4 automatically, and layers already downloaded are cached.

**`port is already allocated` / `address already in use` for port 3306**
Something else on your machine (a previous MySQL install, a leftover Docker
container from before this lab moved to Podman) is already using port 3306.
Either stop that service, or change the host port in `docker-compose.yml` —
under `ports:`, change `"0.0.0.0:3306:3306"` to e.g. `"0.0.0.0:3307:3306"`
and connect on port 3307 instead.

**Ports below 1024 refuse to bind**
Rootless containers can't bind privileged ports without extra configuration.
Nothing in this lab needs one (3306 and 8888 are both fine) — but it's the
one real functional difference you'll notice versus rootful Docker.

**Row counts don't match after `podman-compose up -d`**
The seed scripts only run the *first* time a container's data volume is
created — if you previously started a container (even one that failed
partway), the volume may already exist with partial data. Wipe it and
start clean:
```bash
podman-compose down -v
podman-compose up -d
```

**Still stuck?** Run `podman logs mysql-lan` and read the last ~30
lines — MySQL prints a clear error near the bottom when something in
`db-init/` fails to apply. Share that output with your instructor.

## Resetting the lab

```bash
podman-compose down -v   # drops the containers AND their data volumes
podman-compose up -d     # re-creates and re-seeds from scratch
```

## Regenerating the seed data

`db-init/01_superstore_products.sql` through `04_superstore_returns.sql`
are real order data (not synthetic) — see the note under
[What's in here](#whats-in-here). To reload them from scratch, re-run the
files in order against the running container: `podman exec -i mysql-lan
mysql -uroot -p123456 < db-init/00_superstore_schema.sql`, then the
`01`–`04` files the same way.

`exercises/data/*.csv` (used only by the standalone Part 1 DDL-practice
exercise, against a separate `superstore_practice` database) is still
synthetic, generated by `scripts/generate_superstore_data.py` (fixed random
seed, so output is reproducible). Edit constants at the top of the script
(row counts, date range, categories) and re-run:
```bash
python3 scripts/generate_superstore_data.py
```
Then re-run `podman-compose down -v && podman-compose up -d` to reseed.
