# Useful starting base
FROM ghcr.io/ucsc-cse-x25/dockerimages:base

# Set environment variables
ENV LANG C.UTF-8
ARG INSTALL_ZSH="true"

# Install dependencies
RUN apt-get update && apt-get install -y \
    python3-dev \
    sudo \
    wget \
    npm \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip3 install -r sw_utils/requirements.txt

# Install the required tools
RUN wget -O - https://raw.githubusercontent.com/sifferman/hdl-tool-installer/main/install | bash -s -- . --oss-cad-suite --zachjs-sv2v

# Install netlistsvg tool
RUN cd /opt && git clone https://github.com/nturley/netlistsvg
RUN cd /opt/netlistsvg && npm install --legacy-peer-deps && npm install . -g

# Create a user for running the container
RUN useradd -ms /bin/bash sv_user -G sudo -p "$(openssl passwd -1 ilikehdl)"
USER sv_user

# Ensure paths for tools are available
RUN echo "$GITHUB_WORKSPACE/oss-cad-suite/bin" >> $GITHUB_PATH
RUN echo "$GITHUB_WORKSPACE/zachjs-sv2v" >> $GITHUB_PATH
