# SQL Bootcamp Labs — Data Engineering

Hands-on SQL labs for the Data Engineering bootcamp: aggregate functions,
`GROUP BY`/`HAVING`, joins & unions, `CASE WHEN` / pivot tables, and
subqueries. Everything runs against a local MySQL instance in Docker — no
manual database setup required.

## What's in here

Two databases, auto-created and auto-seeded the first time the container
starts:

| Database     | Tables                                   | Rows                                              | Used for |
|--------------|-------------------------------------------|----------------------------------------------------|----------|
| `superstore` | `customers`, `products`, `orders`, `returns` | 250 customers, 60 products, 3,000 orders (2009–2012), 240 returns | Aggregate functions, `GROUP BY`/`HAVING`, joins, `CASE WHEN`/pivots, subqueries |
| `company`    | `employee`, `hire`, `hobby`, `review`     | 7 employees, 6 hire records, 4 hobbies, 6 reviews (intentionally sparse) | Joins, subqueries |

```
sql-bootcamp-labs/
├── README.md
├── docker-compose.yml        # recommended way to run the lab
├── db-init/                  # schema + seed SQL, auto-run on first container start
├── exercises/                # student worksheets (no answers) + sample CSVs
├── solutions/                # reference solutions
└── scripts/generate_superstore_data.py   # regenerates the superstore seed data
```

The `superstore` schema and its entity relationships (`customers` →
`orders` ← `products`, `orders` → `returns`) follow the ERD from the
"Introduction to Entity Relationships" lecture. The `company` schema's row
counts are intentionally small and intentionally sparse (not every
employee has a hire record, hobby, or review) so `LEFT`/`RIGHT`/`FULL`
joins produce visibly different, meaningful results.

## Prerequisites

You need Docker installed and running. Pick your OS:

**macOS**
```bash
brew install --cask docker
open -a Docker   # first launch finishes setup; wait for the whale icon in the menu bar
```
Or download Docker Desktop from https://www.docker.com/products/docker-desktop/

**Windows**
Download and install Docker Desktop from
https://www.docker.com/products/docker-desktop/ (requires WSL2, which the
installer sets up for you). Launch Docker Desktop and wait until it says
"Docker Desktop is running".

**Linux (Debian/Ubuntu)**
```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER   # log out/in afterward so `docker` works without sudo
```

**Linux (Arch/CachyOS)**
```bash
sudo pacman -S docker docker-compose
sudo systemctl enable --now docker
sudo usermod -aG docker $USER   # log out/in afterward
```

Verify it worked:
```bash
docker --version
docker run hello-world
```

You'll also want a MySQL client to run queries. Any of these work:
- `mysql` CLI (`brew install mysql-client` / `apt install mysql-client` / `pacman -S mysql-clients`)
- [DBeaver](https://dbeaver.io/) / [TablePlus](https://tableplus.com/) / MySQL Workbench (GUI)
- `docker exec` straight into the container (no local client needed — see below)

## Spin up the lab

### Option A — docker compose (recommended)

From the repo root:
```bash
docker compose up -d
```
This builds a container named `some-mysql`, publishes MySQL on
`localhost:3306`, and runs every `.sql` file in `db-init/` in order the
first time it starts — creating and seeding both `superstore` and
`company` automatically. Data persists in a Docker volume across restarts.

Check it's healthy:
```bash
docker compose ps
docker compose logs -f mysql   # watch the seed scripts run on first boot
```

### Option B — plain `docker run`

Same result, no compose file, using the image/flags style from class:
```bash
docker run --name some-mysql \
  -e MYSQL_ROOT_PASSWORD=my-secret-pw \
  -p 3306:3306 \
  -v "$(pwd)/db-init:/docker-entrypoint-initdb.d" \
  -d mysql:8.0
```
Replace `mysql:8.0` with whatever tag your class is standardizing on
(`mysql:8.4`, `mysql:5.7`, etc.) — the schema and lab SQL are compatible
with any current MySQL 5.7+/8.x tag.

### Connect

```bash
mysql -h 127.0.0.1 -P 3306 -u root -p     # password: my-secret-pw
```
or, without installing a client locally:
```bash
docker exec -it some-mysql mysql -uroot -pmy-secret-pw
```

### Verify the seed worked

```sql
USE superstore;
SELECT COUNT(*) FROM customers;  -- 250
SELECT COUNT(*) FROM products;   -- 60
SELECT COUNT(*) FROM orders;     -- 3000
SELECT COUNT(*) FROM returns;    -- 240

USE company;
SELECT COUNT(*) FROM employee;   -- 7
SELECT COUNT(*) FROM hire;       -- 6
SELECT COUNT(*) FROM hobby;      -- 4
SELECT COUNT(*) FROM review;     -- 6
```

## Doing the exercises

Work through `exercises/` in order — each file has the task prompts as
comments with a blank space underneath for your query. Check your answer
against the matching file in `solutions/` once you've given it a real
attempt.

1. `Part1_Exercise_Build_Database_and_Tables.sql` — DDL practice: build a
   scratch database from CSVs by hand (the main `superstore`/`company`
   databases are already built for you by `db-init/`, so this is purely
   for practicing `CREATE TABLE`, primary/foreign keys, and `LOAD DATA
   LOCAL INFILE`). Run this one from a mysql client on your **host**
   machine, not inside the container, since `LOCAL INFILE` reads files
   from the client's filesystem.
2. `Part2_Exercise_Joins.sql` — `INNER`/`LEFT`/`RIGHT`/`FULL` joins on `company`.
3. `Part3_Exercise_CaseWhen_Pivot.sql` — `CASE WHEN` and pivot tables on `superstore`.
4. `Part3_Exercise_Subqueries.sql` — subqueries on `company` and `superstore`.

## Resetting the lab

```bash
docker compose down -v   # drops the container AND its data volume
docker compose up -d     # re-creates and re-seeds from scratch
```

## Regenerating the seed data

`db-init/01_superstore_products.sql` through `04_superstore_returns.sql`
and `exercises/data/*.csv` are generated by
`scripts/generate_superstore_data.py` (fixed random seed, so output is
reproducible). Edit constants at the top of the script (row counts, date
range, categories) and re-run:
```bash
python3 scripts/generate_superstore_data.py
```
Then re-run `docker compose down -v && docker compose up -d` to reseed.
