#!/bin/sh
# Substitute Prometheus targets based on environment
# In docker-compose: PRODUCT_TARGET=product-service:4001, ORDER_TARGET=order-service:4002
# In ECS: set via env vars to use ALB internal or service connect
PRODUCT_TARGET=${PRODUCT_TARGET:-product-service:4001}
ORDER_TARGET=${ORDER_TARGET:-order-service:4002}

sed -i "s|PRODUCT_TARGET|${PRODUCT_TARGET}|g" /etc/prometheus/prometheus.yml
sed -i "s|ORDER_TARGET|${ORDER_TARGET}|g" /etc/prometheus/prometheus.yml

# Start Prometheus in background
prometheus --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/prometheus \
  --storage.tsdb.retention.time=3d \
  --web.listen-address=:9090 &

# Start Grafana in foreground
exec grafana-server \
  --homepath=/usr/share/grafana \
  --config=/etc/grafana/grafana.ini
