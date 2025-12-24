FROM ubuntu:22.04

# Base tools and locales
RUN apt-get update && apt-get install -y \
        curl \
        wget \
        unzip \
        git \
        python3 \
        python3-pip \
        python3-venv \
        ssh \
        jq \
        gnupg \
        software-properties-common \
        lsb-release \
        locales \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 \
        LANGUAGE=en_US:en \
        LC_ALL=en_US.UTF-8

# Detect architecture and install AWS CLI
RUN set -e; ARCH=$(dpkg --print-architecture); \
    if [ "$ARCH" = "arm64" ]; then \
        CLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip"; \
    else \
        CLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"; \
    fi; \
    curl -fsSL "$CLI_URL" -o awscliv2.zip && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws

# AWS Session Manager Plugin
RUN ARCH=$(dpkg --print-architecture) && \
    curl -fsSL "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_${ARCH}/session-manager-plugin.deb" -o "/tmp/session-manager-plugin.deb" && \
    dpkg -i /tmp/session-manager-plugin.deb && \
    rm /tmp/session-manager-plugin.deb

# Terraform
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && apt-get install -y terraform && \
    rm -rf /var/lib/apt/lists/*

# Python packages for Ansible + AWS and collections
RUN pip3 install --no-cache-dir ansible boto3 botocore && \
    ansible-galaxy collection install amazon.aws community.aws

# Allow Git usage within the workspace
RUN git config --global --add safe.directory /workspace

WORKDIR /workspace