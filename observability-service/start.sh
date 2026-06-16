#!/bin/sh
PRODUCT_TARGET=${PRODUCT_TARGET:-product-service:4001}
ORDER_TARGET=${ORDER_TARGET:-order-service:4002}
PAGERDUTY_KEY=${PAGERDUTY_INTEGRATION_KEY:-dummy-key-for-local}

sed -i "s|PRODUCT_TARGET|${PRODUCT_TARGET}|g" /etc/prometheus/prometheus.yml
sed -i "s|ORDER_TARGET|${ORDER_TARGET}|g" /etc/prometheus/prometheus.yml
sed -i "s|\${PAGERDUTY_INTEGRATION_KEY}|${PAGERDUTY_KEY}|g" /etc/grafana/provisioning/alerting/contactpoints.yml

# Start Prometheus in background
prometheus --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/prometheus \
  --storage.tsdb.retention.time=3d \
  --web.listen-address=:9090 &

# Start Grafana in foreground
exec grafana-server \
  --homepath=/usr/share/grafana \
  --config=/etc/grafana/grafana.ini
