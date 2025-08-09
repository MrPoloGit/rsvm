# Use Alpine-based devcontainer base image for consistency
FROM mcr.microsoft.com/devcontainers/base:alpine

# Set environment variables
ENV LANG C.UTF-8
ARG INSTALL_ZSH="true"

# Install dependencies (Alpine uses apk instead of apt-get)
RUN apk update && apk add --no-cache \
    python3-dev \
    py3-pip \
    sudo \
    wget \
    npm \
    git \
    bash \
    openssl \
    shadow

# Copy requirements file if it exists
COPY sw_utils/requirements.txt /tmp/requirements.txt 2>/dev/null || echo "# No requirements" > /tmp/requirements.txt

# Install Python dependencies
RUN pip3 install -r /tmp/requirements.txt

# Install the required tools
RUN wget -O - https://raw.githubusercontent.com/sifferman/hdl-tool-installer/main/install | bash -s -- . --oss-cad-suite --zachjs-sv2v

# Install netlistsvg tool
RUN cd /opt && git clone https://github.com/nturley/netlistsvg
RUN cd /opt/netlistsvg && npm install --legacy-peer-deps && npm install . -g

# Create a user for running the container
RUN useradd -m -s /bin/bash sv_user -G wheel
RUN echo "sv_user:ilikehdl" | chpasswd

# Switch to the user
USER sv_user
WORKDIR /home/sv_user

# Add tools to PATH in bashrc
RUN echo 'export PATH="/workspaces/$(basename $PWD)/oss-cad-suite/bin:$PATH"' >> ~/.bashrc
RUN echo 'export PATH="/workspaces/$(basename $PWD)/zachjs-sv2v:$PATH"' >> ~/.bashrc