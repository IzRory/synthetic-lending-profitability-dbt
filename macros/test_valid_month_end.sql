{% test valid_month_end(model, column_name) %}

select *
from {{ model }}
where {{ column_name }} != last_day({{ column_name }})

{% endtest %}

