-- surrogate_key -- our own version of what dbt_utils.generate_surrogate_key does.
--
-- Written by hand on purpose. Code running inside Snowflake has no outbound
-- internet by default, so `dbt deps` cannot reach the dbt Hub and a project that
-- REQUIRES a package will not build. Nine lines of Jinja removes 400+ files of
-- dependency, and the mechanics are worth seeing once.
--
-- What it does: concatenate the fields, coalescing NULLs to a sentinel so that
-- (1, null) and (null, 1) do not collide, then hash. A separator keeps
-- ('ab','c') distinct from ('a','bc').
--
-- Usage: call surrogate_key(['prod_key', 'valid_from']) in Jinja, aliased.

{% macro surrogate_key(field_list) -%}

    md5(
        {%- for field in field_list %}
        coalesce(cast({{ field }} as varchar), '__NULL__')
        {%- if not loop.last %} || '-' || {% endif %}
        {%- endfor %}
    )

{%- endmacro %}
