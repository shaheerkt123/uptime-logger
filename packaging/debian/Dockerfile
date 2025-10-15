# syntax=docker/dockerfile:1
# Use the official minimal Debian base image
FROM debian:stable-slim

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install essential build tools (rarely changes → good for caching)
RUN --mount=type=cache,target=/var/cache/apt,id=apt-cache \
    --mount=type=cache,target=/var/lib/apt,id=apt-lib \
    apt-get update && apt-get install -y \
    build-essential \
    devscripts \
    debhelper \
    fakeroot \
    git

# Copy Debian packaging metadata separately for better caching
WORKDIR /app
COPY packaging/debian/control packaging/debian/control
COPY packaging/debian/rules packaging/debian/rules
COPY packaging/debian/changelog packaging/debian/changelog

# Install build dependencies declared in debian/control
# Only re-runs if control or other packaging files change
# Use a cache mount to persist apt's cache across builds
RUN --mount=type=cache,target=/var/cache/apt,id=apt-cache \
    --mount=type=cache,target=/var/lib/apt,id=apt-lib \
    apt-get update && \
    apt-get build-dep -y ./ && \
    apt-get autoremove -y

# Copy the rest of the project after dependency layers are cached
COPY . .

# Set noninteractive build options
ENV DEB_BUILD_OPTS=nocheck

# Create build output directory
RUN mkdir build

# Default command: build .deb and move it to build/
CMD ["sh", "-c", "dpkg-buildpackage -us -uc && mv ../*.deb build/"]