{% test warn_freshness_anomalies_defaults(
    model,
    time_bucket={'period': 'day', 'count': 1},
    detection_period={'period': 'day', 'count': 2},
    training_period={'period': 'month', 'count': 2},
    timestamp_column='_updated_at',
    anomaly_direction= 'spike',
    anomaly_sensitivity = 4
    )
%}

  {{ config(
        severity = 'warn',
        meta = {
            'alert_suppression_interval': 24
        }
     )
  }}

{% endtest %}
