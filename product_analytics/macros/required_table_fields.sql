{% macro required_table_fields() -%}

	cast(current_timestamp() AS timestamp_ntz) AS record_updated_at

{%- endmacro %}
