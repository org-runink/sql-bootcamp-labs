#!/usr/bin/env python3
"""Generate the operational source database for week3_day4_morning.

The L03 deck ("Data Modeling and ETL Design") works one case study end to
end: an education provider's **enrollment** process, taken from a normalized
operational schema to a star schema and then to a seven-step ELT design.
Slide 24 shows the source ER diagram and slide 29 shows the target star. The
worksheets build the second from the first -- so they need the first to exist.

This writes it: eleven CSVs matching slide 24's tables and column names
exactly, into week3_day4_morning/exercises/data/ and its solutions/ mirror.

    python3 scripts/generate_enrollment_data.py
    python3 scripts/generate_enrollment_data.py --verify   # check, write nothing

Fixed seed -> byte-identical output every run. About 1.2 MB.

WHAT IS DELIBERATELY WRONG WITH IT
----------------------------------
An operational database that is already clean teaches nothing about Step 3
(business rules) or Step 7 (data quality). Every defect below is planted, and
every one of them is a defect the deck names:

  transaction.full_paid holds Y / Yes / 1 / N / No / 0 / empty
      -> slide 36's "Standardize paid-in-full flag"
  discount_type.discount_amount is NULL for one promotion
      -> slide 36's "Default missing discount amount"
  category.category_name is NULL for one category
      -> slide 36's "Standardize missing program category"
  enrollment.status includes 'cancelled'
      -> slide 36's "Apply reporting rule"
  40 transaction rows are exact duplicates of an earlier row
      -> slide 39's "Was the same enrollment loaded more than once?"
  7 enrollments reference a stu_id that is not in students
      -> slide 39's "Does every fact row match valid dimension records?"
  students named 'TEST ...' with their own enrollments
      -> slide 35's "Filtering out test ... records"
  some enrollments have NO transaction rows at all
      -> the difference between an INNER and a LEFT join, which decides
         whether the fact table has 2,400 rows or fewer
  transaction is at PAYMENT grain, not enrollment grain
      -> slide 28's footnote, and the reason Step 4 exists at all

None of it is random noise. Each defect has a fixed size, so the worksheets
can quote an exact count and the solution can be checked against it.
"""

import argparse
import csv
import os
import random
import sys
from datetime import date, timedelta

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLASS = os.path.join(REPO, "week3_day4_morning")
PRIMARY = os.path.join(CLASS, "exercises", "data")
MIRROR = os.path.join(CLASS, "solutions", "data")

SEED = 20260829

N_STUDENTS = 600
N_ENROLLMENTS = 2400

# --- the fixed size of every planted defect -------------------------------
N_TEST_STUDENTS = 6          # students whose name starts with TEST
N_ORPHAN_ENROLL = 7          # enrollments pointing at a stu_id that was purged
N_DUP_TRANSACTIONS = 40      # exact duplicate transaction rows
N_PRICE_CORRECTED = 3        # enrollments whose transactions disagree on full_price
PCT_CANCELLED = 0.05         # enrollment.status = 'cancelled'
PCT_NO_TRANSACTIONS = 0.06   # enrollments that never generated a transaction

CATEGORIES = [
    (1, "Data Engineering", "Pipelines, warehousing and platform work"),
    (2, "Data Science", "Statistics, modeling and machine learning"),
    (3, "Cloud Computing", "Infrastructure, containers and deployment"),
    (4, "Cybersecurity", "Defensive and offensive security practice"),
    # category_name is deliberately NULL -- slide 36 expects 'Unknown'
    (5, None, "Uncategorised, pending review"),
]

PROGRAMS = [
    (101, "Applied Data Engineering", 1),
    (102, "Analytics Engineering", 1),
    (103, "Machine Learning Foundations", 2),
    (104, "Applied Data Science", 2),
    (105, "Cloud Platform Engineering", 3),
    (106, "Site Reliability Engineering", 3),
    (107, "Security Operations", 4),
    (108, "Foundations Bootcamp", 5),      # the NULL-category program
]

