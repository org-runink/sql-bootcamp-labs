# WeCloudData — Control Flow and Iteration Practice

The course's own L05 notebooks, **exactly as shipped** in
`Control_Flow_and_Iteration_Practice.zip`. Nothing here has been edited,
renamed or reordered — this folder is the vendor zip unpacked, kept so the
original layout stays available for reference.

```
Demo_Control_Flow_1_For_Loops_v1.ipynb          worked examples, with outputs
Demo_Control_Flow_2_While_Loops_v1.ipynb        and "What you should see" cells
Demo_Control_Flow_3_Comprehensions_v1.ipynb

Exercise_Control_Flow_1_For_Loops_v1.ipynb      20 questions, stubs only
Exercise_Control_Flow_2_While_Loops_v1.ipynb     9 questions
Exercise_Control_Flow_3_Comprehension_v1.ipynb   7 questions
    ...and their three _Solution notebooks

Python Exercises 2_v1.ipynb                     7 questions over six CSV files
Python Exercises 2 (Solutions)_v1.ipynb
```

## The same files are also under `morning-class-2708/`

Byte-for-byte identical, but **split** so questions and answers stay
separable:

- `morning-class-2708/exercises/wcd-originals/` — the three demos, the three
  exercise notebooks, and `Python Exercises 2_v1.ipynb`
- `morning-class-2708/solutions/wcd-originals/` — the three `_Solution`
  notebooks and `Python Exercises 2 (Solutions)_v1.ipynb`

**That split copy is the one students reach.** `docker-compose.yml` mounts
each class's `exercises/` folder into the shared JupyterLab; this root folder
is not mounted, so it is only visible to someone who has cloned the repo.

If you edit either copy, edit both — nothing checks that they stay in sync.

## Three things to know before running them

- **`Python Exercises 2` cannot be run as shipped.** It reads
  `data/orders.csv`, `data/customers.csv` and four more, and the `data/`
  folder is not in the zip. `morning-class-2708/exercises/08_reading_real_files.ipynb`
  asks the same kinds of question against files that are actually present.
- Its solutions use `def`, `import re` and `import datetime` — the first is
  the L06 lecture, the other two are later still.
- `Demo_Control_Flow_2` and the Exercise 2 solutions call **`input()`**, which
  blocks waiting for you to type. Run those cells by hand; they cannot be
  re-run cleanly with Restart & Run All.

See [`morning-class-2708/README.md`](../morning-class-2708/README.md) for how
these map onto the lab's own worksheets.
