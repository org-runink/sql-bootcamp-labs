-- A CUSTOM GENERIC TEST -- our own version of
-- dbt_expectations.expect_column_values_to_be_between.
--
-- A generic test is just a query that returns the OFFENDING rows: zero rows
-- means pass. Wrap it in a `test` block and it becomes reusable by name from any
-- properties .yml, exactly like the built-in `unique` and `not_null`.
--
-- Written by hand so the project needs no packages -- see macros/surrogate_key.sql
-- for the same reasoning. Writing one is also the best way to understand what
-- every other test in dbt actually is.
--
-- Usage in a properties file:
--   tests:
--     - column_between:
--         arguments:
--           min_value: 0
--           max_value: 1000

{% test column_between(model, column_name, min_value=none, max_value=none) %}

select *
from {{ model }}
where {{ column_name }} is not null
  and (
    false
    {% if min_value is not none %} or {{ column_name }} < {{ min_value }} {% endif %}
    {% if max_value is not none %} or {{ column_name }} > {{ max_value }} {% endif %}
  )

{% endtest %}
