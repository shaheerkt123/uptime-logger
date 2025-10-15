SHELL := /bin/bash
NAME  := uptime-logger
VERSION := 2.0

# Paths
BUILD_DIR := build
SRC_DIR   := src

# Tarball
DIST_DIR  := $(BUILD_DIR)/$(NAME)-$(VERSION)
TARBALL   := $(BUILD_DIR)/$(NAME)-$(VERSION).tar.gz

# Toolchain
CC := gcc

# Flags
CFLAGS   := -O2 -Wall -Wextra -g -fPIE
LDFLAGS  := -lsqlite3 -lcurl -pie

# Install paths
PREFIX      := /usr
BIN_DIR     := $(PREFIX)/bin
SYSTEMD_DIR ?= /etc/systemd/system

.PHONY: all build clean install dist rpm help \
        build-deb-image build-rpm-image deb rpm-docker docker-packages

# Default target: show help
all: help

help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "Main Targets:"
	@echo "  build                Build the local binaries."
	@echo "  install              Install the binaries and service files."
	@echo "  clean                Remove build artifacts."
	@echo "  dist                 Create a source tarball."
	@echo "  rpm                  Build the RPM package locally."
	@echo "  help                 Show this help message."
	@echo ""
	@echo "Docker-based Package Builds:"
	@echo "  deb-docker           Build the .deb package using Docker."
	@echo "  rpm-docker           Build the .rpm package using Docker."
	@echo "  docker-packages      Build both .deb and .rpm packages using Docker."

build: $(BUILD_DIR)/uptime_logger $(BUILD_DIR)/uptime_upload

$(BUILD_DIR)/uptime_logger: $(SRC_DIR)/main.c
	@echo "Compiling uptime_logger..."
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $< -o $@ $(LDFLAGS) -lsqlite3

$(BUILD_DIR)/uptime_upload: $(SRC_DIR)/upload.c
	@echo "Compiling uptime_upload..."
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $< -o $@ $(LDFLAGS)

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)

install: build
	@echo "Installing files to $(DESTDIR)..."
	# Create directories
	install -d $(DESTDIR)$(BIN_DIR)
	install -d $(DESTDIR)$(SYSTEMD_DIR)
	install -d $(DESTDIR)/etc/cron.d
	install -d $(DESTDIR)/var/lib/uptime-logger
	# Install binaries
	install -m 755 $(BUILD_DIR)/uptime_logger $(DESTDIR)$(BIN_DIR)/
	install -m 755 $(BUILD_DIR)/uptime_upload $(DESTDIR)$(BIN_DIR)/
	# Install scripts, service files, and cron definitions
	install -m 755 $(SRC_DIR)/uptime_upload_cron.sh $(DESTDIR)$(BIN_DIR)/
	install -m 644 $(SRC_DIR)/services/uptime-logger.service $(DESTDIR)$(SYSTEMD_DIR)/
	install -m 644 $(SRC_DIR)/services/uptime-logger-shutdown.service $(DESTDIR)$(SYSTEMD_DIR)/
	install -m 644 $(SRC_DIR)/cron/uptime-logger $(DESTDIR)/etc/cron.d/

dist:
	@echo "Creating source tarball..."
	@mkdir -p $(DIST_DIR)
	@cp -r src/ packaging/ LICENSE Makefile README.md TODO $(DIST_DIR)/
	@tar -C $(BUILD_DIR) -czf $(TARBALL) $(NAME)-$(VERSION)
	@rm -rf $(DIST_DIR)

rpm: dist
	@echo "Building RPM package..."
	@mkdir -p $(HOME)/rpmbuild/SOURCES
	@cp $(TARBALL) $(HOME)/rpmbuild/SOURCES/
	@rpmbuild -ba packaging/rpm/uptime-logger.spec
	@echo "Moving RPMs to $(BUILD_DIR)/..."
	@find $(HOME)/rpmbuild/RPMS -name "$(NAME)*.rpm" -exec mv {} $(BUILD_DIR) \;
	@find $(HOME)/rpmbuild/SRPMS -name "$(NAME)*.src.rpm" -exec mv {} $(BUILD_DIR) \;

# --- Docker Package Builds ---

DEB_IMG_TAG := uptime-logger-deb
RPM_IMG_TAG := uptime-logger-rpm

# Target to build the Debian Docker image
build-deb-image:
	@echo "Building Debian Docker image..."
	@docker build -t $(DEB_IMG_TAG) -f packaging/debian/Dockerfile .

# Target to build the RPM Docker image
build-rpm-image:
	@echo "Building RPM Docker image..."
	@docker build -t $(RPM_IMG_TAG) -f packaging/rpm/Dockerfile .

# Target to create the .deb package using Docker
deb-docker: build-deb-image
	@echo "Creating .deb package..."
	@mkdir -p $(BUILD_DIR)
	@docker run --rm -v "$(CURDIR)/$(BUILD_DIR):/app/build:z" $(DEB_IMG_TAG)
	@echo "Debian package created in $(BUILD_DIR)/"

# Target to create the .rpm package using Docker
rpm-docker: build-rpm-image
	@echo "Creating .rpm package..."
	@mkdir -p $(BUILD_DIR)
	@docker run --rm -v "$(CURDIR)/$(BUILD_DIR):/app/build:z" $(RPM_IMG_TAG)
	@echo "RPM package created in $(BUILD_DIR)/"

# A target to build both packages via Docker
docker-packages: deb-docker rpm-docker
