#!/bin/bash
set -e

# Function to clean up containers and networks
cleanup() {
    echo "Cleaning up..."
    docker-compose down --volumes --remove-orphans
}

# Clean up on script exit
trap cleanup EXIT

# Start Elastic Stack
echo "Starting Elastic Stack..."
docker-compose up -d

# Wait for Elasticsearch to be ready
echo "Waiting for Elasticsearch to be ready..."
until docker-compose ps elasticsearch | grep "healthy"; do
    sleep 1
done

echo "Elastic Stack is ready!"
echo "Elasticsearch: http://localhost:9200"
echo "Kibana: http://localhost:5601"

# Keep script running
tail -f /dev/null
