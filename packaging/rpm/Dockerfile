# syntax=docker/dockerfile:1
# Use the official Fedora image
FROM fedora:latest

# Install essential RPM build tools (rarely changes -> good for caching)
RUN --mount=type=cache,target=/var/cache/dnf,id=dnf-cache \
    dnf install -y \
    rpm-build \
    make \
    gcc \
    git

# Copy RPM spec file separately for better caching
WORKDIR /app
COPY packaging/rpm/uptime-logger.spec ./packaging/rpm/

# Install build dependencies declared in the spec file
# Only re-runs if the spec file changes
# Use a cache mount to persist dnf's cache across builds
RUN --mount=type=cache,target=/var/cache/dnf,id=dnf-cache \
    dnf builddep -y packaging/rpm/uptime-logger.spec

# Copy the rest of the project after dependency layers are cached
COPY . .

# Build the RPM package using the existing Makefile target
CMD ["make", "rpm"]
