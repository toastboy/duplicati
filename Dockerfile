FROM linuxserver/duplicati:v2.0.5.1-2.0.5.1_beta_2020-01-18-ls72

# Add docker ready to be connected to the host docker engine so we can
# run scripts to extract or inject the minimal backup set from/to each
# container.
RUN apt-get update && \
    apt-get install -y docker.io=18.09.7-0ubuntu1~18.04.4 && \
    rm -rf /var/lib/apt/lists/*

# Add application-specific scripts
ADD ./scripts/* /scripts/
RUN chmod +x /scripts/*
