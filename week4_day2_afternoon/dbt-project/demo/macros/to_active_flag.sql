-- A custom macro. Macros are Jinja functions that RETURN SQL text, which dbt
-- pastes into the model at compile time — the direct analogue of a function in
-- Python. This one wraps the "a null close date means the row is current" rule
-- so it is written once and reused, not copy-pasted into every dimension.
--
-- Usage in a model:   call to_active_flag('valid_to') in curly braces,
--                     aliased as is_current
-- Compiles to:        iff(valid_to is null, true, false) as is_current
--
-- (The usage line is spelled out rather than written with real Jinja
--  delimiters: dbt renders this file as a template before parsing it, so a live
--  tag inside a comment would actually be executed.)

{% macro to_active_flag(valid_to_column) -%}
    iff({{ valid_to_column }} is null, true, false)
{%- endmacro %}
