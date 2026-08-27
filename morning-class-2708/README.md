# Morning class — 27/08

Python, not SQL, and the second Python session. Where 26/08 covered the four
data structures, this one covers what makes a program *do* something with
them: conditionals, `for` loops, comprehensions, `while` loops, and
`break`/`continue`/`pass`.

Seven worksheets, plus a second practice sheet for each of the five topics in
`more-practice/`.

Work through `exercises/` in order. Answers are in `solutions/`, same
numbering.

| # | Worksheet | Covers | Slides |
|---|---|---|---|
| 01 | `01_conditionals.ipynb` | `if`/`elif`/`else`, comparison and logical operators, nesting, truthiness, the conditional expression | 2–23 |
| 02 | `02_for_loops.ipynb` | collections, `range()` with steps, strings, unpacking, `enumerate`, dictionaries, nesting | 24–53 |
| 03 | `03_comprehensions.ipynb` | list/dict/set comprehensions, the two positions of `if`, nesting, scope | 54–66 |
| 04 | `04_while_loops.ipynb` | counters, indefinite loops, `while True`, guards, and three ways a while loop goes wrong | 67–77 |
| 05 | `05_break_continue_pass.ipynb` | `break`, `continue`, `pass`, `for`/`while` … `else`, breaking out of nested loops | 2, 76–77 |
| 06 | `06_combined_challenges.ipynb` | capstone — ten questions over one morning of clickstream | all |
| 07 | `07_control_flow_in_pipelines.ipynb` | batching, retrying, validating, joining, watermarks, and the run report | — |

## Extra practice

`exercises/more-practice/` holds a **second sheet for each of the five
topics**, numbered to match: `more-practice/03_comprehensions.ipynb` is more
practice on worksheet 03. Same topic, different data, plus angles the first
sheet did not reach.

