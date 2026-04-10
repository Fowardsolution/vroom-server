FROM ghcr.io/project-osrm/osrm-backend:v5.27.1 AS osrm-builder

RUN apt-get update && apt-get install -y wget

# Download Dominican Republic + Haiti map
RUN mkdir -p /data && wget -q https://download.geofabrik.de/central-america/haiti-and-domrep-latest.osm.pbf -O /data/map.osm.pbf

# Process map for OSRM
RUN osrm-extract -p /opt/car.lua /data/map.osm.pbf && \
    osrm-partition /data/map.osrm && \
    osrm-customize /data/map.osrm && \
    rm /data/map.osm.pbf


FROM vroomvrp/vroom-docker:v1.13.0

# Install OSRM and supervisor
USER root
RUN apt-get update && apt-get install -y supervisor wget && rm -rf /var/lib/apt/lists/*

# Copy processed OSRM data
COPY --from=osrm-builder /data /osrm-data
COPY --from=osrm-builder /usr/local/bin/osrm-routed /usr/local/bin/osrm-routed
COPY --from=osrm-builder /usr/local/lib/libosrm.so /usr/local/lib/
COPY --from=osrm-builder /usr/lib/x86_64-linux-gnu/libTBB* /usr/lib/x86_64-linux-gnu/
RUN ldconfig

# Copy config
COPY config.yml /conf/config.yml
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 3000

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
