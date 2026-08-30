#!/usr/bin/env python3
"""Extract the superstore database into a bronze landing zone.

week3_day1_afternoon worksheets 16 and 17 teach DataFrame joins and the
bronze/silver/gold medallion pattern. Both need what a real landing zone looks
like: several related files, delivered separately, at their own grains.

This writes that landing zone from the REAL superstore data already in
db-init/ -- the same extract the rest of the class uses -- by querying the
running mysql-lan container.

    python3 scripts/generate_medallion_data.py
    python3 scripts/generate_medallion_data.py --verify   # check, write nothing

Output, into week3_day1_afternoon/exercises/data/bronze/ and its solutions
mirror:

    orders_2009.csv .. orders_2012.csv   the fact feed, partitioned by year
    customers.csv                        the CRM export
    products.csv                         the catalogue
    returns.csv                          a second feed, keyed differently

WHAT IS REAL, AND WHAT IS PLANTED
---------------------------------
Almost everything is real, including every property the worksheets teach from:

  orders is at LINE grain -- 8,060 rows for 5,361 distinct OrderIDs. This is
      why joining returns (one row per OrderID) to orders multiplies rows, and
      it is the single most important lesson in worksheet 16.
  returns is keyed by OrderID, so its 558 rows match 837 order LINES.
  20 customers have never ordered -- real, and the anti-join exercise.
  referential integrity is otherwise perfect: no orphan or null join keys.

ONE thing is planted, and only one:

  ORDERS_2012 IS DELIVERED TWICE. orders_2012.csv contains the whole year, and
      the last 40 line rows of 2011 are appended to it as well -- a late
      re-delivery overlapping the previous partition. Landing zones do this
      constantly (a re-run, a backfill, an at-least-once delivery), and it is
      what makes "bronze is append-only, dedup on the way to silver" a real
      instruction rather than a slogan. Worksheet 17 finds it.

Nothing else is injected. Where a worksheet quotes a number, it came from this
data.
"""

import argparse
import csv
import io
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(REPO, "week3_day1_afternoon", "exercises", "data", "bronze")
MIRROR = os.path.join(REPO, "week3_day1_afternoon", "solutions", "data", "bronze")

CONTAINER = "mysql-lan"
DB = "superstore"
YEARS = [2009, 2010, 2011, 2012]

# The planted re-delivery: how many of 2011's last line rows are appended to
# the 2012 partition. See the module docstring.
REDELIVERED_ROWS = 40

ORDER_COLS = ("LineID, OrderID, ProductID, CustomerID, OrderDate, "
              "OrderPriority, OrderQuantity, Sales, Discount, ShipMode, "
              "Profit, UnitPrice, ShippingCost")


def query(sql):
    """Run SQL in the mysql container and return (header, rows)."""
    r = subprocess.run(
        ["podman", "exec", CONTAINER, "mysql", "-uroot", "-p123456",
         "--batch", "--raw", "-e", sql],
        capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit("mysql query failed:\n%s" % r.stderr.strip()[:400])
    lines = r.stdout.rstrip("\n").split("\n")
    reader = list(csv.reader(io.StringIO("\n".join(lines)), delimiter="\t"))
    return reader[0], reader[1:]


def collect():
    """Build every output file as (name, header, rows), in write order."""
    files = []

    for year in YEARS:
        header, rows = query(
            "SELECT %s FROM %s.orders WHERE YEAR(OrderDate)=%d "
            "ORDER BY OrderDate, LineID;" % (ORDER_COLS, DB, year))
        files.append(("orders_%d.csv" % year, header, rows))

    # The planted re-delivery: 2011's last N line rows, appended to 2012.
    by_name = {n: (h, r) for n, h, r in files}
    tail = by_name["orders_2011.csv"][1][-REDELIVERED_ROWS:]
    h2012, r2012 = by_name["orders_2012.csv"]
    files = [(n, h, (r2012 + tail) if n == "orders_2012.csv" else r)
             for n, h, r in files]

    for name, sql in [
        ("customers.csv",
         "SELECT CustomerID, CustomerName, Province, Region, CustomerSegment "
         "FROM %s.customers ORDER BY CustomerID;" % DB),
        ("products.csv",
         "SELECT ProductID, ProductName, ProductCategory, ProductSubCategory, "
         "ProductContainer, ProductBaseMargin FROM %s.products "
         "ORDER BY ProductID;" % DB),
        ("returns.csv",
         "SELECT OrderID, Status FROM %s.returns ORDER BY OrderID;" % DB),
    ]:
        header, rows = query(sql)
        files.append((name, header, rows))

    return files


def render(header, rows):
    buf = io.StringIO()
    w = csv.writer(buf, lineterminator="\n")
    w.writerow(header)
    w.writerows(rows)
    return buf.getvalue()


def main():
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--verify", action="store_true",
                    help="check the files on disk match a fresh extract")
    args = ap.parse_args()

    files = collect()

    if args.verify:
        ok = True
        for name, header, rows in files:
            path = os.path.join(OUT, name)
            want = render(header, rows)
            if not os.path.exists(path):
                print("  MISSING  %s" % name); ok = False
            elif open(path, newline="").read() != want:
                print("  CHANGED  %s does not match a fresh extract" % name)
                ok = False
            else:
                print("  ok       %-18s %5d rows" % (name, len(rows)))
        mirror_ok = all(os.path.exists(os.path.join(MIRROR, n))
                        for n, _, _ in files)
        print()
        if ok and mirror_ok:
            print("all %d bronze files match, and the solutions mirror is present"
                  % len(files))
            return
        if not mirror_ok:
            print("the solutions/ mirror is incomplete")
        sys.exit(1)

    for d in (OUT, MIRROR):
        os.makedirs(d, exist_ok=True)

    total = 0
    for name, header, rows in files:
        text = render(header, rows)
        for d in (OUT, MIRROR):
            with open(os.path.join(d, name), "w", newline="") as fh:
                fh.write(text)
        total += len(rows)
        print("  %-18s %5d rows" % (name, len(rows)))
    print("\n%d files, %d rows, written to bronze/ and its solutions mirror"
          % (len(files), total))
    print("note: orders_2012.csv carries %d re-delivered rows from 2011 "
          "(see the docstring)" % REDELIVERED_ROWS)


if __name__ == "__main__":
    main()
