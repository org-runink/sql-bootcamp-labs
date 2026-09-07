-- Custom generate_schema_name — the macro that makes the layer schemas literal.
--
-- dbt's DEFAULT version PREFIXES a custom schema with the target schema, so a
-- model configured schema='edw' would build in "<target.schema>_edw". That
-- default exists so several developers sharing one warehouse do not overwrite
-- each other. This lab wants exactly STG / EDW / MARTS / SEED, so we override it.
--
-- The .sql file name does not need to match the macro name.

{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}

        {{ default_schema }}

    {%- else -%}

        {{ custom_schema_name | trim }}

    {%- endif -%}

{%- endmacro %}
