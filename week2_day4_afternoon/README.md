# Week 2, day 4 (afternoon) — 26/08

> Folders are named by position in the course; the worksheets inside still
> carry the calendar date they were taught on. Both refer to the same
> session.

Python, not SQL. The four core data structures — lists, tuples, sets and
dictionaries — the built-in functions that work across all of them, the
language around them (strings, conditionals, loops), a capstone, and a
data-engineering sheet that puts the structures to work on a dirty feed.

Eight worksheets, plus a second practice sheet for each of the six topics in
`more-practice/`.

Work through `exercises/` in order. Answers are in `solutions/`, same
numbering.

| # | Worksheet | Covers | Slides |
|---|---|---|---|
| 01 | `01_lists.ipynb` | creating, indexing, slicing, nesting, list methods, `+`/`*`/`len`/`in`, aliasing vs `.copy()`, comprehensions | 4–21 |
| 02 | `02_tuples.ipynb` | `(5,)` vs `(5)`, immutability, unpacking incl. `*rest`, operators, `index`/`count` | 22–30 |
| 03 | `03_sets.ipynb` | uniqueness, membership, the four set operations, `remove` vs `discard`, subset tests | 48–55 |
| 04 | `04_dictionaries.ipynb` | three ways to build one, `KeyError` vs `.get()`, views, iteration, key rules | 31–47 |
| 05 | `05_builtin_functions.ipynb` | `len`/`type`/`max`/`min`/`sum`, conversions, `sorted`, `range`/`zip`/`enumerate`, `map`/`filter` | Demo 5 |
| 06 | `06_strings_conditionals_loops.ipynb` | arithmetic, `str.split`/`replace`, `if`/`elif`/`else`, `for`/`while`/`range`, Hangman | — |
| 07 | `07_combined_challenges.ipynb` | capstone — eight business questions over one list-of-tuples dataset | all |
| 08 | `08_data_engineering_applications.ipynb` | the structures at work: `array` vs list, dedup, schema validation, joins, anti-joins, grouping, data quality | — |

## Extra practice

`exercises/more-practice/` holds a **second sheet for each of the six
topics**, numbered to match: `more-practice/03_sets.ipynb` is more practice on
worksheet 03. Same topic, different data, plus a couple of angles the first
sheet did not reach.

| # | Extra sheet | Adds |
|---|---|---|
| 01 | lists | step slicing, a grid of lists, the *shallow* copy trap |
| 02 | tuples | swapping via unpacking, a mutable list *inside* a tuple |
| 03 | sets | `set()` on a string, deduplicating *while keeping order* |
| 04 | dictionaries | **counting** and **grouping** — the two jobs you'll actually do |
| 05 | built-in functions | `max(key=…)`, sorting records, `dict(zip(...))` |
| 06 | strings, conditionals, loops | `and`/`or`, `break`/`continue`, CSV parsing, FizzBuzz |

Use them when a topic didn't land, or after class. Answers are in
`solutions/more-practice/`, same numbering. The capstone has no extra sheet —
it already draws on everything.

Roughly: 01–04 are the four structures one at a time, 05 is the toolkit that
works on all of them, 06 is the language around them, 07 puts everything
together, and 08 asks what any of it is *for*.

**Worksheet 08 is the data-engineering one.** It works on a deliberately
dirty feed — a duplicate record, a record missing a field, a user ID absent
from the lookup table, null amounts — and walks the pipeline: deduplicate,
validate the schema, coerce types, join to a dimension, find the orphans,
aggregate, then report data quality. It also introduces `array.array` as the
typed, compact counterpart to a list, and explains where numpy and pandas
take over in real work. Neither is installed here; nothing on this sheet
needs them.

Worksheet 06 has no slide reference because it is not from the L04 deck: it
covers the same ground as the course's `Python Exercises 1`, described below.

## The original WeCloudData notebooks

The course's own notebooks are here too, unmodified, in `wcd-originals/`:

```
exercises/wcd-originals/     Demo_Data_Structures_1..5   (worked examples, read these)
                             Exercise_Data_Structures_1..4
                             Python Exercises 1_v1.ipynb
solutions/wcd-originals/     Exercise_Data_Structures_1..4_Solution
                             Python Exercises 1 (Solutions)_v1.ipynb
```

They are **split across `exercises/` and `solutions/`** rather than kept in
one folder, so the questions and their answers stay separable. The files
themselves are byte-for-byte as shipped.

(The answers are reachable in the console anyway, via the top-level
`SOLUTIONS/` folder — see the root README.)

How they relate to these worksheets:

- The five **`Demo_`** notebooks are the lecture's worked examples, each cell
  followed by a "What you should see" explanation. Read these first if a
  topic didn't land; they explain, where these worksheets ask.
- **`Exercise_Data_Structures_1..4`** cover the same ground as worksheets
  01–04 and their extra-practice sheets, one method per question. Use them for extra repetition — they are
  gentler and more mechanical.
