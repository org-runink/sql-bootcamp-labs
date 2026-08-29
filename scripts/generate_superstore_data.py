#!/usr/bin/env python3
"""
Generates the small deterministic CSV sample used by worksheet 01.

This does NOT generate the main `superstore` database — that is the real
dataset in db-init/, which this script must never overwrite.

Writes SQL INSERT files straight into db-init/, in FK-safe load order
(products, customers, orders, returns), plus sample CSVs into
exercises/data/. Re-run any time to regenerate with the same fixed seed
-> identical output.
"""

import csv
import random
from datetime import date, timedelta
from pathlib import Path

random.seed(42)

OUT_DIR = Path(__file__).resolve().parent.parent / "db-init"
CSV_DIR = Path(__file__).resolve().parent.parent / "week2_day2_afternoon" / "exercises" / "data"

N_CUSTOMERS = 250
N_PRODUCTS = 60
N_ORDERS = 3000
RETURN_RATE = 0.08

PROVINCE_REGION = [
    ("Ontario", "Ontario"),
    ("Quebec", "Quebec"),
    ("British Columbia", "West"),
    ("Alberta", "West"),
    ("Manitoba", "Prairie"),
    ("Saskatchewan", "Prairie"),
    ("Nova Scotia", "Atlantic"),
    ("New Brunswick", "Atlantic"),
    ("Newfoundland and Labrador", "Atlantic"),
    ("Prince Edward Island", "Atlantic"),
    ("Yukon", "Yukon"),
    ("Northwest Territories", "Northwest Territories"),
]
SEGMENTS = ["Consumer", "Corporate", "Home Office", "Small Business"]

FIRST_NAMES = [
    "Tamara", "Bill", "Christy", "Barry", "Aleksandra", "Sally", "Tom",
    "Juliana", "Trudy", "Jeremy", "Cindy", "Roland", "Brendan", "Nadia",
    "Marcus", "Priya", "Owen", "Fatima", "Liam", "Sophie", "Noah", "Chloe",
    "Ethan", "Mia", "Lucas", "Ava", "Mason", "Isabella", "Logan", "Zoe",
    "Jack", "Layla", "Ryan", "Grace", "Nathan", "Hannah", "Caleb", "Ella",
    "Dylan", "Lily",
]
LAST_NAMES = [
    "Dahlen", "Donatelli", "Brittain", "Blumstein", "Gannaway", "Matthias",
    "Prescott", "Krohn", "Bell", "Lonsdale", "Schnelling", "Murray",
    "Murry", "Kowalski", "Singh", "Nguyen", "Tremblay", "Roy", "Cote",
    "Gagnon", "Belanger", "Levesque", "Fortin", "Fournier", "Morin",
    "Bergeron", "Girard", "Beaulieu", "Pelletier", "Boucher",
]

CATEGORIES = {
    "Office Supplies": {
        "subcats": ["Paper", "Binders", "Appliances", "Storage", "Envelopes", "Labels", "Fasteners", "Art"],
        "containers": ["Small Box", "Wrap Bag", "Small Pack"],
    },
    "Technology": {
        "subcats": ["Phones", "Computers", "Accessories", "Copiers"],
        "containers": ["Medium Box", "Large Box", "Jumbo Box"],
    },
    "Furniture": {
        "subcats": ["Chairs", "Tables", "Bookcases", "Furnishings"],
        "containers": ["Jumbo Box", "Jumbo Drum", "Large Box"],
    },
}
PRODUCT_ADJ = ["Deluxe", "Standard", "Premium", "Economy", "Executive", "Compact", "Heavy-Duty", "Wireless"]
PRODUCT_NOUN = {
    "Paper": ["Copy Paper", "Note Pads", "Scratch Pads"],
    "Binders": ["3-Ring Binder", "Report Cover", "Clipboard"],
    "Appliances": ["Surge Protector", "Paper Shredder", "Desk Fan"],
    "Storage": ["File Cabinet", "Storage Box", "Literature Rack"],
    "Envelopes": ["Mailing Envelopes", "Interoffice Envelopes"],
    "Labels": ["Address Labels", "File Labels"],
    "Fasteners": ["Push Pins", "Paper Clips", "Staples"],
    "Art": ["Highlighters", "Markers", "Pencils"],
    "Phones": ["Cordless Phone", "Smartphone", "Answering Machine"],
    "Computers": ["Laptop", "Desktop PC", "Monitor"],
    "Accessories": ["USB Drive", "Keyboard", "Mouse"],
    "Copiers": ["Desktop Copier", "Laser Printer"],
    "Chairs": ["Task Chair", "Executive Chair", "Stacking Chair"],
    "Tables": ["Conference Table", "Computer Desk", "Side Table"],
    "Bookcases": ["Bookcase", "Wall Shelf"],
    "Furnishings": ["Desk Lamp", "Wall Clock", "Bulletin Board"],
}

ORDER_PRIORITIES = ["Low", "Medium", "High", "Critical", "Not Specified"]
SHIP_MODES = ["Regular Air", "Express Air", "Delivery Truck"]


def esc(s):
    return s.replace("'", "''")


def sql_insert(table, columns, rows, batch_size=500):
    lines = [f"USE superstore;\n"]
    for i in range(0, len(rows), batch_size):
        batch = rows[i:i + batch_size]
        lines.append(f"INSERT INTO {table} ({', '.join(columns)}) VALUES")
        value_lines = []
        for row in batch:
            formatted = []
            for v in row:
                if v is None:
                    formatted.append("NULL")
                elif isinstance(v, str):
                    formatted.append(f"'{esc(v)}'")
                elif isinstance(v, date):
                    formatted.append(f"'{v.isoformat()}'")
                else:
                    formatted.append(str(v))
            value_lines.append(f"({', '.join(formatted)})")
        lines.append(",\n".join(value_lines) + ";\n")
    return "\n".join(lines)