COURSE_NAMES = [
    "SQL for Data Engineers", "Data Modeling and ETL Design",
    "Python for Data Engineering", "Streaming Fundamentals",
    "Analytics Engineering with dbt", "Dashboard Design",
    "Statistics for Analysts", "Machine Learning Foundations",
    "Deep Learning Foundations", "Feature Engineering",
    "Containers and Orchestration", "Infrastructure as Code",
    "Cloud Networking", "Observability and SRE Practice",
    "Incident Response", "Threat Detection",
    "Secure Coding", "Identity and Access Management",
    "Linux for Engineers", "Version Control in Practice",
    "Data Warehousing on Snowflake", "Distributed Systems Primer",
    "Career Foundations", "Capstone Project",
]

PLACES = [
    ("Toronto", "Ontario", "Canada"), ("Ottawa", "Ontario", "Canada"),
    ("Mississauga", "Ontario", "Canada"), ("Hamilton", "Ontario", "Canada"),
    ("Montreal", "Quebec", "Canada"), ("Quebec City", "Quebec", "Canada"),
    ("Vancouver", "British Columbia", "Canada"),
    ("Victoria", "British Columbia", "Canada"),
    ("Calgary", "Alberta", "Canada"), ("Edmonton", "Alberta", "Canada"),
    ("Winnipeg", "Manitoba", "Canada"), ("Regina", "Saskatchewan", "Canada"),
    ("Halifax", "Nova Scotia", "Canada"),
    ("Fredericton", "New Brunswick", "Canada"),
    ("New York", "New York", "United States"),
    ("Buffalo", "New York", "United States"),
    ("Boston", "Massachusetts", "United States"),
    ("Chicago", "Illinois", "United States"),
    ("Seattle", "Washington", "United States"),
    ("San Francisco", "California", "United States"),
    ("Los Angeles", "California", "United States"),
    ("Austin", "Texas", "United States"),
    ("Denver", "Colorado", "United States"),
    ("Atlanta", "Georgia", "United States"),
    ("London", "England", "United Kingdom"),
    ("Manchester", "England", "United Kingdom"),
    ("Dublin", "Leinster", "Ireland"),
    ("Berlin", "Berlin", "Germany"),
    ("Lisbon", "Lisboa", "Portugal"),
    ("Sao Paulo", "Sao Paulo", "Brazil"),
]

PAYMENT_TYPES = [
    (1, "Credit Card"), (2, "Debit"), (3, "Bank Transfer"),
    (4, "Installment Plan"), (5, "Employer Sponsored"),
]

DISCOUNT_TYPES = [
    # (discount_id, discount_type_id, name, amount)
    (1, 10, "Early Bird", 500.00),
    (2, 20, "Alumni Referral", 750.00),
    (3, 30, "Employer Partner", 1200.00),
    (4, 40, "Scholarship", 2000.00),
    (5, 50, "Spring Campaign", 300.00),
    # discount_amount deliberately NULL -- slide 36 expects 0
    (6, 60, "Legacy Promotion", None),
]

FIRST = [
    "Amara", "Bo", "Celine", "Dmitri", "Elena", "Farid", "Greta", "Hiro",
    "Imani", "Jonas", "Kaia", "Liam", "Mina", "Noor", "Oscar", "Priya",
    "Quinn", "Rafael", "Sofia", "Tomas", "Ursula", "Viktor", "Wren",
    "Xiomara", "Yusuf", "Zara", "Adaeze", "Bruno", "Chiara", "Devon",
    "Esther", "Felix", "Gabriela", "Hassan", "Ines", "Jasper", "Kenji",
    "Lucia", "Mateo", "Nadia",
]
LAST = [
    "Achebe", "Bergstrom", "Costa", "Dubois", "Eriksen", "Ferreira",
    "Gallagher", "Haddad", "Ibrahim", "Jansen", "Kowalski", "Lindqvist",
    "Moreau", "Nakamura", "Okonkwo", "Petrov", "Quintero", "Rossi",
    "Silva", "Tanaka", "Ueda", "Varga", "Whitfield", "Xu", "Yilmaz",
    "Zielinski", "Ahmadi", "Bianchi", "Choi", "Delgado",
]

