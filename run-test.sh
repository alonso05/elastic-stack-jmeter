#!/bin/bash
set -e

# Function to clean up containers and networks
cleanup() {
    echo "Cleaning up..."
    docker-compose down --volumes --remove-orphans
    # Force remove any lingering containers
    docker-compose ps -q | xargs -r docker rm -f
    # Force remove the network
    docker network ls | grep jmeter_elastic | awk '{print $1}' | xargs -r docker network rm
}

# Function to check if Elasticsearch is ready
check_elasticsearch() {
    docker-compose exec elasticsearch curl -s http://localhost:9200/_cluster/health | grep -q 'status.*green\|status.*yellow'
}

# Function to setup directories
setup_directories() {
    echo "Setting up directories..."
    # Create directories with proper permissions
    mkdir -p test result/dashboard log/jmeter
    chmod -R 777 result result/dashboard
    chmod -R 777 log log/jmeter
    # Create empty files to ensure proper permissions
    touch log/jmeter/jmeter.log
    chmod 666 log/jmeter/jmeter.log
}

# Function to clean up previous results
cleanup_results() {
    echo "Cleaning up previous results..."
    rm -rf result/* log/jmeter/*
}

# Clean up on script exit
trap cleanup EXIT

# Clean up any previous containers
echo "Cleaning up previous containers..."
cleanup

# Setup directories
setup_directories

# Clean up previous results
cleanup_results

# Verify JMeter test file exists
if [ ! -f "test/todoist.jmx" ]; then
    echo "Error: test/todoist.jmx file not found!"
    ls -la test/
    exit 1
fi

# Start Elastic Stack
echo "Starting Elastic Stack..."
docker-compose up -d elasticsearch kibana filebeat

# Wait for Elasticsearch to be ready
echo "Waiting for Elasticsearch to be ready..."
until docker-compose ps elasticsearch | grep "healthy"; do
    sleep 1
done

# Run JMeter test
echo "Running JMeter test in Docker..."
docker-compose run --rm jmeter 2>&1 | tee jmeter_run.log

# Check if test completed successfully
if [ $? -eq 0 ]; then
    echo "Test completed successfully!"
    echo "Results are available in:"
    echo "- JTL file: result/result.jtl"
    echo "- Dashboard: result/dashboard/index.html"
    echo "- Logs: log/jmeter/jmeter.log"
    echo "- Kibana: http://localhost:5601"
    echo
    echo "Test Summary:"
    if [ -f "result/result.jtl" ]; then
        echo "Results file created successfully"
        ls -l result/result.jtl
        echo "Test results were generated"
        head -n 5 result/result.jtl
    else
        echo "No results file was created"
    fi
    echo "Checking logs for errors..."
    if [ -f "log/jmeter/jmeter.log" ]; then
        grep -i "error\|exception" log/jmeter/jmeter.log || echo "No errors found in logs"
    else
        echo "Warning: No JMeter log file found!"
    fi
else
    echo "Test failed!"
    echo "Checking logs for errors..."
    if [ -f "log/jmeter/jmeter.log" ]; then
        grep -i "error\|exception" log/jmeter/jmeter.log
    else
        echo "Warning: No JMeter log file found!"
    fi
    exit 1
fi
