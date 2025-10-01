# Project info
NAME        := uptime-logger
VERSION     := 1.0
RELEASE     := 1
TARBALL     := $(NAME)-$(VERSION).tar.gz

# Paths
BUILD_DIR   := Build
PKG_DEBIAN  := packaging/debian
PKG_RPM     := packaging/rpm
SOURCE_CODE := uptime_logger
RPMBUILD    := $(HOME)/rpmbuild
SOURCES_DIR := $(RPMBUILD)/SOURCES
SPECS_DIR   := $(RPMBUILD)/SPECS

all: deb rpm

help:
	@echo "Available targets:"
	@echo "  make tarball     - Create source tarball"
	@echo "  make deb         - Build Debian package"
	@echo "  make rpm         - Build RPM package"
	@echo "  make clean       - Clean build artifacts"

tarball-rpm:
	@echo "Creating source tarball for RPM..."
	mkdir -p $(BUILD_DIR)
	rm -rf tmp-tar
	mkdir -p tmp-tar/$(NAME)-$(VERSION)
	# Copy only the RPM package folder
	rsync -a packaging/rpm/uptime-logger-package/ tmp-tar/$(NAME)-$(VERSION)/
	tar -C tmp-tar -czf $(BUILD_DIR)/$(TARBALL) $(NAME)-$(VERSION)
	rm -rf tmp-tar

deb:
	@echo "Building .deb package..."
	mkdir -p $(BUILD_DIR)
	cd $(PKG_DEBIAN) && dpkg-deb --build . ../../$(BUILD_DIR)/$(NAME)_$(VERSION)-$(RELEASE).deb

rpm: tarball-rpm
	@echo "Building .rpm package..."
	# Clean old rpmbuild dirs (optional but safe)
	rm -rf $(RPMBUILD)/BUILD/* $(RPMBUILD)/BUILDROOT/* $(RPMBUILD)/RPMS/* $(RPMBUILD)/SRPMS/*
	mkdir -p $(SOURCES_DIR) $(SPECS_DIR)
	cp $(BUILD_DIR)/$(TARBALL) $(SOURCES_DIR)/
	cp $(PKG_RPM)/$(NAME).spec $(SPECS_DIR)/
	rpmbuild -ba $(SPECS_DIR)/$(NAME).spec
	# Move RPMs into Build/
	find $(RPMBUILD)/RPMS -name "$(NAME)-$(VERSION)-$(RELEASE)*.rpm" -exec mv {} $(BUILD_DIR)/ \;

clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)
