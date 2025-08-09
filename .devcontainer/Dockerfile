# Use Ubuntu as base image instead of Microsoft's container
FROM ubuntu:22.04

# Set environment variables
ENV LANG=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    sudo \
    wget \
    curl \
    npm \
    git \
    build-essential \
    ca-certificates \
    gnupg \
    lsb-release \
    zsh \
    && rm -rf /var/lib/apt/lists/*

# Create a user for running the container
RUN useradd -ms /bin/bash sv_user && \
    echo "sv_user:ilikehdl" | chpasswd && \
    usermod -aG sudo sv_user && \
    echo "sv_user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to sv_user for installations
USER sv_user
WORKDIR /home/sv_user

# Install Python dependencies (you'll need to copy requirements.txt or install specific packages)
# RUN pip3 install -r sw_utils/requirements.txt

# Install the HDL tools
RUN wget -O - https://raw.githubusercontent.com/sifferman/hdl-tool-installer/main/install | bash -s -- . --oss-cad-suite --zachjs-sv2v

# Install netlistsvg tool
RUN cd /tmp && git clone https://github.com/nturley/netlistsvg && \
    cd netlistsvg && npm install --legacy-peer-deps && \
    sudo npm install . -g

# Add tools to PATH
ENV PATH="/home/sv_user/oss-cad-suite/bin:/home/sv_user/zachjs-sv2v:${PATH}"

# Set up shell
RUN sudo chsh -s /bin/zsh sv_user