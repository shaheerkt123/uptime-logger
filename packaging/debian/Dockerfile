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

# Create a build directory for the output
RUN mkdir build

# Build the Debian package and move the artifact to the build directory
# The -us -uc flags prevent signing, which is not needed here.
CMD ["sh", "-c", "dpkg-buildpackage -us -uc && mv ../*.deb build/"]
