FROM mcr.microsoft.com/devcontainers/go:1-1.23-bookworm

# Remove problematic Yarn repository that comes with the base image
RUN rm -f /etc/apt/sources.list.d/yarn.list && \
    apt-get update && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*