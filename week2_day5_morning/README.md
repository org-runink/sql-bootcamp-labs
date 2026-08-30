# Week 2, day 5 (morning) — 27/08

> Folders and worksheet titles both name the position in the course. The
> calendar date this session was taught on is in the heading above, and
> nowhere else.

Python, not SQL. This folder holds **two lectures**: L05, control flow and
iteration, and L06, functions and code reusability. Worksheets 01–08 are the
first; 09–14 are the second.

Fourteen worksheets, plus a second practice sheet for ten of the topics in
`more-practice/`.

Work through `exercises/` in order. Answers are in `solutions/`, same
numbering.

## Part 1 — Control flow and iteration (L05), worksheets 01–08

| # | Worksheet | Covers | Slides |
|---|---|---|---|
| 01 | `01_conditionals.ipynb` | `if`/`elif`/`else`, comparison and logical operators, nesting, truthiness, the conditional expression | 2–23 |
| 02 | `02_for_loops.ipynb` | collections, `range()` with steps, strings, unpacking, `enumerate`, dictionaries, nesting | 24–53 |
| 03 | `03_comprehensions.ipynb` | list/dict/set comprehensions, the two positions of `if`, nesting, scope | 54–66 |
| 04 | `04_while_loops.ipynb` | counters, indefinite loops, `while True`, guards, and three ways a while loop goes wrong | 67–77 |
| 05 | `05_break_continue_pass.ipynb` | `break`, `continue`, `pass`, `for`/`while` … `else`, breaking out of nested loops | 2, 76–77 |
| 06 | `06_combined_challenges.ipynb` | capstone — ten questions over one morning of clickstream | all |
| 07 | `07_control_flow_in_pipelines.ipynb` | batching, retrying, validating, joining, watermarks, and the run report | — |
| 08 | `08_reading_real_files.ipynb` | four real tab-separated files: headers, joins across files, dates without `datetime`, and four kinds of wrong number | — |

## Part 2 — Functions and code reusability (L06), worksheets 09–14

| # | Worksheet | Covers | Slides |
|---|---|---|---|
| 09 | `09_defining_functions.ipynb` | `def`, `return`, parameters, docstrings, returning several values, early returns — and print vs return | 4–20 |
| 10 | `10_function_arguments.ipynb` | positional, keyword, defaults, `*args`, `**kwargs`, ordering, unpacking at the call site, the mutable default | 21–41 |
| 11 | `11_scope_and_side_effects.ipynb` | local vs global, `global`, mutating an argument, LEGB, pure vs impure, and the deck's own DRY refactor | 43–58 |
| 12 | `12_lambda_map_filter.ipynb` | `lambda`, `filter`, `map`, `sorted(key=…)`, `max(key=…)`, and why `map` objects are one-shot | 59–67 |
| 13 | `13_recursion.ipynb` | base cases, the call stack, factorial and Fibonacci, what recursion costs, and where it actually wins | 68–87 |
| 14 | `14_functions_capstone.ipynb` | capstone — rebuild worksheet 07's pipeline as a toolkit, then run it on a second feed for free | all |

## Extra practice

`exercises/more-practice/` holds a **second sheet for ten of the topics**,
numbered to match: `more-practice/03_comprehensions.ipynb` is more practice on
worksheet 03. Same topic, different data, plus angles the first sheet did not
reach.

