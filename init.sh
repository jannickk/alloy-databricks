#!/bin/bash

set -e

# ========= CONFIGURABLE VALUES ==========
CONFIG_DIR="/etc/alloy"
CONFIG_FILE="$CONFIG_DIR/config.alloy"
ALLOY_USER="alloy"
APPLICATION_LOGS_DIRECTORY="/tmp/logs/**/*.log"

# ========= CREATE USER ==========
if ! id "$ALLOY_USER" &>/dev/null; then
  echo "Creating user $ALLOY_USER..."
  sudo useradd --no-create-home --system --shell /bin/false "$ALLOY_USER"
fi


# ========= CREATE DIRECTORIES ==========
sudo mkdir -p "$CONFIG_DIR"
sudo chown -R "$ALLOY_USER":"$ALLOY_USER" "$CONFIG_DIR"

# ========= DOWNLOAD AND INSTALL ==========

apt-get install gpg

mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list


apt-get update

apt-get install alloy

# ========= CREATE CONFIG TO FORWARD APPLICATONS LOGS ===============#
cat <<EOF | tee "$CONFIG_FILE"
logging {
  level  = "info"
  format = "logfmt"
}

loki.write "grafana_cloud_loki" {
  endpoint {
    url = "https://logs-prod-012.grafana.net/loki/api/v1/push"

    basic_auth {
      username = "$GRAFANA_USERNAME"
      password = "$GRAFANA_PASSWORD"
    }
  }
}


local.file_match "logs_integrations_databricks" {

  path_targets = [{
    __address__   = "localhost",
    __path__      = "$APPLICATION_LOGS_DIRECTORY",
    instance      = "$HOSTNAME",
    job           = "integrations/databricks",
  },]

}



loki.source.file "logs_integrations_databricks" {
  targets    = local.file_match.logs_integrations_databricks.targets
  forward_to = [loki.write.grafana_cloud_loki.receiver]
}


EOF

sudo chown "$ALLOY_USER":"$ALLOY_USER" "$CONFIG_FILE"


# ========= START ==========
sudo systemctl start alloy

echo "✅ Grafana Alloy $ALLOY_VERSION installed and running."