| # | Extra sheet | Adds |
|---|---|---|
| 01 | conditionals | `in` as a test, what `and`/`or` actually *return*, short-circuiting, string comparison |
| 02 | for loops | `zip`, `zip` on unequal lengths, `sorted()` in a loop header, parsing a CSV line |
| 03 | comprehensions | `any()` and `all()`, dict → list, and the point where a comprehension should be a loop |
| 04 | while loops | two indexes in one list, emulating a do-while, `while` inside `while` |
| 05 | break/continue/pass | **what is the `break` of a comprehension?** (there isn't one) |

Use them when a topic didn't land, or after class. Answers are in
`solutions/more-practice/`, same numbering. The capstone and the pipeline
sheet have no extra sheet — they already draw on everything.

Roughly: 01 is the decision, 02–04 are the three ways to repeat, 05 is how to
get out early, 06 puts everything together, and 07 asks what any of it is
*for*.

**Worksheet 07 is the data-engineering one.** Every pattern on it is one you
meet in the first week of a data job: batching a list into fixed-size chunks,
retrying a flaky call with a cap, validating rows with `continue`, joining to
a dimension table, processing only what is new since the last run, and writing
the summary at the end. It finishes with two run reports that are both true,
one of which would let a broken pipeline pass unnoticed for months.

Worksheet 07 has no slide reference because it is not from the L05 deck.

## The original WeCloudData notebooks

The course's own notebooks are here too, unmodified, in `wcd-originals/`:

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

How they relate to these worksheets:

- The three **`Demo_`** notebooks are the lecture's worked examples, each cell
  followed by a "What you should see" explanation. Read these first if a
  topic didn't land; they explain, where these worksheets ask.
- **`Exercise_Control_Flow_1..3`** cover the same ground as worksheets 02, 04
  and 03 — one construct per question, gentler and more mechanical. 20
  questions on for loops, 9 on while loops, 7 on comprehensions. Use them for
  extra repetition.
- **`Python Exercises 2_v1.ipynb`** is the odd one out. It is a proper
  end-to-end exercise over six CSV files — counting distinct customers,
  finding the most expensive product, joining orders to customers — and it is
  the closest thing in the course to worksheet 07.

Three warnings about the WeCloudData set:

- **`Python Exercises 2` cannot be run as shipped.** It reads
  `data/orders.csv`, `data/customers.csv` and four more, and **the `data/`
  folder is not in the course zip.** Read it for the technique; worksheet 07
  is the runnable equivalent, with its data inline.
- Its solutions use `def`, `import re` and `import datetime` — all of which
  are the *next* two lectures, not this one. Nothing in these worksheets
  needs them.
- Demo 2 and the Exercise 2 solutions use **`input()`**, which blocks waiting
  for you to type. Run those cells by hand; they cannot be re-run cleanly
  with Restart & Run All. Worksheet 04 deliberately avoids this — its
  guessing game reads from a fixed list of guesses.

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
— exactly the scope of the lecture. If the lab is running you can open them
at `http://<instructor-ip>:8888` like any other worksheet, but you can equally
run them in any Python 3 you already have.

**There is not one `import` in the whole set.** Everything on these twelve
sheets is built into the language. If you find yourself reaching for
`itertools`, `collections`, `pandas` or `numpy`, that is a sign you have
wandered past what this session covers — and the shared console does not have
the last two installed, so it will fail rather than mislead you.

Nor is there a `def`. Functions are the *next* lecture (L06), and every
worksheet here is written to be solvable without them.

## Some cells are supposed to fail

**Ten questions across the set end in a deliberate error**, because the error
*is* the lesson:

| Sheet | Q | Raises |
|---|---|---|
| 01 conditionals | 11 | `TypeError` — comparing `"84.50"` with a number |
| 02 for loops | 10 | `RuntimeError` — dictionary changed size during iteration |
| 03 comprehensions | 11 | `TypeError` — a list as a dictionary key |
| 04 while loops | 11 | `IndexError` — `pop` from empty list |
| 05 break/continue/pass | 11 | `NameError` — loop variable from a loop that never ran |
| extra 01 | 9 | `KeyError` — a key that isn't there |
| extra 02 | 9 | `IndexError` — indexing two lists of different lengths |
| extra 03 | 9 | `TypeError` — a set cannot hold lists either |
| extra 04 | 9 | `IndexError` — `<=` against a length |
| extra 05 | 9 | `NameError` — the value the `break` forgot to save |

Every one of them is the **last question on its sheet**, so Restart & Run All
gets all the way to the bottom before it stops. That is expected, not a broken
notebook. **Worksheets 06 and 07 run clean from top to bottom.**

## Where the slides and Python disagree

The L05 deck has four places where the code and the output printed beside it
cannot both be right. Each one is a worksheet question, so you see it happen
rather than take our word for it.

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

Two more where the slide is not wrong, just quiet:

- **Slide 48** is titled *convert characters with odd indexes to uppercase*
  and its code steps `range(0, len, 2)`, which is the even ones. The code and
  its output agree; only the title doesn't. Worksheet 02 Q7.
- **Slide 43** numbers a list with a manual counter and an `if`/`else` whose
  two branches do the same thing. That is `enumerate` written in nine lines,
  and the `if` does nothing. Worksheet 02 Q4.

And one thing the deck lists as a learning objective on slide 2 and then never
covers: **`break`, `continue` and `pass`**. That is what worksheet 05 is for.

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
- and **07 Q11**, where a pipeline reports `rows delivered: 4, errors: 0,
  status: OK` while half the feed did not arrive.

None of those raises an error. That is deliberate, and it is the most useful
thing in this session: getting the code to run is the easy half, and knowing
what the number does **not** entitle you to conclude is the half that matters.
It is the same lesson the SQL sessions and 26/08 ended on.

Worksheet 07 Q8 is the sharpest version of it. A correct incremental run and a
source file that never arrived print exactly the same thing: *0 rows
processed, no errors*.

## How to use the solutions

Each solution quotes the **actual output**, produced by running the code on
the same Python the lab ships (3.13), so you can check yourself without
guessing — and diagnose *where* you diverged rather than only *that* you did.
Try to finish a question before opening it; when you're stuck for more than a
few minutes, read only the next line.
