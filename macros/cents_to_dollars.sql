{% macro cents_to_dollars(column_name) -%}
    cast(({{ column_name }}) / 100.0 as decimal(18, 2))
{%- endmacro %}

