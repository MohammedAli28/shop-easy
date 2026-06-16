#!/bin/sh
# Start Prometheus in background
prometheus --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/prometheus \
  --storage.tsdb.retention.time=3d \
  --web.listen-address=:9090 &

# Start Grafana in foreground
exec grafana-server \
  --homepath=/usr/share/grafana \
  --config=/etc/grafana/grafana.ini
