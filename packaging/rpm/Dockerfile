# Use the official Fedora image
FROM fedora:latest

# Install RPM build tools and package dependencies
RUN dnf install -y \
    rpm-build \
    make \
    gcc \
    sqlite-devel \
    libcurl-devel \
    systemd-devel

# Copy the entire project source code into the container
WORKDIR /app
COPY . .

# Build the RPM package using the existing Makefile target
CMD ["make", "rpm"]