TITLES = ["Mr", "Ms", "Mx", "Dr"]
EMP_TYPES = [(1, "Full Time"), (2, "Part Time"), (3, "Contract")]


def write_csv(path, header, rows):
    with open(path, "w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(header)
        w.writerows(rows)
    return len(rows)


def blank(v):
    """CSV-empty for NULL, so read_csv gives NaN rather than the text 'None'."""
    return "" if v is None else v


def build():
    rnd = random.Random(SEED)
    tables = {}

    # ---- category, employee, program, course ----------------------------
    tables["category"] = (
        ["category_id", "category_name", "category_desc", "director_id",
         "start_date", "active_flg"],
        [[cid, blank(name), desc, 900 + cid, "2021-01-04", 1]
         for cid, name, desc in CATEGORIES],
    )

    employees = []
    for i in range(1, 15):
        employees.append([
            900 + i,
            "%s %s" % (FIRST[(i * 7) % len(FIRST)], LAST[(i * 5) % len(LAST)]),
            rnd.choice([1, 1, 2, 3]),
            "active",
            rnd.randint(1, len(PLACES)),
            rnd.choice(["Program Manager", "Director", "Lead Instructor"]),
            901 if i > 1 else "",
            1,
        ])
    tables["employee_type"] = (["emp_type_id", "emp_type_des"],
                               [list(t) for t in EMP_TYPES])
    tables["employee"] = (
        ["emp_id", "emp_name", "emp_type_id", "status", "city_id", "title",
         "manager_id", "active_flg"],
        employees,
    )

    tables["program"] = (
        ["program_id", "program_name", "program_desc", "pm_id", "start_date",
         "active_flg", "category_id"],
        [[pid, name, "%s program" % name, 900 + ((pid % 13) + 1),
          "2022-0%d-01" % ((pid % 6) + 1),
          0 if pid == 106 else 1,            # one retired program
          cat]
         for pid, name, cat in PROGRAMS],
    )

    courses = []
    for i, name in enumerate(COURSE_NAMES):
        cid = 201 + i
        program_id = PROGRAMS[i % len(PROGRAMS)][0]
        courses.append([
            cid, name, "%s, applied" % name,
            "GOV-%04d" % (4000 + i),
            rnd.choice([0, 1]),
            rnd.choice([24, 30, 36, 42, 48]),      # hours
            program_id,
            0 if cid in (223,) else 1,             # one retired course
        ])
    tables["course"] = (
        ["course_id", "course_name", "course_desc", "gov_code", "full_time",
         "hours", "program_id", "active_flg"],
        courses,
    )
    course_ids = [c[0] for c in courses]

    # ---- cohort ---------------------------------------------------------
    cohorts = []
    d = date(2024, 1, 8)
    for i in range(16):
        start = d + timedelta(days=i * 42)
        cohorts.append([
            301 + i,
            "%d-%02d" % (start.year, ((start.month - 1) // 3) * 3 + 1),
            start.isoformat(),
            (start + timedelta(days=98)).isoformat(),
        ])
    tables["cohort"] = (["cohort_id", "cohort_name", "start_dt", "end_dt"],
                        cohorts)
    cohort_ids = [c[0] for c in cohorts]

    # ---- city, students -------------------------------------------------
    cities = []
    prov_ids, cntry_ids = {}, {}
    for i, (city, prov, cntry) in enumerate(PLACES):
        prov_ids.setdefault(prov, len(prov_ids) + 1)
        cntry_ids.setdefault(cntry, len(cntry_ids) + 1)
        cities.append([i + 1, city, prov_ids[prov], prov,
                       cntry_ids[cntry], cntry])
    tables["city"] = (["city_id", "city_name", "provn_id", "provn_name",
                       "cntry_id", "cntry_name"], cities)
    city_ids = [c[0] for c in cities]

    students, real_student_ids = [], []
    for i in range(N_STUDENTS):
        sid = 5001 + i
        real_student_ids.append(sid)
        name = "%s %s" % (rnd.choice(FIRST), rnd.choice(LAST))
        # A handful of students have no city on file.
        city = "" if i % 97 == 0 else rnd.choice(city_ids)
        birth = date(1975, 1, 1) + timedelta(days=rnd.randint(0, 11000))
        students.append([
            sid, name, rnd.choice([1, 1, 1, 2, 3]), rnd.choice(TITLES),
            birth.isoformat(),
            "%d %s St" % (rnd.randint(1, 999), rnd.choice(LAST)),
            "%s%d%s %d%s%d" % (rnd.choice("KLMNPV"), rnd.randint(0, 9),
                               rnd.choice("ABCEHJ"), rnd.randint(0, 9),
                               rnd.choice("XYZWRT"), rnd.randint(0, 9)),
            city,
            "555-%04d" % rnd.randint(1000, 9999),
            "student%d@example.edu" % sid,
            1,
        ])
    # Test accounts, indistinguishable from real ones except by name.
    for j in range(N_TEST_STUDENTS):
        sid = 5001 + N_STUDENTS + j
        real_student_ids.append(sid)
        students.append([
            sid, "TEST Student %d" % (j + 1), 1, "Mx", "1990-01-01",
            "1 Test St", "T0T 0T0", rnd.choice(city_ids), "555-0000",
            "qa+%d@example.edu" % j, 1,
        ])
    tables["students"] = (
        ["stu_id", "stu_name", "emp_type_id", "title", "birthday",
         "home_address", "postal_code", "city_id", "phone_num", "email",
         "active_flg"],
        students,
    )

    # ---- enrollment -----------------------------------------------------
    # Purged students: enrollments survive, the student rows do not.
    purged = [5001 + N_STUDENTS + N_TEST_STUDENTS + k
              for k in range(N_ORPHAN_ENROLL)]

    enrollments = []
    enrl_id = 700001
    for i in range(N_ENROLLMENTS):
        if i < N_ORPHAN_ENROLL:
            stu = purged[i]
        elif i < N_ORPHAN_ENROLL + 18:
            stu = 5001 + N_STUDENTS + (i % N_TEST_STUDENTS)   # test enrollments
        else:
            stu = rnd.choice(real_student_ids[:N_STUDENTS])
        cohort = rnd.choice(cohort_ids)
        cohort_start = date.fromisoformat(cohorts[cohort - 301][2])
        enrl_date = cohort_start - timedelta(days=rnd.randint(1, 45))
        status = "cancelled" if rnd.random() < PCT_CANCELLED else "active"
        enrollments.append([
            enrl_id, enrl_date.isoformat(), stu, rnd.choice(course_ids),
            cohort, status,
        ])
        enrl_id += 1
    tables["enrollment"] = (
        ["enrl_id", "enrl_date", "stu_id", "course_id", "cohort_id", "status"],
        enrollments,
    )

    tables["payment_type"] = (["pymt_type_id", "pymt_type_name"],
                              [list(t) for t in PAYMENT_TYPES])
    tables["discount_type"] = (
        ["discount_id", "discount_type_id", "discount_type_name",
         "discount_amount"],
        [[a, b, c, blank(d)] for a, b, c, d in DISCOUNT_TYPES],
    )

    # ---- transaction ----------------------------------------------------
    # PAYMENT grain, not enrollment grain: an enrollment pays in 1-4
    # installments. This is the whole reason slide 28 says payment and
    # discount transactions are "summarized at the enrollment level".
    discount_type_ids = [d[1] for d in DISCOUNT_TYPES]
    price_corrected = set(rnd.sample(range(N_ENROLLMENTS), N_PRICE_CORRECTED))

    transactions = []
    trans_id = 900001
    for i, e in enumerate(enrollments):
        if rnd.random() < PCT_NO_TRANSACTIONS:
            continue                       # enrolled, never paid anything
        full_price = float(rnd.choice([3500, 4200, 4800, 5400, 6000, 7200]))
        has_promo = rnd.random() < 0.55
        dtid = rnd.choice(discount_type_ids) if has_promo else None
        discount = 0.0
        for did, dt, _, amt in DISCOUNT_TYPES:
            if dt == dtid:
                discount = amt if amt is not None else 0.0
        net = full_price - discount

        n_pay = rnd.choice([1, 1, 2, 2, 3, 4])
        # Most enrollments settle up; some do not.
        target = net if rnd.random() < 0.62 else round(net * rnd.uniform(0.2, 0.9), 2)
        paid_so_far = 0.0
        enrl_date = date.fromisoformat(e[1])
        for k in range(n_pay):
            last = (k == n_pay - 1)
            amount = round(target - paid_so_far, 2) if last \
                else round(target / n_pay, 2)
            paid_so_far = round(paid_so_far + amount, 2)
            full_paid_raw = rnd.choice(["Y", "Yes", "1"]) if (
                last and paid_so_far >= net - 0.005
            ) else rnd.choice(["N", "No", "0", ""])
            price = full_price
            if i in price_corrected and k > 0:
                price = full_price + 200.0      # a mid-stream price correction
            transactions.append([
                trans_id, (enrl_date + timedelta(days=7 * k)).isoformat(),
                e[0], rnd.choice([p[0] for p in PAYMENT_TYPES]),
                "%.2f" % price, blank(dtid), "%.2f" % amount, full_paid_raw,
            ])
            trans_id += 1

    # A partial re-load: 40 rows appended again, byte-identical but for the id.
    for row in rnd.sample(transactions, N_DUP_TRANSACTIONS):
        dup = list(row)
        dup[0] = trans_id
        trans_id += 1
        transactions.append(dup)
    transactions.sort(key=lambda r: r[0])

    tables["transaction"] = (
        ["trans_id", "trans_dt", "enrl_id", "pymt_type_id", "full_price",
         "discount_type_id", "payment_amount", "full_paid"],
        transactions,
    )
    return tables


def main():
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--verify", action="store_true",
                    help="check the files on disk match a fresh build")
    args = ap.parse_args()

    tables = build()

    if args.verify:
        import io
        ok = True
        for name, (header, rows) in sorted(tables.items()):
            path = os.path.join(PRIMARY, name + ".csv")
            buf = io.StringIO()
            w = csv.writer(buf)
            w.writerow(header)
            w.writerows(rows)
            want = buf.getvalue()
            if not os.path.exists(path):
                print("  MISSING  %s" % name); ok = False
            elif open(path, newline="").read() != want:
                print("  CHANGED  %s.csv does not match a fresh build" % name)
                ok = False
            else:
                print("  ok       %-16s %6d rows" % (name + ".csv", len(rows)))
        mirror_ok = all(
            os.path.exists(os.path.join(MIRROR, n + ".csv")) for n in tables)
        print()
        if ok and mirror_ok:
            print("all %d tables match, and the solutions mirror is present"
                  % len(tables))
            return
        if not mirror_ok:
            print("the solutions/ mirror is incomplete")
        sys.exit(1)

    for d in (PRIMARY, MIRROR):
        os.makedirs(d, exist_ok=True)

    total = 0
    for name, (header, rows) in sorted(tables.items()):
        n = write_csv(os.path.join(PRIMARY, name + ".csv"), header, rows)
        write_csv(os.path.join(MIRROR, name + ".csv"), header, rows)
        total += n
        print("  %-16s %6d rows" % (name + ".csv", n))
    print("\n%d tables, %d rows, written to exercises/data/ and solutions/data/"
          % (len(tables), total))


if __name__ == "__main__":
    main()
