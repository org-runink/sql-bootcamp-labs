# Week 4, day 3 (morning) — Data management and governance

The *Data Governance L01* lecture as six worksheets. It is a **discussion
session**: there is no dataset, no SQL to write and nothing to run. Every answer
space is a markdown block.

That is deliberate. Governance failures are almost never technical — the
lecture's opening story has encryption in place and still loses control of the
data. What is missing is accountability, and you cannot debug that with a query.

```
exercises/     worksheets 01–06
solutions/     discussion answers, not a marking scheme
```

## The worksheets

| # | Sheet | Covers |
|---|---|---|
| 01 | [`01_the_data_sharing_story.ipynb`](exercises/01_the_data_sharing_story.ipynb) | the five-department story; the three risks; tracing accountability; defining governance from the failure |
| 02 | [`02_governance_and_management.ipynb`](exercises/02_governance_and_management.ipynb) | governance vs management; why it lands on engineers; where it appears in the lifecycle; inconsistent definitions |
| 03 | [`03_quality_trust_and_ai.ipynb`](exercises/03_quality_trust_and_ai.ipynb) | training data and bias; the burnout-monitoring ethics case; AI readiness as data readiness; the five AI questions |
| 04 | [`04_frameworks_and_regulation.ipynb`](exercises/04_frameworks_and_regulation.ipynb) | GDPR/CCPA/PIPEDA/PIPL/POPIA; the DAMA wheel's ten knowledge areas; people-process-technology; where to start |
| 05 | [`05_case_study_acquisitions.ipynb`](exercises/05_case_study_acquisitions.ipynb) | the defence-company case study: four challenges, sequencing, the operating model, and what to measure |
| 06 | [`06_governance_in_practice.ipynb`](exercises/06_governance_in_practice.ipynb) | **hands-on with yesterday's dbt project**: find the governance features, tests as agreements, what dbt does *not* cover, the two Azure layers |

Read them in order. 01 sets up the problem the rest of the day answers, and 06
is where it becomes concrete.

## Worksheet 06 needs yesterday's project

Open `week4_day2_afternoon/dbt-project/demo/` alongside it. The lecture claims
dbt supports governance by helping teams document models, define tests, track
dependencies, standardise logic and generate lineage — and students spent the
previous session building a project that does all five. Worksheet 06 has them
find each claim in the files, then work out what dbt **does not** cover:
classification, access control, retention, and anything outside the project's
own boundary.

Nothing needs to run. Reading the files is the exercise.

## How to teach it

The questions are written for **groups**, and several have no single right
answer:

- **Worksheet 01, Question 1** works best cold. Ask for failure modes *before*
  showing the lecture's three risks; groups routinely find all three plus
  "nobody knows who to ask".
- **Worksheet 03, Question 2** — the employee burnout case — is the one that
  should generate disagreement. A group that splits is doing it correctly. Push
  on the *conditions*, not the verdict.
- **Worksheet 05** is a 30–40 minute design activity. The sequencing question
  (Q2) matters more than the list; make groups justify what each step unblocks.
- **Worksheet 06, Question 5** asks whether yesterday's project is "governed".
  The intended landing: the mechanisms are there, the decisions are not — which
  is a fair description of most real dbt projects.

Solutions are written as *discussion answers*, and say so at the top. Where a
question asks for judgement, the reasoning matters more than matching the text.

## The through-line

The lecture's opening story is the spine of the day. Department B encrypts its
data, cleans it, and is accountable for it — and still loses control the moment
copies start moving, because no one owns the copies. Every later sheet is a
different angle on that same gap:

- **02** names it: management is the doing, governance is the deciding.
- **03** shows what it costs when the data feeds a model rather than a report.
- **04** shows the regulators making it mandatory.
- **05** scales it to ten subsidiaries.
- **06** shows how much of it a tool can actually enforce — and how much it
  cannot.

The claim worth leaving them with: governance is mostly decision rights and
accountability. Tools enforce it; they do not constitute it. A catalogue nobody
populates and a repository nobody owns are the same failure in different fonts.

## Source

`[Data_Governance_L01]_data_management_and_governance.pdf`, 65 slides. Every
worksheet maps to its sections: why governance matters (03–04), what goes wrong
without it (05–14), core concepts (15–21), data quality and AI readiness
(22–29), frameworks and operating model (30–43), and putting governance into
practice (44–58).
