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

.PHONY: all build clean install dist rpm

all: build

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
	# Install binaries
	install -m 755 $(BUILD_DIR)/uptime_logger $(DESTDIR)$(BIN_DIR)/
	install -m 755 $(BUILD_DIR)/uptime_upload $(DESTDIR)$(BIN_DIR)/
	# Install scripts, service files, and cron definitions
	install -m 755 $(SRC_DIR)/uptime_upload_cron.sh $(DESTDIR)$(BIN_DIR)/
	install -m 644 $(SRC_DIR)/services/uptime-logger.service $(DESTDIR)$(SYSTEMD_DIR)/
	install -m 644 $(SRC_DIR)/services/uptime-logger-shutdown.service $(DESTDIR)$(SYSTEMD_DIR)/
	install -m 644 $(SRC_DIR)/cron/uptime-logger $(DESTDIR)/etc/cron.d/

dist: clean
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