| # | Extra sheet | Adds |
|---|---|---|
| 01 | conditionals | `in` as a test, what `and`/`or` actually *return*, short-circuiting, string comparison |
| 02 | for loops | `zip`, `zip` on unequal lengths, `sorted()` in a loop header, parsing a CSV line |
| 03 | comprehensions | `any()` and `all()`, dict → list, and the point where a comprehension should be a loop |
| 04 | while loops | two indexes in one list, emulating a do-while, `while` inside `while` |
| 05 | break/continue/pass | **what is the `break` of a comprehension?** (there isn't one) |
| 09 | defining functions | composing small functions, and a **dictionary of functions** picked by name |
| 10 | function arguments | the bare `*` for keyword-only arguments, and the mutable default in its **dictionary** form |
| 11 | scope | shadowing a **builtin**, closures, and pure vs impure side by side |
| 12 | lambda/map/filter | sorting on **two** fields with a tuple key, `map` over two lists, a dict of lambdas |
| 13 | recursion | walking a nested config, recursive binary search, and two ways a base case can be unreachable |

Use them when a topic didn't land, or after class. Answers are in
`solutions/more-practice/`, same numbering. Worksheets 06, 07, 08 and 14 have
no extra sheet — they already draw on everything.

Roughly: 01 is the decision, 02–04 are the three ways to repeat, 05 is how to
get out early, 06 puts everything together, 07 asks what any of it is *for*,
08 does it on data that was not typed into a cell — and then 09–14 wrap all of
that up so it can be reused.

**Worksheet 07 is the data-engineering one.** Every pattern on it is one you
meet in the first week of a data job: batching a list into fixed-size chunks,
retrying a flaky call with a cap, validating rows with `continue`, joining to
a dimension table, processing only what is new since the last run, and writing
the summary at the end. It finishes with two run reports that are both true,
one of which would let a broken pipeline pass unnoticed for months.

**Worksheet 14 is worksheet 07 again, as functions.** Same job, rebuilt as a
toolkit — and then run on a second feed, with a different threshold, in three
lines. That contrast is the entire argument of the L06 lecture, and it is
worth doing 07 first so the difference lands.

**Worksheet 08 is the one with real files.** `exercises/data/` holds four
tab-separated files with header rows:

| File | Data rows | Columns |
|---|---|---|
| `orders.csv` | 1,093 | `OrderID`, `ProductID`, `CustomerID`, `OrderDate`, `OrderPriority`, `OrderQuantity`, `Sales`, `Discount`, `ShipMode`, `Profit`, `UnitPrice`, `ShippingCost` |
| `customers.csv` | 1,832 | `CustomerID`, `CustomerName`, `Province`, `Region`, `CustomerSegment` |
| `products.csv` | 1,237 | `ProductID`, `ProductName`, `ProductCategory`, `ProductSubCategory`, `ProductContainer`, `ProductBaseMargin` |
| `returns.csv` | 572 | `OrderID`, `Status` |

This is the **same superstore data behind the SQL sessions**, read a line at a
time instead of queried. `orders.csv` is a sample: every line item of the
first 600 `OrderID`s in the source file, so orders that span several rows are
preserved — which is the point of Q4. The dimension files are complete, so
most of their rows have no matching order, which is the point of Q3 and Q6.
`products.csv` was transcoded from latin-1 to UTF-8; nothing else was altered.

(`week2_day2_afternoon/exercises/data/` holds a different, 400-row sample of
the same tables, made for that session's `LOAD DATA LOCAL INFILE` exercise.
The two are not interchangeable — this one deliberately keeps the repeated
`OrderID`s that the 2408 sample does not have.)

Worksheets 07, 08 and 14 have no slide reference because they are not from
either deck.

## The original WeCloudData notebooks

The course's own notebooks for L05 are here too, unmodified, in
`wcd-originals/`:

```
exercises/wcd-originals/     Demo_Control_Flow_1_For_Loops
                             Demo_Control_Flow_2_While_Loops
                             Demo_Control_Flow_3_Comprehensions
                             Exercise_Control_Flow_1..3
                             Python Exercises 2_v1.ipynb
solutions/wcd-originals/     Exercise_Control_Flow_1..3_Solution
                             Python Exercises 2 (Solutions)_v1.ipynb
```

They are **split across `exercises/` and `solutions/`** rather than kept in
one folder, so the questions and their answers stay separable. The files
themselves are byte-for-byte as shipped.

(The answers are reachable in the console anyway, via the top-level
`SOLUTIONS/` folder — see the root README.)

There is no WeCloudData practice set for L06; worksheets 09–14 stand alone.

How the L05 ones relate to these worksheets:

- The three **`Demo_`** notebooks are the lecture's worked examples, each cell
  followed by a "What you should see" explanation. Read these first if a
  topic didn't land; they explain, where these worksheets ask.
- **`Exercise_Control_Flow_1..3`** cover the same ground as worksheets 02, 04
  and 03 — one construct per question, gentler and more mechanical. 20
  questions on for loops, 9 on while loops, 7 on comprehensions. Use them for
  extra repetition.
- **`Python Exercises 2_v1.ipynb`** is the odd one out. It is a proper
  end-to-end exercise over six CSV files — counting distinct customers,
  finding the most expensive product, joining orders to customers.

Three warnings about the WeCloudData set:

- **`Python Exercises 2` cannot be run as shipped.** It reads
  `data/orders.csv`, `data/customers.csv` and four more, and **the `data/`
  folder is not in the course zip.** Read it for the technique — then do
  **worksheet 08**, which asks the same kinds of question against files that
  are actually here.
- Its solutions use `def`, `import re` and `import datetime`. The first of
  those is worksheets 09–14; the other two are a later lecture, and nothing
  in these worksheets needs them.
- Demo 2 and the Exercise 2 solutions use **`input()`**, which blocks waiting
  for you to type. Run those cells by hand; they cannot be re-run cleanly
  with Restart & Run All. Worksheets 04 and 09 deliberately avoid this —
  their guessing game and login read from fixed lists instead.

## Every worksheet is a Jupyter notebook

Open one, run the setup cell at the top once, then work down: each question
is a Markdown cell with a `## Your Code Here` cell underneath it for your
answer. Run a cell with `Shift+Enter` and the result appears immediately
below it, so you can iterate without leaving the page.

Questions run **in order** and several of them change their data in place, so
a later question sees the structure as the earlier ones left it. If you lose
track, print it — or re-run the setup cell to get back to a known state.

## Nothing here needs the database

No `%%sql`, no connection cell, no MySQL. These worksheets are **pure Python**
— exactly the scope of the two lectures. If the lab is running you can open
them at `http://<instructor-ip>:8888` like any other worksheet, but you can
equally run them in any Python 3 you already have.

**There is not one `import` in the whole set.** Everything on these 24 sheets
is built into the language — including worksheet 08's file reading, because
`open()` is a builtin. If you find yourself reaching for `csv`, `itertools`,
`collections`, `pandas` or `numpy`, that is a sign you have wandered past what
these sessions cover — and the shared console does not have the last two
installed, so it will fail rather than mislead you.

**Worksheets 01–08 contain no `def` and no `lambda`, on purpose.** Everything
in the L05 block is solvable without them, and doing it that way is what makes
the L06 block land. From worksheet 09 on, both are the subject.

## Some cells are supposed to fail

**Twenty-one questions across the set end in a deliberate error**, because the
error *is* the lesson:

| Sheet | Q | Raises |
|---|---|---|
| 01 conditionals | 11 | `TypeError` — comparing `"84.50"` with a number |
| 02 for loops | 10 | `RuntimeError` — dictionary changed size during iteration |
| 03 comprehensions | 11 | `TypeError` — a list as a dictionary key |
| 04 while loops | 11 | `IndexError` — `pop` from empty list |
| 05 break/continue/pass | 11 | `NameError` — loop variable from a loop that never ran |
| 08 reading real files | 11 | `ValueError` — forgetting to skip the header row |
| 09 defining functions | 11 | `TypeError` — missing a required argument |
| 10 function arguments | 11 | `NameError` — slide 34's half-finished rename |
| 11 scope | 11 | `NameError` — reaching for a local after the call |
| 12 lambda/map/filter | 11 | `KeyError` — sorting on a field that isn't there |
| 13 recursion | 11 | `RecursionError` — no base case |
| extra 01 | 9 | `KeyError` — a key that isn't there |
| extra 02 | 9 | `IndexError` — indexing two lists of different lengths |
| extra 03 | 9 | `TypeError` — a set cannot hold lists either |
| extra 04 | 9 | `IndexError` — `<=` against a length |
| extra 05 | 9 | `NameError` — the value the `break` forgot to save |
| extra 09 | 9 | `NameError` — calling a function before its `def` has run |
| extra 10 | 9 | `TypeError` — two values for the same argument |
| extra 11 | 9 | `UnboundLocalError` — assigning to a global without saying so |
| extra 12 | 9 | `TypeError` — a lambda called with too few arguments |
| extra 13 | 9 | `RecursionError` — a base case that cannot be reached |

Every one of them is the **last question on its sheet**, so Restart & Run All
gets all the way to the bottom before it stops. That is expected, not a broken
notebook. **Worksheets 06, 07 and 14 run clean from top to bottom.**

## Where the slides and Python disagree

Both decks have places where the code and the output printed beside it cannot
both be right. Each one is a worksheet question, so you see it happen rather
than take our word for it.

**L05 — control flow:**

- **Slide 23** shows the same fraud check written as an `if`/`else` and as a
  conditional expression, and prints `False` for one and `True` for the other.
  Same input, same test. Worksheet 01 Q9.
- **Slide 46** is titled *reversing a list* and loops
  `range(num_students-1, 0, -2)`, which skips every other element **and** can
  never reach index 0. Six enrolments in, three out, and `jack` never
  appears. Worksheet 02 Q5.
- **Slide 51** raises four different prices by 13% and prints `2.541031` for
  all four. Multiplying different numbers by a constant cannot make them
  equal. Worksheet 02 Q9.
- **Slide 65** builds a dictionary whose values are the string `"On sale"`,
  and prints `'Out of stock'` underneath it. Worksheet 03 Q6.

**L06 — functions:**

- **Slide 25** calls `welcome('Hi, welcome to')` on a function with defaults
  and prints `welcome to Hi!`. Python prints `Welcome to Hi, welcome to!` —
  a positional argument fills the *first* parameter, not the one that sounds
  right. Worksheet 10 Q2.
- **Slide 34** renames a parameter from `*args` to `*nums` and leaves
  `sum(args)` in the body, then prints a result underneath. That code raises
  `NameError`; the output shown is the other version's. Worksheet 10 Q11.
- **Slide 79** traces `factorial(5)` and its trace starts at `n = 4`, while
  still ending with the `n = 5` line. Worksheet 13 Q2.
- **Slide 87** offers a recursive and an iterative factorial as two ways to do
  the same thing. They disagree at `n = 0`: the recursive one returns **0**,
  the iterative one returns 1, and `0!` is 1. Worksheet 13 Q8.

Two more where the slide is not wrong, just quiet:

- **Slide 48** is titled *convert characters with odd indexes to uppercase*
  and its code steps `range(0, len, 2)`, which is the even ones. The code and
  its output agree; only the title doesn't. Worksheet 02 Q7.
- **Slide 43** numbers a list with a manual counter and an `if`/`else` whose
  two branches do the same thing. That is `enumerate` written in nine lines,
  and the `if` does nothing. Worksheet 02 Q4.

And three things the decks list and never cover:

- **`break`, `continue` and `pass`** are learning objectives on L05 slide 2
  and appear nowhere else. Worksheet 05.
- **Scope** — L06's resources list links *Python Scope: The LEGB Rule* and the
  deck never mentions scope again. Worksheet 11.
- **Mutable default arguments** are not mentioned at all, and they are the
  single most common way a Python function surprises you. Worksheet 10 Q4 and
  extra sheet 10 Q4.

## A theme worth naming

Several questions end with a result that is arithmetically perfect and
substantively wrong:

- the grade chain in **01 Q5** where a 95 is graded `C` and two branches can
  never run;
- the `zip` in **extra 02 Q4** that drops a city without a word;
- the inverted dictionary in **03 Q7** that loses an entry to a duplicate
  value;
- the three conversion rates in **06 Q10** — per event, per user, per session
  — where the highest is four times the lowest;
- the join in **07 Q6** that loses 31.00 of 78.74 to a single orphaned row;
- **07 Q11**, where a pipeline reports `rows delivered: 4, errors: 0,
  status: OK` while half the feed did not arrive;
- **08 Q4**, where `orders.csv` has 1,093 rows and 600 orders, so the obvious
  row count is nearly double the answer;
- **08 Q6**, where a lookup dictionary built from 1,237 rows comes out with
  1,234 keys because three product ids repeat — and the three lost products
  are not duplicates, they are different products sharing an id;
- **08 Q7**, where the per-region order counts sum to 640 against a true
  total of 600, because 39 orders straddle two regions and distinct counts do
  not add up across groups;
- **08 Q10**, where the region subtotals and the grand total differ in the
  twelfth decimal place, so a reconciliation written as `==` fails on correct
  data;
- **12 Q8**, where `max(staff, key=lambda p: p["role"])` returns a perfectly
  real record in answer to a question that has no answer;
- and **14 Q10**, where a well-named function returns two correct averages,
  one of which is the average of a single row.

None of those raises an error. That is deliberate, and it is the most useful
thing in these sessions: getting the code to run is the easy half, and knowing
what the number does **not** entitle you to conclude is the half that matters.
It is the same lesson the SQL sessions and week 2, day 4 ended on.

Worksheet 07 Q8 is the sharpest version of it. A correct incremental run and a
source file that never arrived print exactly the same thing: *0 rows
processed, no errors*.

And worksheet 14 Q10 is the sting in the tail of the functions lecture: a
function is not a guarantee of meaning. Wrapping a bad average in a good name
makes it more convincing, not more true.

## How to use the solutions

Each solution quotes the **actual output**, produced by running the code on
the same Python the lab ships (3.13), so you can check yourself without
guessing — and diagnose *where* you diverged rather than only *that* you did.
Try to finish a question before opening it; when you're stuck for more than a
few minutes, read only the next line.
