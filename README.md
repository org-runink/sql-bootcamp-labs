# SQL Bootcamp Labs — Data Engineering

Hands-on SQL labs for the Data Engineering bootcamp: aggregate functions,
`GROUP BY`/`HAVING`, joins & unions, `CASE WHEN` / pivot tables, and
subqueries. Everything runs against a local MySQL instance in a container —
no manual database setup required.

**New to containers, the terminal, or SQL entirely?** Skip straight to
[Step-by-Step Onboarding](#step-by-step-onboarding) — it assumes nothing.
Already comfortable with containers? Use the [Quick Start](#quick-start) below.

**Just want to write SQL, no installs?** Once the lab is running
(`podman-compose up -d`, or `docker compose up -d`), open
`http://<instructor-ip>:8888` in any browser — that's a shared JupyterLab
instance with the database connection and the worksheets already there. See
[Option A in Step 5](#step-5--connect-and-run-your-first-query).

**Podman or Docker?** Either works — the same `docker-compose.yml` runs under
both, and both are verified against this lab. Podman is the default
recommendation ([why](#why-podman-and-not-docker)), but if it's fighting you,
use Docker and move on; nothing in the coursework depends on the choice.
**Just never run both at once** — see
[Running both at once](#running-both-at-once).

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
`docker-compose.yml` because that's the filename BOTH tools look for by
default — the format is an open spec, the name is just history.

**If Podman gives you trouble, use Docker.** This is a SQL course, not a
containers course. The same `docker-compose.yml` runs unchanged under
`docker compose up -d` — verified end to end: the databases seed identically,
Jupyter serves, and saving your work in the worksheet folders works. Docker
simply ignores the one Podman-specific line (`userns_mode`), and because the
container user and your host user share uid 1000, the bind mount is writable
without it. Every `podman` command below has a `docker` equivalent — swap the
word.

### Running both at once

Don't. They compete for ports 3306 and 8888, and the failure is confusing
rather than obvious: whichever starts second loses the port, and it's usually
the Jupyter console, which then sits in `Created` and never starts **while the
database still looks healthy**. You get a lab that appears to be up but serves
nothing.

Switching runtimes? Stop the other one first:

```bash
podman-compose down     # before using docker
docker compose down     # before using podman
```

To check what you actually have running:

```bash
podman ps -a
docker ps -a
```

The two places rootless genuinely differs are called out in
`docker-compose.yml` with comments: images must be **fully qualified**
(`docker.io/library/mysql:latest`, not `mysql:latest`), and the
`exercises/` bind mounts need `userns_mode: keep-id` so Jupyter can save your
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

The week 2 day 4 and day 5 sessions are **Python rather than SQL** — data structures
on the first, then control flow, iteration and functions on the second — so
they use neither database. They still live here, and still open in the same Jupyter console, so
there is one place to find every worksheet.

Worksheets are organised **by class session**, in teaching order within each:

```
sql-bootcamp-labs/
├── README.md
├── docker-compose.yml        # recommended way to run the lab (via podman-compose)
├── db-init/                  # schema + seed SQL, auto-run on first container start
├── week2_day2_afternoon/     # the taught syllabus: DDL, aggregates, joins, subqueries, CASE WHEN
│   ├── README.md             #   what this session covers, and its gotchas
│   ├── exercises/            #   01–10, no answers — mounted into the Jupyter console
│   │   └── data/             #   CSVs for worksheet 01
│   └── solutions/            #   01–10, with the actual expected results
├── week2_day3_morning/       # beyond the lectures: views, cross-database, modelling, keys, reports, windows
│   ├── README.md
│   ├── exercises/            #   01–07 (03 is a Jupyter notebook)
│   └── solutions/            #   01–07
├── week2_day4_afternoon/     # Python, not SQL: lists, tuples, sets, dicts, built-ins, capstone
│   ├── README.md             #   needs no database — pure standard library
│   ├── exercises/            #   01–08
│   │   ├── more-practice/    #     a second sheet per topic, same numbering
│   │   └── wcd-originals/    #     the course's own demo + exercise notebooks, unmodified
│   └── solutions/            #   01–08, with the actual expected output
│       ├── more-practice/
│       └── wcd-originals/    #     their matching answer notebooks
├── week2_day5_morning/       # Python, two lectures: control flow (01–08) then functions (09–14)
│   ├── README.md             #   needs no database, and not one import in the whole set
│   ├── exercises/            #   01–14
│   │   ├── data/             #     tab-separated superstore extract, read by worksheet 08
│   │   ├── more-practice/    #     a second sheet per topic, same numbering
│   │   └── wcd-originals/    #     the course's own control-flow demos + exercises, unmodified
│   └── solutions/            #   01–14, with the actual expected output
│       ├── data/             #     the same files, so the solution can be re-run in place
│       ├── more-practice/
│       └── wcd-originals/    #     their matching answer notebooks
├── week3_day1_afternoon/     # Pandas, three lectures: L01 basics, L02 core ops, L03 reading/writing
│   ├── README.md             #   NEEDS pandas in the image -- base-notebook does not ship it
│   ├── exercises/            #   01–14
│   │   └── data/             #     csv / tsv / json / xlsx built from the same superstore extract
│   └── solutions/            #   01–14, with the actual expected output
│       └── data/             #     the same files, so the solution can be re-run in place
├── week3_day2_afternoon/               # Pandas continued: reshaping (L04) and transformation (L05)
│   ├── README.md             #   also needs pandas in the image
│   ├── slides/               #   the two lecture decks
│   ├── exercises/            #   01–10 plus more-practice/
│   │   └── data/             #     long, wide and deliberately messy CSVs
│   └── solutions/            #   01–10, with the actual expected output
├── week3_day3_afternoon/     # Snowflake: Snowsight (01-02) and batch ingestion (03-05)
│   ├── README.md             #   01-02 run in Snowflake; 03-05 run locally and ARE verified
│   ├── exercises/            #   01-05
│   │   ├── data/             #     the lab's two real CSVs -- 1,215 products, 100,000 sales
│   │   ├── snowflake-scripts/#     the lab's four .sql scripts, unmodified
│   │   └── labs/             #     both lab pages, saved for offline reading
│   └── solutions/            #   01-05; 03-05 quote observed output, 01-02 say they do not
├── week3_day4_morning/       # Dimensional modeling and ELT design (L03), end to end
│   ├── README.md             #   builds slide 29's star schema from slide 24's source model
│   ├── exercises/            #   01-10 coded, 11 the group design activity (no code cells)
│   │   └── data/             #     12 CSVs matching slide 24's ER diagram, seeded generator
│   └── solutions/            #   01-10 quote observed output; 11 is a worked example
├── Control_Flow_and_Iteration_Practice/   # the WeCloudData L05 zip, unpacked as shipped
│                             #   same files also split under week2_day5_morning/wcd-originals/
├── solutions/                # ALL answers for all eight sessions, in one place (generated)
├── jupyter-sql/               # shared browser SQL console (JupyterLab + jupysql), pre-wired to mysql-lan
│   ├── Dockerfile            #   base pinned by DIGEST, every pip package pinned to an exact version
│   └── verify_image.py       #   runs as a BUILD step: wrong/missing package -> the build fails
│                             #   carries pandas 3.0.5 + openpyxl/pyarrow/lxml, and curl for the WCD lab
└── scripts/
    ├── generate_superstore_data.py   # regenerates the superstore seed data
    ├── generate_enrollment_data.py   # regenerates the L03 enrollment source database
    ├── collect_solutions.py          # rebuilds the top-level solutions/ mirror
    ├── check_console.py              # verifies the console is serving what is on disk
    ├── check_exercises.py            # every exercise has a solution, none leak answers
    ├── fetch_lab_data.py             # one-time ~136MB fetch so the WCD Advanced lab runs offline
    ├── normalise_notebooks.py        # fixes notebook JSON churn after a JupyterLab save
    └── retitle_worksheets.py         # worksheet titles -> course positions (idempotent)
```

The top-level `solutions/` is a **generated mirror** of each class folder's
own `solutions/`, there so every answer for every session can be opened from
one place. The class folders remain the source of truth — edit there, then
run `python3 scripts/collect_solutions.py`. Note that it **is** mounted into
the Jupyter console — see below.

Each class folder is self-contained — start from its own `README.md`.

**The answers are published in the console.** The top-level `solutions/`
folder is mounted into the shared JupyterLab as `SOLUTIONS/`, so anyone who
opens `:8888` can read every answer to every session. That is deliberate —
it makes teaching from one place easy — but it does mean students can look
ahead at exercises they have not attempted. To make the console
answers-free again, delete the `./solutions` line from `docker-compose.yml`
and re-create the console.

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
podman-compose up -d      # or: docker compose up -d
```
Then either open `http://localhost:8888` in a browser for the shared
Jupyter SQL console (no login, the worksheets are already there — see
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
`docker-compose.yml`, `db-init/`, `week2_day2_afternoon/`,
`week2_day3_morning/`.

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

#### Or install Docker instead

Perfectly fine, and the rest of this guide works with `docker` substituted for
`podman`.

- **macOS**: `brew install --cask docker`, then open Docker Desktop and wait
  for the whale icon to stop animating.
- **Windows**: install Docker Desktop from
  https://www.docker.com/products/docker-desktop/ (accept the WSL2 setup),
  launch it, and wait for "Docker Desktop is running".
- **Linux (Debian/Ubuntu)**:
  ```bash
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker $USER
  ```
  Then **log all the way out and back in** — Linux only applies new group
  memberships to new login sessions, so this step is easy to think you've
  done when you haven't.
- **Linux (Arch/CachyOS)**:
  ```bash
  sudo pacman -S docker docker-compose
  sudo systemctl enable --now docker
  sudo usermod -aG docker $USER
  ```
  Same as above: log out and back in afterward.

Note Docker Desktop's licensing on macOS/Windows — see
[Why Podman and not Docker](#why-podman-and-not-docker). For a class it's free;
it's your employer that may need a subscription.

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

Using Docker? Every command in this guide translates directly:

| Podman | Docker |
|---|---|
| `podman-compose up -d` | `docker compose up -d` |
| `podman-compose down` | `docker compose down` |
| `podman-compose down -v` | `docker compose down -v` |
| `podman ps` | `docker ps` |
| `podman logs -f mysql-lan` | `docker logs -f mysql-lan` |
| `podman exec -it mysql-lan mysql -uroot -p123456` | `docker exec -it mysql-lan mysql -uroot -p123456` |

Container names, ports and data are identical either way.

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
- `week2_day2_afternoon/` and `week2_day3_morning/` — the worksheets for
  each session, described in [Doing the exercises](#doing-the-exercises).
  Open one, read a task comment, then run your answer as a `%%sql` cell in
  `SQL_Console.ipynb` (or paste it into a new cell right in the worksheet's
  own scratch space). Only `exercises/` is mounted, so you won't find the
  solutions here.

Everything in this lab can be done in SQL — you shouldn't need any other
Python here. This JupyterLab instance is **shared** across everyone on the
classroom LAN (same as the database), not one-per-student: edits to
the worksheets or `SQL_Console.ipynb` are visible to everyone connected. If
you'd rather keep your own private copy of your work, edit the worksheet
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

Go to your class's folder and start from its `README.md`:

- **[`week2_day2_afternoon/`](week2_day2_afternoon/README.md)** — the full
  taught syllabus: building tables and constraints, aggregate functions,
  joins, subqueries, `CASE WHEN`/pivots (worksheets 01–10)
- **[`week2_day3_morning/`](week2_day3_morning/README.md)** — past the
  lectures: views and materialization, cross-database queries, ER modelling,
  key design, subquery reports, window functions, and a combined analytical
  capstone (worksheets 01–07)
- **[`week2_day4_afternoon/`](week2_day4_afternoon/README.md)** — **Python,
  not SQL**: lists, tuples, sets, dictionaries, the built-in functions,
  strings/conditionals/loops, a combined capstone, and a data-engineering
  sheet that puts the structures to work on a dirty feed (worksheets 01–08).
  Needs no database and no `%%sql` —
  pure standard library, so it runs in any Python 3 as well as in the shared
  console.
- **[`week2_day5_morning/`](week2_day5_morning/README.md)** — **Python too**,
  and **two lectures in one folder**. Worksheets 01–08 are control flow and
  iteration: conditionals, `for`, comprehensions, `while`,
  `break`/`continue`/`pass`, a clickstream capstone, the control-flow patterns
  a data pipeline is made of, and a sheet that reads the superstore tables
  straight off disk as tab-separated text. Worksheets 09–14 are functions and
  code reusability: `def` and `return`, arguments and `*args`/`**kwargs`,
  scope and side effects, `lambda`/`map`/`filter`, recursion, and a capstone
  that rebuilds the pipeline as a reusable toolkit. Not one `import` in the
  whole set — `open()` is a builtin.
- **[`week3_day1_afternoon/`](week3_day1_afternoon/README.md)** — **Pandas**,
  and **three lectures in one folder**. Worksheets 01–04 are the introduction:
  Series, DataFrames, the `Index` object, and `loc` vs `iloc`. Worksheets 05–10
  are the core operations: reindexing, dropping, filtering, label alignment,
  `apply`/`map`, and sorting and ranking. Worksheets 11–14 are reading and
  writing: CSV and TSV parameters, chunked reads, JSON including nested
  objects, and Excel workbooks with a full load-check-process-save capstone.
  Needs no database, but it **does** need pandas — the upstream base image
  ships without it, which is why `jupyter-sql/Dockerfile` installs it
  explicitly. If an import fails, see *Checking the console image* below.
- **[`week3_day2_afternoon/`](week3_day2_afternoon/README.md)** — **Pandas continued**, two more
  lectures. Worksheets 01–05 are reshaping and pivoting: long vs wide,
  MultiIndex, `unstack`, `stack`, and `pivot` versus `pivot_table`. Worksheets
  06–10 are data transformation: duplicates, `replace`/`map`/`.loc`, binning,
  outliers, and one-hot encoding with a capstone that runs the whole day end to
  end. Four extra-practice sheets alongside. Same pandas requirement as week3_day1_afternoon.
- **[`week3_day3_afternoon/`](week3_day3_afternoon/README.md)** — **Snowflake**, two
  labs. Worksheets 01–02 run in your own Snowflake account: Snowsight, the
  `TPCH_SF1` sample data, named internal stages, and a transformational
  `COPY INTO`. They carry **no code cells**, because nothing here can execute
  them. Worksheets 03–05 run in the console, on the same two CSVs the ingestion
  lab loads, and take apart what a successful load still leaves wrong — a
  filename that contradicts its own dates, quotes that make `WHERE PRIORITY =
  'High'` return zero rows, and a join that invents 606,705.92 of revenue.
- **[`week3_day4_morning/`](week3_day4_morning/README.md)** — **Dimensional
  modeling and ELT design**, the L03 case study built rather than described.
  Worksheets 01–04 are the concepts with numbers on them: OLTP vs OLAP, grain as
  a testable claim, the three measure types, and star vs snowflake vs galaxy.
  Worksheets 05–10 are the lecture's seven ELT steps — mapping, staging, business
  rules, derived measures, dimension load, fact load, quality checks — ending
  with a fact table that reconciles to `0.00` and answers five of six business
  questions. Worksheet 11 is the group design activity, with **no code cells**.
  Its data is generated by `scripts/generate_enrollment_data.py`.

Each folder holds `exercises/` and its matching `solutions/`, numbered in
teaching order. The week2_day4_afternoon and week2_day5_morning sessions also carry a
`exercises/more-practice/` subfolder holding a second sheet per topic, with
matching numbering — use those when something didn't land, or after class.

The SQL worksheets have their task prompts as SQL comments with blank space
underneath for you to write your own query; the Python ones are notebooks with
a `## Your Code Here` cell under each question. Open them either from your
local git clone,
or straight from the Jupyter SQL console (Option A in Step 5) — same files
either way. Suggested workflow per worksheet:

1. Read the comment describing the task.
2. Write your query underneath it and run it against the live database
   (any client from Step 5 works).
3. Sanity-check your result against the row counts/values described in
   the comment, or against the matching file in `solutions/`.
4. If you're stuck for more than a few minutes, peek at just the next
   line of the matching solution file rather than the whole thing — it's
   more useful to unstick yourself than to solve it end-to-end.

Two worksheets need a word of warning, both covered in their class README:

- **`week2_day3_morning/exercises/03_er_modelling_challenges.ipynb`** is a
  Jupyter notebook, not a `.sql` file, because its ER diagrams are written in
  [Mermaid](https://mermaid.js.org/) and JupyterLab renders them as actual
  pictures. You read the problem, draw your answer by editing a Markdown
  cell, run it to see the diagram, and write the DDL in a `%%sql` cell
  underneath — all in one place.

## Checks worth running before a class

```bash
python3 scripts/check_console.py     # is the console serving what is on disk?
python3 scripts/check_exercises.py   # does every exercise have a solution?
python3 scripts/collect_solutions.py --check   # is the published mirror in sync?
python3 scripts/fetch_lab_data.py --verify     # is the offline lab data in place?
```

All three exit non-zero on failure, so they work in a pre-commit hook or a
pre-class script. `check_exercises.py` verifies that every exercise has a
matching solution, that no exercise ships with answers or stored outputs, that
the notebook JSON is normalised, and that any `data/` read by a relative path
exists on both sides.

It deliberately does **not** check whether the numbers quoted in a solution are
right — that needs the notebooks executed in the lab image and the output
compared against the prose, which is how each class was built.

If a notebook has been opened in JupyterLab, its JSON key order drifts and the
diff fills with noise. `python3 scripts/normalise_notebooks.py` puts it back;
it touches key order and formatting only and refuses to write if cell contents
would change.

## Troubleshooting

**A class folder is EMPTY in the browser, but the files are there in git**
The bind mount is pointing at a directory that no longer exists. A bind mount
resolves to an **inode** when the container starts, not to a path, so anything
that deletes and recreates a mounted directory orphans it — and git does this
routinely:

```bash
git checkout some-branch-without-that-folder   # git removes the directory
git checkout master                            # git recreates it, new inode
```

The container keeps pointing at the old inode and serves an empty folder, with
no error anywhere. Restarting does **not** reliably fix it; recreate:

```bash
python3 scripts/check_console.py               # tells you which mounts are stale
podman-compose up -d --force-recreate sql-console
```

Run the check before class. It compares host and container inodes for every
mount and exits non-zero if any is orphaned.

**`short-name "mysql:latest" did not resolve to an alias`**
Rootless Podman ships no default registry list, so it refuses to guess which
registry a bare image name means. Use the fully qualified name —
`docker.io/library/mysql:latest`. The compose file in this repo already
does; you'll only hit this if you type your own `podman run` or `podman pull`
with a short name.

**Jupyter says `Permission denied` when saving a notebook in a class folder**
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

**`address already in use`, or Jupyter stuck in `Created`**
Almost always both runtimes running at once — see
[Running both at once](#running-both-at-once). Check with `podman ps -a` AND
`docker ps -a`; stop whichever you're not using. The giveaway is a healthy
database with a console that never starts.

**`port is already allocated` / `address already in use` for port 3306**
Something else on your machine (a previous MySQL install, a leftover
container from the other runtime) is already using port 3306.
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

`db-init/01_superstore_products.ipynb` through `04_superstore_returns.ipynb`
are real order data (not synthetic) — see the note under
[What's in here](#whats-in-here). To reload them from scratch, re-run the
files in order against the running container: `podman exec -i mysql-lan
mysql -uroot -p123456 < db-init/00_superstore_schema.ipynb`, then the
`01`–`04` files the same way.

`week2_day2_afternoon/exercises/data/*.csv` (used only by worksheet 01,
against a separate `superstore_practice` database) is synthetic, generated by
## Checking the console image

`quay.io/jupyter/base-notebook` ships **without pandas** — that is the
`scipy-notebook` image. This repo's `jupyter-sql/Dockerfile` installs it, along
with the twelve other packages the worksheets need.

To ask the running console what it actually has:

```bash
podman cp jupyter-sql/verify_image.py sql-console-lan:/tmp/v.py
podman exec sql-console-lan python3 /tmp/v.py
```

It prints a version per package and exits non-zero on anything missing or at
the wrong version. The same script runs as a **build step**, so a broken image
fails the build rather than a worksheet in front of a class.

To rebuild:

```bash
podman-compose up -d --build --force-recreate sql-console
```

### Everything is pinned, and that is deliberate

The base image is pinned by **digest**, not `:latest`, and every pip package to
an exact version.

This repo's guarantee is that every number quoted in a solution is output
somebody observed. That guarantee lives or dies on the interpreter that
produced it: an unpinned `pip install pandas` means a rebuild months from now
can bring a pandas that changes a dtype, a repr or an error message, and
silently invalidate hundreds of verified figures with nothing failing. 282
notebooks also declare `"version": "3.13.15"` in their kernel metadata, which
`scripts/normalise_notebooks.py` enforces — so the Python version is
load-bearing too.

To bump anything: change the pin, rebuild, run `verify_image.py`, and re-verify
the classes whose solutions quote output. Each class README documents how its
figures were checked.

`scripts/generate_superstore_data.py` (fixed random seed, so output is
reproducible). That script writes **only those four CSVs** — it deliberately
does not touch `db-init/`, which holds the real dataset. Edit constants at the
top of the script (row counts, date range, categories) and re-run:
```bash
python3 scripts/generate_superstore_data.py
```
The CSVs are kept referentially consistent — every order references a
customer and product that are actually exported — so worksheet 01 can declare
the foreign keys it teaches. If you change the subset sizes, keep that
property or the loads will silently drop rows.
