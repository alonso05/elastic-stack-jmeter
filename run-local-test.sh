#!/bin/bash
set -e

# Function to clean up containers and networks
cleanup() {
    echo "Cleaning up..."
    cd elastic-server && docker-compose down --volumes --remove-orphans
    cd ../jmeter-client && docker-compose down --volumes --remove-orphans
    docker network rm elastic_network || true
}

# Clean up on script exit
trap cleanup EXIT

# Create necessary directories
mkdir -p log/jmeter result

# Create shared network
echo "Creating shared network..."
docker network create elastic_network || true

# Start Elastic Stack first
echo "Starting Elastic Stack..."
cd elastic-server
docker-compose up -d

# Wait for Elasticsearch to be ready
echo "Waiting for Elasticsearch to be ready..."
until curl -s http://localhost:9200/_cluster/health | grep -q 'status.*green\|status.*yellow'; do
    echo "Waiting for Elasticsearch..."
    sleep 5
done

echo "Elastic Stack is ready!"
echo "Elasticsearch: http://localhost:9200"
echo "Kibana: http://localhost:5601"

# Update Filebeat configuration to use localhost
cd ..
sed -i.bak 's/ELASTIC_SERVER_IP/localhost/g' filebeat.yml

# Start JMeter and Filebeat
echo "Starting JMeter and Filebeat..."
cd jmeter-client
docker-compose up -d

# Wait a moment for services to start
sleep 5

# Show logs from both Filebeat and JMeter
docker-compose logs -f
