-- A macro that GENERATES SQL with a Jinja loop — the pattern that makes dbt more
-- than string templating. Given a column and a list of categories it writes one
-- conditional SUM per category, so a five-category pivot is a few lines of Jinja
-- instead of five hand-maintained columns that drift.
--
-- The Jinja on show: a for/endfor loop, with loop.last so a comma goes between
-- items but not after the last; expression interpolation for the category and
-- the column name; the replace('-', '_') filter, because 'category-1' is not a
-- legal column name; and the dashes on the tags, which trim whitespace so the
-- compiled SQL stays readable.
--
-- NOTE: this comment spells those tags out in words on purpose. dbt renders
-- every file as a Jinja template BEFORE parsing it and does not skip SQL
-- comments — a literal loop tag written here would open a control-flow block and
-- fail with "block definition inside control flow".
--
-- Run `dbt compile --select rpt_category_pivot` to see what it expands to.

{% macro pivot_category_amounts(amount_column, categories) -%}
    {%- for c in categories %}
    sum(case when category_name = '{{ c }}' then {{ amount_column }} else 0 end)
        as {{ c | replace('-', '_') }}
    {%- if not loop.last %},{% endif %}
    {%- endfor %}
{%- endmacro %}
