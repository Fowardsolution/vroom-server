#!/bin/bash

# Start OSRM in background
osrm-routed --algorithm mld --port 5000 /osrm-data/map.osrm &

# Wait for OSRM to be ready
echo "Waiting for OSRM to start..."
for i in $(seq 1 30); do
    if curl -s http://127.0.0.1:5000/health > /dev/null 2>&1; then
        echo "OSRM is ready!"
        break
    fi
    sleep 1
done

# Start VROOM Express
cd /vroom-express
exec npm start
