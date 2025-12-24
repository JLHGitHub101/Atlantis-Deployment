FROM ubuntu:22.04

# Basic tools
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
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y locales && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Detect architecture and install AWS CLI
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "arm64" ]; then \
        curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"; \
    else \
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"; \
    fi && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws

# AWS Session Manager Plugin
RUN ARCH=$(dpkg --print-architecture) && \
    curl -s "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_${ARCH}/session-manager-plugin.deb" -o "/tmp/session-manager-plugin.deb" && \
    dpkg -i /tmp/session-manager-plugin.deb && \
    rm /tmp/session-manager-plugin.deb

# Terraform
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && apt-get install -y terraform && \
    rm -rf /var/lib/apt/lists/*

# Python packages for Ansible + AWS
RUN pip3 install --no-cache-dir \
    ansible \
    boto3 \
    botocore

# Ansible AWS collections
RUN ansible-galaxy collection install amazon.aws community.aws

WORKDIR /workspace