@echo off
SETLOCAL EnableDelayedExpansion

REM Function to clean up containers and networks
:cleanup
echo Cleaning up...
docker-compose down --volumes --remove-orphans
exit /b

REM Clean up on script exit
REM Note: Windows doesn't support trap, so we'll handle cleanup manually

REM Start Elastic Stack
echo Starting Elastic Stack...
docker-compose up -d

REM Wait for Elasticsearch to be ready
echo Waiting for Elasticsearch to be ready...
:wait_es
docker-compose ps elasticsearch | findstr "healthy" >nul
if errorlevel 1 (
    timeout /t 1 /nobreak >nul
    goto :wait_es
)

echo Elastic Stack is ready!
echo Elasticsearch: http://localhost:9200
echo Kibana: http://localhost:5601

REM Keep the window open
pause
