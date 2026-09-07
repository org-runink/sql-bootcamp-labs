-- A CUSTOM GENERIC TEST at MODEL level -- our own version of
-- dbt_expectations.expect_table_row_count_to_be_between.
--
-- Note it takes no column_name: a test declared under a model's `tests:` key
-- rather than under a column's is passed only the model. This is the "shape"
-- check -- the one that catches a report silently coming back empty, which no
-- column-level test can see.
--
-- Usage:
--   tests:
--     - row_count_between:
--         min_value: 1

{% test row_count_between(model, min_value=1, max_value=none) %}

with counted as (
    select count(*) as row_count from {{ model }}
)

select *
from counted
where
    row_count < {{ min_value }}
    {% if max_value is not none %} or row_count > {{ max_value }} {% endif %}

{% endtest %}
