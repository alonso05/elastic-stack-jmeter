#!/bin/bash
set -e

# Check if Elasticsearch IP is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <elasticsearch-ip>"
    exit 1
fi

ELASTIC_IP=$1

# Function to clean up containers and networks
cleanup() {
    echo "Cleaning up..."
    docker-compose down --volumes --remove-orphans
}

# Clean up on script exit
trap cleanup EXIT

# Create necessary directories
mkdir -p ../log/jmeter ../result

# Update Filebeat configuration with Elasticsearch IP
sed -i.bak "s/ELASTIC_SERVER_IP/$ELASTIC_IP/g" ../filebeat.yml

# Start JMeter and Filebeat
echo "Starting JMeter and Filebeat..."
docker-compose up -d

# Follow JMeter logs
docker-compose logs -f jmeter
