FROM grafana/grafana:10.4.0

USER root

# Install Prometheus
RUN apk add --no-cache curl && \
    curl -LO https://github.com/prometheus/prometheus/releases/download/v2.51.0/prometheus-2.51.0.linux-amd64.tar.gz && \
    tar -xzf prometheus-2.51.0.linux-amd64.tar.gz && \
    mv prometheus-2.51.0.linux-amd64/prometheus /usr/local/bin/ && \
    mv prometheus-2.51.0.linux-amd64/promtool /usr/local/bin/ && \
    rm -rf prometheus-2.51.0.linux-amd64* && \
    mkdir -p /prometheus /etc/prometheus

# Prometheus config
COPY prometheus.yml /etc/prometheus/prometheus.yml

# Grafana provisioning
COPY provisioning/datasources/ /etc/grafana/provisioning/datasources/
COPY provisioning/alerting/ /etc/grafana/provisioning/alerting/
COPY provisioning/dashboards/ /etc/grafana/provisioning/dashboards/

# Startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Grafana env config
ENV GF_SECURITY_ADMIN_USER=admin \
    GF_SECURITY_ADMIN_PASSWORD=ShopEasy2026 \
    GF_AUTH_ANONYMOUS_ENABLED=false \
    GF_SERVER_HTTP_PORT=3000 \
    GF_SERVER_ROOT_URL=%(protocol)s://%(domain)s/grafana/ \
    GF_SERVER_SERVE_FROM_SUB_PATH=true \
    GF_ALERTING_ENABLED=false \
    GF_UNIFIED_ALERTING_ENABLED=true

EXPOSE 3000 9090

ENTRYPOINT ["/start.sh"]
