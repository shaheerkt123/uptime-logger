# Use the official Debian stable image
FROM debian:stable-slim

# Install Debian build tools and package dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    devscripts \
    debhelper \
    fakeroot \
    git \
    libsqlite3-dev \
    libcurl4-openssl-dev

# Copy the entire project source code into the container
WORKDIR /app
COPY . .

# Set environment variables for a non-interactive build
ENV DEB_BUILD_OPTS=nocheck
ENV DEBIAN_FRONTEND=noninteractive

# Build the Debian package
# The -us -uc flags prevent signing, which is not needed here.
CMD ["dpkg-buildpackage", "-us", "-uc"]
