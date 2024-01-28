####################
#   Build Image    #
####################
FROM docker.io/ubuntu:22.04 AS builder

# Prepare environment
RUN mkdir /work
WORKDIR /work

# Install curl for downloading the latest release
RUN apt update && apt upgrade -y && apt install -y curl

# Detect the latest release version (expect pre-releases)
# AND Download "BeamMP-Server.$CURRENT_OS.$ARCH"
# Where arch is either x86_64 or arm64
# And download to current dir as "BeamMP-Server"
RUN export LATEST_VERSION=$(curl -s https://api.github.com/repos/BeamMP/BeamMP-Server/releases/latest | grep "tag_name" | cut -d '"' -f 4) && \
    export CURRENT_ARCH=$(uname -m | sed s/aarch64/arm64/g) && \
    export CURRENT_OS="ubuntu.22.04" && \
    export DOWNLOAD_URL="https://github.com/BeamMP/BeamMP-Server/releases/download/$LATEST_VERSION/BeamMP-Server.$CURRENT_OS.$CURRENT_ARCH" && \
    echo "Downloading $DOWNLOAD_URL" && \
    curl -L -o BeamMP-Server $DOWNLOAD_URL && \
    chmod +x BeamMP-Server

# Ensure the executable is present
RUN ls -lsh /work/BeamMP-Server

####################
#    Run Image     #
####################
FROM docker.io/ubuntu:22.04
LABEL maintainer="Rouven Himmelstein rouven@himmelstein.info"

# Install game server required packages
RUN apt update &&  \
    apt upgrade -y && \
    apt install -y liblua5.3-0 && \
    apt-get clean && rm -rf /var/lib/apt/lists/

# Create game server folder
RUN mkdir -p /beammp/Resources/Server /beammp/Resources/Client
VOLUME /beammp/Resources/Server
VOLUME /beammp/Resources/Client
WORKDIR /beammp

# Copy the previously downloaded executable
COPY --from=builder /work/BeamMP-Server ./beammp-server

# Prepare user, with uid 1000 and gid 1000
RUN groupadd -g 1000 beammp && \
    useradd -u 1000 -g 1000 -d /beammp -s /bin/bash beammp && \
    chown -R beammp:beammp . &&  \
    chown -R nobody:nogroup /beammp/Resources/ && \
    chmod -R 777 .
USER beammp

# Specify entrypoint
COPY entrypoint.sh .
ENTRYPOINT ["/beammp/entrypoint.sh"]
