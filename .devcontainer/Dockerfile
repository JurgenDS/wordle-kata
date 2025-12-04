# Wordle Kata Development Container
# Base image with Java 21, Node.js 20, and development tools

FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set locale
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Install Java 21 (Eclipse Temurin)
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    gnupg \
    ca-certificates \
    && wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor -o /usr/share/keyrings/adoptium.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends temurin-21-jdk \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME - find the actual temurin directory
RUN JAVA_DIR=$(ls -d /usr/lib/jvm/temurin-21-jdk-* 2>/dev/null | head -1) && \
    ln -sf "$JAVA_DIR" /usr/lib/jvm/temurin-21-jdk && \
    echo "export JAVA_HOME=/usr/lib/jvm/temurin-21-jdk" >> /etc/profile.d/java.sh && \
    chmod +x /etc/profile.d/java.sh

ENV JAVA_HOME=/usr/lib/jvm/temurin-21-jdk
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Install Maven
ARG MAVEN_VERSION=3.9.11
RUN wget -q https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz -O /tmp/maven.tar.gz \
    && tar -xzf /tmp/maven.tar.gz -C /opt \
    && ln -s /opt/apache-maven-${MAVEN_VERSION} /opt/maven \
    && rm /tmp/maven.tar.gz

ENV MAVEN_HOME=/opt/maven
ENV PATH="${MAVEN_HOME}/bin:${PATH}"

# Install Node.js 20 LTS
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install pnpm
RUN npm install -g pnpm@latest

# Install Angular CLI globally
RUN npm install -g @angular/cli@latest

# Install Playwright system dependencies
RUN npx playwright install-deps chromium firefox webkit

# Install security and quality tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install gitleaks
ARG GITLEAKS_VERSION=8.21.2
RUN wget -q https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz -O /tmp/gitleaks.tar.gz \
    && tar -xzf /tmp/gitleaks.tar.gz -C /usr/local/bin gitleaks \
    && chmod +x /usr/local/bin/gitleaks \
    && rm /tmp/gitleaks.tar.gz

# Install semgrep via pip
RUN pip3 install --no-cache-dir semgrep

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install additional development utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    jq \
    httpie \
    tree \
    ncdu \
    htop \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create workspace directory
RUN mkdir -p /workspace && chown vscode:vscode /workspace

# Create directories for caches with proper permissions
RUN mkdir -p /home/vscode/.m2 \
    && mkdir -p /home/vscode/.local/share/pnpm \
    && mkdir -p /home/vscode/.cache/ms-playwright \
    && chown -R vscode:vscode /home/vscode

# Set working directory
WORKDIR /workspace

# Switch to non-root user
USER vscode

# Configure Maven settings for faster downloads
RUN mkdir -p /home/vscode/.m2 \
    && echo '<?xml version="1.0" encoding="UTF-8"?>\n\
<settings xmlns="http://maven.apache.org/SETTINGS/1.2.0"\n\
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"\n\
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.2.0 http://maven.apache.org/xsd/settings-1.2.0.xsd">\n\
  <mirrors>\n\
    <mirror>\n\
      <id>maven-central</id>\n\
      <name>Maven Central</name>\n\
      <url>https://repo.maven.apache.org/maven2</url>\n\
      <mirrorOf>central</mirrorOf>\n\
    </mirror>\n\
  </mirrors>\n\
</settings>' > /home/vscode/.m2/settings.xml

# Configure pnpm
RUN pnpm config set store-dir /home/vscode/.local/share/pnpm/store

# Set default shell to zsh (will be configured by devcontainer features)
ENV SHELL=/bin/zsh

# Verify installations
RUN java -version && \
    mvn -version && \
    node -v && \
    pnpm -v && \
    ng version && \
    gh --version && \
    gitleaks version && \
    semgrep --version
