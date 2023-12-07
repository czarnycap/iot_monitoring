 
#!/bin/bash

# InfluxDB parameters
INFLUXDB_URL="http://192.168.1.239:8086"
DATABASE="EdgeX1"

# Create the database (optional, uncomment if needed)
curl -i -XPOST "${INFLUXDB_URL}/query" --data-urlencode "q=CREATE DATABASE ${DATABASE}"

# Get current bandwidth and hourly RX/TX rate using vnstat --oneline
VNSTAT_ONELINE=$(vnstat --oneline)

# Extract relevant data from vnstat oneline output
CURRENT_RX=$(echo "${VNSTAT_ONELINE}" | awk -F';' '{print $10}' | sed 's/MiB//' | tr -d ' ')
CURRENT_TX=$(echo "${VNSTAT_ONELINE}" | awk -F';' '{print $12}' | sed 's/kbit\/s//' | tr -d ' ')
HOURLY_RX=$(echo "${VNSTAT_ONELINE}" | awk -F';' '{print $5}' | sed 's/MiB//' | tr -d ' ')
HOURLY_TX=$(echo "${VNSTAT_ONELINE}" | awk -F';' '{print $14}' | sed 's/MiB\/s//' | tr -d ' ')

# Data to be sent
MEASUREMENT="network_stats"
TAGS="interface=eth0"
FIELDS="current_rx=${CURRENT_RX},current_tx=${CURRENT_TX}"

# Build the line protocol
LINE_PROTOCOL="${MEASUREMENT},${TAGS} ${FIELDS} $(date +%s%N)"

# Send data to InfluxDB using curl
curl -i -XPOST "${INFLUXDB_URL}/write?db=${DATABASE}" --data-binary "${LINE_PROTOCOL}"

# Check for success (optional)
if [ $? -eq 0 ]; then
  echo "Data sent successfully to InfluxDB."
else
  echo "Failed to send data to InfluxDB."
fi
