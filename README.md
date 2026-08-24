# SQL Bootcamp Labs — Data Engineering

Hands-on SQL labs for the Data Engineering bootcamp: aggregate functions,
`GROUP BY`/`HAVING`, joins & unions, `CASE WHEN` / pivot tables, and
subqueries. Everything runs against a local MySQL instance in Docker — no
manual database setup required.

**New to Docker, the terminal, or SQL entirely?** Skip straight to
[Step-by-Step Onboarding](#step-by-step-onboarding) — it assumes nothing.
Already comfortable with Docker? Use the [Quick Start](#quick-start) below.

**Just want to write SQL, no installs?** Once the lab is running
(`docker compose up -d`), open `http://<instructor-ip>:8888` in any
browser — that's a shared JupyterLab instance with the database connection
and the `exercises/` folder already there. See
[Option A in Step 5](#step-5--connect-and-run-your-first-query).

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
├── docker-compose.yml        # recommended way to run the lab
├── db-init/                  # schema + seed SQL, auto-run on first container start
├── exercises/                # student worksheets (no answers) + sample CSVs — also mounted into jupyter-sql
├── solutions/                # reference solutions (not exposed in the shared Jupyter console — see note below)
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

For students already comfortable with git/Docker:

```bash
git clone https://github.com/paesdan/sql-bootcamp-labs.git
cd sql-bootcamp-labs
docker compose up -d
```
Then either open `http://localhost:8888` in a browser for the shared
Jupyter SQL console (no login, `exercises/` is already there — see
[Option A](#step-5--connect-and-run-your-first-query)), or:
```bash
docker exec -it mysql-lan mysql -uroot -p123456
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
- **Docker** — a tool that runs pre-packaged applications ("containers")
  without you having to install and configure them yourself. We use it to
  run MySQL so nobody has to install MySQL by hand.
- **Container** — a running instance of an application (here: our MySQL
  server), isolated from the rest of your machine.
- **Image** — the packaged blueprint a container is started from (here:
  `mysql:latest`, downloaded from Docker Hub the first time you run it).
- **`docker compose`** — a tool for describing "start this container with
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
git clone https://github.com/paesdan/sql-bootcamp-labs.git
cd sql-bootcamp-labs
```

✅ **Checkpoint:** `ls` (or `dir` on Windows) shows `README.md`,
`docker-compose.yml`, `db-init/`, `exercises/`, `solutions/`.

*Don't want to use git at all?* Click the green "Code" button on the
GitHub repo page → "Download ZIP" → unzip it → open a terminal inside
the unzipped folder. Everything below works the same either way.

### Step 3 — Install Docker

You need Docker installed and running. Pick your OS:

**macOS**
```bash
brew install --cask docker
open -a Docker   # first launch finishes setup; wait for the whale icon in the menu bar
```
Or download Docker Desktop directly from
https://www.docker.com/products/docker-desktop/ and drag it into
Applications like any other app. Open it and wait for the whale icon in
the menu bar to stop animating — that means it's ready.

**Windows**
Download and install Docker Desktop from
https://www.docker.com/products/docker-desktop/ (it will offer to set up
WSL2 for you — accept that). Launch Docker Desktop from the Start menu
and wait until it says "Docker Desktop is running" in the bottom left.

**Linux (Debian/Ubuntu)**
```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
```
Then **log all the way out and back in** (or reboot) — Linux only applies
new group memberships to *new* login sessions, so this step is easy to
think you've done when you haven't.

**Linux (Arch/CachyOS)**
```bash
sudo pacman -S docker docker-compose
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```
Same as above: log out and back in afterward.

✅ **Checkpoint:** run both of these —
```bash
docker --version
docker run hello-world
```
The second command should print a paragraph starting with `"Hello from
Docker!"`. If you instead see `permission denied` or `Cannot connect to
the Docker daemon`, see [Troubleshooting](#troubleshooting).

### Step 4 — Start the lab

From inside the `sql-bootcamp-labs` folder:
```bash
docker compose up -d
```
The first run downloads MySQL (a few hundred MB — can take a couple of
minutes on a slow connection) and then automatically builds and fills in
both databases. You'll see a wall of output; that's normal.

Check that it's actually up and healthy:
```bash
docker compose ps
```

✅ **Checkpoint:** the `STATUS` column says something like
`Up X seconds (healthy)`. If it says `(health: starting)`, wait a few
seconds and run the command again — first-time seeding of 3,000+ rows
takes a little while.

Want to watch it happen instead of waiting blind?
```bash
docker compose logs -f mysql
```
(Press `Ctrl+C` to stop watching — this does not stop the container.)

*Prefer not to use docker compose?* The equivalent plain `docker run`,
matching the style used in class:
```bash
docker run --name mysql-lan \
  -p 0.0.0.0:3306:3306 \
  -e MYSQL_ROOT_PASSWORD=123456 \
  -v "$(pwd)/db-init:/docker-entrypoint-initdb.d" \
  -d mysql:latest
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
automatically with `docker compose up -d`.

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
docker exec -it mysql-lan mysql -uroot -p123456
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

## Troubleshooting

**`permission denied while trying to connect to the Docker daemon socket`**
Your user was added to the `docker` group, but the *current* terminal
session predates that change — Linux only picks up new group memberships
on new logins. Close and reopen your terminal (or fully log out and back
in). If you're in a rush and don't want to restart your session, prefix
commands with `sg docker -c "..."`, e.g. `sg docker -c "docker compose up -d"`.

**`Cannot connect to the Docker daemon. Is the docker daemon running?`**
Docker Desktop (macOS/Windows) isn't open yet — launch it and wait for
the whale icon to settle. On Linux, the background service isn't running:
`sudo systemctl enable --now docker`.

**Image pull fails with `network is unreachable` mentioning an IPv6 address**
Some networks/VPNs advertise IPv6 without actually routing it. Docker
tried IPv6 first and failed — just retry `docker compose up -d`; it falls
back to IPv4 automatically, and layers already downloaded are cached.

**`port is already allocated` / `address already in use` for port 3306**
Something else on your machine (a previous MySQL install, another lab
container) is already using port 3306. Either stop that service, or
change the host port in `docker-compose.yml` — under `ports:`, change
`"3306:3306"` to e.g. `"3307:3306"` and connect on port 3307 instead.

**Row counts don't match after `docker compose up -d`**
The seed scripts only run the *first* time a container's data volume is
created — if you previously started a container (even one that failed
partway), the volume may already exist with partial data. Wipe it and
start clean:
```bash
docker compose down -v
docker compose up -d
```

**Windows: `docker-entrypoint-initdb.d` mount doesn't seem to run anything**
Make sure Docker Desktop's WSL2 integration is enabled for the distro
you're running commands from (Docker Desktop → Settings → Resources →
WSL Integration), and that you're running `docker compose up -d` from
inside that WSL distro's filesystem, not a path under `/mnt/c/...` shared
from Windows — the latter can have file-permission quirks with bind
mounts.

**Still stuck?** Run `docker compose logs mysql` and read the last ~30
lines — MySQL prints a clear error near the bottom when something in
`db-init/` fails to apply. Share that output with your instructor.

## Resetting the lab

```bash
docker compose down -v   # drops the container AND its data volume
docker compose up -d     # re-creates and re-seeds from scratch
```

## Regenerating the seed data

`db-init/01_superstore_products.sql` through `04_superstore_returns.sql`
are real order data (not synthetic) — see the note under
[What's in here](#whats-in-here). To reload them from scratch, re-run the
files in order against the running container: `docker exec -i mysql-lan
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
Then re-run `docker compose down -v && docker compose up -d` to reseed.
