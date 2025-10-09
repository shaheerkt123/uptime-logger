SHELL := /bin/bash

# Project info
NAME        := uptime-logger
VERSION     := 2.0
RELEASE     := 1
TARBALL     := $(NAME)-$(VERSION).tar.gz

# Paths
BUILD_DIR   := build
SRC_DIR     := src
SERVICES_DIR := $(SRC_DIR)/services

PKG_DEBIAN  := packaging/debian
PKG_RPM     := packaging/rpm
RPMBUILD    := $(HOME)/rpmbuild
SOURCES_DIR := $(RPMBUILD)/SOURCES
SPECS_DIR   := $(RPMBUILD)/SPECS

# Debian package paths
DEBIAN_BIN_DIR := $(PKG_DEBIAN)/usr/local/bin
DEBIAN_SYSTEMD_DIR := $(PKG_DEBIAN)/etc/systemd/system

# RPM package paths
RPM_PKG_DIR := $(PKG_RPM)/uptime-logger-package
RPM_BIN_DIR := $(RPM_PKG_DIR)/usr/local/bin
RPM_SYSTEMD_DIR := $(RPM_PKG_DIR)/etc/systemd/system

all: deb rpm

help:
	@echo "Available targets:"
	@echo "  make build       - Compile C programs"
	@echo "  make sync-files  - Copy source files to packaging directories"
	@echo "  make tarball-rpm - Create source tarball for RPM"
	@echo "  make deb         - Build Debian package"
	@echo "  make rpm         - Build RPM package"
	@echo "  make clean       - Clean build artifacts"

build:
	@echo "Compiling C programs..."
	mkdir -p $(BUILD_DIR)
	gcc $(SRC_DIR)/main.c -o $(BUILD_DIR)/uptime_logger -lsqlite3
	gcc $(SRC_DIR)/upload.c -o $(BUILD_DIR)/uptime_upload -lsqlite3 -lcurl

sync-files: build
	@echo "Syncing files to packaging directories..."
	# Debian
	mkdir -p $(DEBIAN_BIN_DIR) $(DEBIAN_SYSTEMD_DIR)
	cp -u $(BUILD_DIR)/uptime_logger $(DEBIAN_BIN_DIR)/
	cp -u $(BUILD_DIR)/uptime_upload $(DEBIAN_BIN_DIR)/
	cp -u $(SRC_DIR)/uptime_upload_cron.sh $(DEBIAN_BIN_DIR)/
	cp -u $(SERVICES_DIR)/uptime-logger.service $(DEBIAN_SYSTEMD_DIR)/
	cp -u $(SERVICES_DIR)/uptime-logger-shutdown.service $(DEBIAN_SYSTEMD_DIR)/
	# RPM
	mkdir -p $(RPM_BIN_DIR) $(RPM_SYSTEMD_DIR)
	cp -u $(BUILD_DIR)/uptime_logger $(RPM_BIN_DIR)/
	cp -u $(BUILD_DIR)/uptime_upload $(RPM_BIN_DIR)/
	cp -u $(SRC_DIR)/uptime_upload_cron.sh $(RPM_BIN_DIR)/
	cp -u $(SERVICES_DIR)/uptime-logger.service $(RPM_SYSTEMD_DIR)/
	cp -u $(SERVICES_DIR)/uptime-logger-shutdown.service $(RPM_SYSTEMD_DIR)/

tarball-rpm:
	@echo "Creating source tarball for RPM..."
	mkdir -p $(BUILD_DIR)
	rm -rf tmp-tar
	mkdir -p tmp-tar/$(NAME)-$(VERSION)
	# Copy only the RPM package folder
	rsync -a packaging/rpm/uptime-logger-package/ tmp-tar/$(NAME)-$(VERSION)/
	tar -C tmp-tar -czf $(BUILD_DIR)/$(TARBALL) $(NAME)-$(VERSION)
	rm -rf tmp-tar

deb: sync-files
	@echo "Building .deb package..."
	mkdir -p $(BUILD_DIR)
	cd $(PKG_DEBIAN) && dpkg-deb --build . ../../$(BUILD_DIR)/$(NAME)_$(VERSION)-$(RELEASE).deb

rpm: sync-files tarball-rpm
	@echo "Building .rpm package..."
	# Clean old rpmbuild dirs (optional but safe)
	rm -rf $(RPMBUILD)/BUILD/* $(RPMBUILD)/BUILDROOT/* $(RPMBUILD)/RPMS/* $(RPMBUILD)/SRPMS/*
	mkdir -p $(SOURCES_DIR) $(SPECS_DIR)
	mv $(BUILD_DIR)/$(TARBALL) $(SOURCES_DIR)/
	cp $(PKG_RPM)/$(NAME).spec $(SPECS_DIR)/
	rpmbuild -ba $(SPECS_DIR)/$(NAME).spec
	# Move RPMs into Build/
	find $(RPMBUILD)/RPMS -name "$(NAME)-$(VERSION)-$(RELEASE)*.rpm" -exec mv {} $(BUILD_DIR)/ \;

clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR) $(SPECS_DIR) $(SOURCES_DIR)