

## Purpose

This shell script can be used as init-script in a all-purpose or job compute cluster in order to install alloy agent and collect logs from the location that is specified as APPLICATION_LOGS_DIRECTORY

Grafana alloy can deal with this directory not being existent. 

This init script requires GRAFANA_USERNAME and GRAFANA_PASSWORD being set as environment variables


## Testing

This script was tested on Databricks Runtime 16.4 LTS