def gen_customers():
    rows = []
    used_names = set()
    for cid in range(1, N_CUSTOMERS + 1):
        while True:
            name = f"{random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}"
            key = (name, cid)
            if key not in used_names:
                used_names.add(key)
                break
        province, region = random.choice(PROVINCE_REGION)
        segment = random.choice(SEGMENTS)
        rows.append((cid, name, province, region, segment))
    return rows


def gen_products():
    rows = []
    pid = 10000
    for _ in range(N_PRODUCTS):
        category = random.choice(list(CATEGORIES.keys()))
        info = CATEGORIES[category]
        subcat = random.choice(info["subcats"])
        container = random.choice(info["containers"])
        noun = random.choice(PRODUCT_NOUN[subcat])
        adj = random.choice(PRODUCT_ADJ)
        name = f"{adj} {noun}"
        margin = round(random.uniform(0.30, 0.65), 2)
        rows.append((pid, name, category, subcat, container, margin))
        pid += 1
    return rows


def daterange_random(start, end):
    delta = (end - start).days
    return start + timedelta(days=random.randint(0, delta))


def gen_orders(customer_ids, products):
    rows = []
    start, end = date(2009, 1, 1), date(2012, 12, 31)
    for oid in range(1, N_ORDERS + 1):
        product = random.choice(products)
        product_id = product[0]
        base_margin = float(product[5])
        customer_id = random.choice(customer_ids)
        order_date = daterange_random(start, end)
        priority = random.choice(ORDER_PRIORITIES)
        ship_mode = random.choice(SHIP_MODES)
        quantity = random.randint(1, 50)
        unit_price = round(random.uniform(2, 400), 2)
        sales = round(unit_price * quantity * random.uniform(0.85, 1.15), 5)
        discount = round(random.uniform(0.0, 0.25), 2)
        shipping_cost = round(random.uniform(1, 15), 2)
        if ship_mode == "Express Air":
            shipping_cost = round(shipping_cost * random.uniform(2.5, 4.0), 2)

        profit = round(sales * base_margin - sales * discount - shipping_cost, 2)
        # Bias Critical-priority Express Air orders to skew loss-making,
        # so the "which combo loses money" exercise has a real answer.
        if priority == "Critical" and ship_mode == "Express Air" and random.random() < 0.6:
            profit = round(-abs(profit) - random.uniform(5, 50), 2)

        rows.append((
            oid, product_id, customer_id, order_date, priority, quantity,
            sales, discount, ship_mode, profit, unit_price, shipping_cost,
        ))
    return rows


def gen_returns(order_ids):
    n_returns = int(len(order_ids) * RETURN_RATE)
    returned = random.sample(order_ids, n_returns)
    return [(oid, "Returned") for oid in sorted(returned)]


def write_csv(path, header, rows):
    with path.open("w", newline="") as f:
        writer = csv.writer(f, delimiter="\t", lineterminator="\n")
        writer.writerow(header)
        for row in rows:
            writer.writerow(v.isoformat() if isinstance(v, date) else v for v in row)


def main():
    customers = gen_customers()
    products = gen_products()
    orders = gen_orders([c[0] for c in customers], products)
    returns = gen_returns([o[0] for o in orders])

    # Tab-delimited CSVs (small subsets), used by the Part 1 "Build
    # Database and Tables" exercise to practice CREATE TABLE + LOAD DATA
    # LOCAL INFILE by hand, mirroring the original lecture workflow.
    CSV_DIR.mkdir(parents=True, exist_ok=True)
    # The subset must be REFERENTIALLY CONSISTENT or the Part 1 exercise
    # cannot declare the foreign keys it teaches: with FKs on, MySQL
    # silently drops every order row whose customer was not exported.
    # So take the orders first, then export exactly the customers they
    # reference (products are exported in full).
    sample_orders = orders[:400]
    referenced = {o[2] for o in sample_orders}
    sample_customers = [c for c in customers if c[0] in referenced]
    sample_order_ids = {o[0] for o in sample_orders}

    write_csv(CSV_DIR / "customers.csv",
              ["CustomerID", "CustomerName", "Province", "Region", "CustomerSegment"],
              sample_customers)
    write_csv(CSV_DIR / "products.csv",
              ["ProductID", "ProductName", "ProductCategory", "ProductSubCategory", "ProductContainer", "ProductBaseMargin"],
              products)
    write_csv(CSV_DIR / "orders.csv",
              ["OrderID", "ProductID", "CustomerID", "OrderDate", "OrderPriority", "OrderQuantity",
               "Sales", "Discount", "ShipMode", "Profit", "UnitPrice", "ShippingCost"],
              sample_orders)
    write_csv(CSV_DIR / "returns.csv",
              ["OrderID", "Status"],
              [r for r in returns if r[0] in sample_order_ids])

    # NOTE: this script deliberately does NOT write db-init/.
    #
    # db-init/01..04_superstore_*.sql hold the REAL Superstore dataset
    # (1,832 customers / 8,060 order lines) loaded from the source zip. This
    # generator produces SYNTHETIC data (250 customers / 3,000 orders), so
    # writing db-init/ here would silently replace the real data with fake
    # data and invalidate every expected result quoted in the worksheets.
    # It only regenerates the small tab-separated CSVs used by worksheet 01.

    print(f"customers={len(customers)} products={len(products)} orders={len(orders)} returns={len(returns)}")


if __name__ == "__main__":
    main()
