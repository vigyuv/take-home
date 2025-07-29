{% macro required_table_fields() -%}

	cast(current_timestamp() AS timestamp_ntz) AS _updated_at

{%- endmacro %}
