FROM duplicati/duplicati

# Add docker ready to be connected to the host docker engine so we can
# run scripts to extract or inject the minimal backup set from/to each
# container.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y docker.io && \
    apt-get clean all

# Add application-specific scripts
ADD ./scripts/* /scripts/
RUN chmod +x /scripts/*