- **`Python Exercises 1_v1.ipynb`** is the odd one out: it is **not** about
  data structures. It covers general Python — arithmetic, `str.split`,
  `if`/`else`, `for`/`while`/`range`, and a Hangman project. **Worksheet 06 and its extra-practice sheet
  cover the same ground** in this lab's format, with the expected output
  written down; use whichever you prefer, or both.

Two warnings about `Python Exercises 1`:

- Several cells use **`input()`**, which blocks waiting for you to type. Run
  those by hand; they cannot be re-run cleanly with Restart & Run All, and
  the WeCloudData solution notebook carries the same caveat. Worksheet 06
  deliberately avoids this — its Hangman runs from a fixed list of guesses,
  with the interactive version supplied but commented out.
- Its solutions contain a date-dependent line (`2022 - user['year_of_birth']`),
  so the age it computes is now wrong. That is in the original, not a typo.

## Every worksheet is a Jupyter notebook

Open one, run the setup cell at the top once, then work down: each question
is a Markdown cell with a `## Your Code Here` cell underneath it for your
answer. Run a cell with `Shift+Enter` and the result appears immediately
below it, so you can iterate without leaving the page.

Questions run **in order** and several of them change their data in place, so
a later question sees the structure as the earlier ones left it. If you lose
track, print it — or re-run the setup cell to get back to a known state.

## Nothing here needs the database

No `%%sql`, no connection cell, no MySQL. These worksheets are **pure Python
and the standard library** — exactly the scope of the lecture. If the lab is
running you can open them at `http://<instructor-ip>:8888` like any other
worksheet, but you can equally run them in any Python 3 you already have.

Only one line in the whole set imports anything: worksheet 08 uses
`from array import array`, which is standard library. If you find yourself
reaching for `pandas`, `collections` or `numpy`, that is a sign you have
wandered past what this session covers — and the shared console does not
have them installed, so it will fail rather than mislead you.

## Some cells are supposed to fail

Eleven questions across the set end in a deliberate error, because the
error *is* the lesson: assigning to a tuple, indexing a set, `remove`-ing
something that is not there, reading a missing dictionary key, using a list
as a key, `int("twelve")`, and appending a string to a typed `array` —
several of them twice, once on each sheet of a pair.

They are flagged in the question text. Read the message, then carry on with
the next cell. It also means **Restart & Run All will stop** on those seven
worksheets — that is expected, not a broken notebook. Worksheets 01, 06 and
07, and extra sheets 01, 05 and 06, run clean from top to bottom. Worksheet
08 stops once, at Q2.

## Where the slides and Python disagree

- **The deck teaches Dictionary before Set; these worksheets do not.** The
  numbering here follows the demo/exercise notebooks (List, Tuple, Set,
  Dictionary), so worksheet 03 is sets and 04 is dictionaries, while slides
  31–47 are dictionaries and 48–55 are sets. Same content, different running
  order — the table above maps each worksheet to its slides.
- **`{}` does not create an empty set.** It creates an empty dictionary.
  Worksheet 03 Q1 makes you use `set()` instead, and an empty set prints back
  as `set()` for the same reason.
- **`sort()` and `reverse()` return `None`.** The slides show them working
  but not what they hand back, so `numbers = numbers.sort()` looks harmless
  and destroys your list. Worksheet 01 Q9 makes you print the `None`.
- **`sorted(key=...)` is not in the deck's method table** (slide 16) but it
  is the single most useful sorting option you will use. Worksheet 05 Q5
  and extra sheet 05 Q3–Q5 cover it.
- **`extend()` on a string adds characters, not a word.** Slide 18 shows
  this; it is worth hitting yourself, because it is silent. Worksheet 01 Q6.
- **`input()` is taught but is not used here.** It blocks waiting for typing,
  which makes a notebook impossible to re-run cleanly. Every worksheet uses
  fixed data instead.
- **Set order is not stable.** Not merely "unordered in theory" — the same
  code prints sets in a different arrangement on different runs. The
  worksheet 03 solutions quote set *contents* and deliberately never quote
  their order.

## A theme worth naming

Several questions end with a result that is arithmetically perfect and
substantively wrong: the inverted dictionary in 04 Q11 that silently loses a
pair, the `zip` in 05 Q7 that drops a data point without a word, the join in
07 that mislays 15.8% of the revenue, the two defensible averages in 07 that
differ by a factor of two, and the **three** defensible revenue figures in
08 that differ by 45%.

That is deliberate, and it is the most useful thing in this session. None of
those cases raises an error. Getting the code to run is the easy half;
knowing what the number does **not** entitle you to conclude is the half that
matters — and it is the same lesson the SQL sessions ended on.

If you did 24/08, worksheet 07 will feel familiar on purpose: `order_lines`
is one row per order **line**, not per order, exactly like `superstore.orders`.
The `COUNT(*)` vs `COUNT(DISTINCT OrderID)` trap is waiting there in Python
form.

## How to use the solutions

Each solution quotes the **actual output**, produced by running the code on
the same Python the lab ships (3.13), so you can check yourself without
guessing — and diagnose *where* you diverged rather than only *that* you did.
Try to finish a question before opening it; when you're stuck for more than a
few minutes, read only the next line.
